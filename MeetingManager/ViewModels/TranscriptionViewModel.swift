import Foundation
import Observation

@Observable
@MainActor
final class TranscriptionViewModel {
    let transcriptionService = TranscriptionService.shared

    var transcript: Transcript?
    var searchText: String = ""
    var errorMessage: String?

    var isTranscribing: Bool { transcriptionService.isTranscribing }
    var isModelLoaded: Bool { transcriptionService.isModelLoaded }
    var loadingStatus: String { transcriptionService.loadingStatus }
    var downloadState: ModelDownloadState { transcriptionService.downloadState }
    var downloadProgress: Double { transcriptionService.downloadProgress }
    var currentModelName: String? { transcriptionService.currentModelName }

    /// Whether the model is currently being prepared (downloading or loading)
    var isPreparingModel: Bool {
        switch downloadState {
        case .determining, .downloading, .downloaded, .loading:
            return true
        default:
            return false
        }
    }

    var filteredSegments: [TranscriptSegment] {
        guard let segments = transcript?.segments else { return [] }
        if searchText.isEmpty { return segments }
        return segments.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
    }

    func loadModelIfNeeded() async {
        guard !isModelLoaded else { return }
        do {
            try await transcriptionService.loadModel()
        } catch {
            errorMessage = "Failed to load Whisper model: \(error.localizedDescription)"
        }
    }

    func transcribe(meeting: Meeting) async -> Transcript? {
        errorMessage = nil

        // Determine which audio file to transcribe
        let audioURL: URL?
        if let mixed = meeting.audioFileURL {
            audioURL = mixed
        } else if let mic = meeting.micAudioFileURL {
            audioURL = mic
        } else {
            audioURL = meeting.systemAudioFileURL
        }

        guard let url = audioURL else {
            errorMessage = "No audio file found for this meeting."
            return nil
        }

        guard FileManager.default.fileExists(atPath: url.path) else {
            errorMessage = "Audio file not found at expected location."
            return nil
        }

        await loadModelIfNeeded()

        guard isModelLoaded else {
            errorMessage = "Whisper model is not loaded."
            return nil
        }

        do {
            let result = try await transcriptionService.transcribe(audioFileURL: url)
            transcript = result
            return result
        } catch {
            errorMessage = "Transcription failed: \(error.localizedDescription)"
            return nil
        }
    }

    func copyTranscript() -> String? {
        transcript?.fullText
    }
}
