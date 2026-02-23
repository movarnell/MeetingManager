import Foundation
import Observation
import WhisperKit

enum ModelDownloadState: Equatable {
    case idle
    case determining
    case downloading(fractionCompleted: Double, description: String)
    case downloaded
    case loading
    case ready
    case failed(String)
}

@Observable
@MainActor
final class TranscriptionService {
    static let shared = TranscriptionService()

    private var whisper: WhisperKit?
    private(set) var isModelLoaded = false
    private(set) var isTranscribing = false
    private(set) var progress: Double = 0
    private(set) var loadingStatus: String = "Not loaded"
    private(set) var currentModelName: String?
    private(set) var errorMessage: String?
    private(set) var downloadState: ModelDownloadState = .idle
    private(set) var downloadProgress: Double = 0

    func loadModel(name: String? = nil) async throws {
        errorMessage = nil
        downloadState = .determining
        loadingStatus = "Checking for recommended model..."

        do {
            // Step 1: Determine which model variant to use
            let modelVariant: String
            if let name = name {
                modelVariant = name
            } else {
                let modelSupport = await WhisperKit.recommendedRemoteModels()
                modelVariant = modelSupport.default
            }

            currentModelName = modelVariant
            loadingStatus = "Preparing \(modelVariant)..."

            // Step 2: Download the model with progress tracking
            downloadState = .downloading(fractionCompleted: 0, description: "Downloading \(modelVariant)...")
            loadingStatus = "Downloading \(modelVariant)..."

            let modelFolder = try await WhisperKit.download(
                variant: modelVariant,
                progressCallback: { [weak self] progress in
                    Task { @MainActor in
                        guard let self = self else { return }
                        let fraction = progress.fractionCompleted
                        self.downloadProgress = fraction
                        let percent = Int(fraction * 100)

                        var description = "Downloading \(modelVariant)... \(percent)%"
                        if let throughput = progress.userInfo[.throughputKey] as? Double, throughput > 0 {
                            let mbps = throughput / (1024 * 1024)
                            description += String(format: " (%.1f MB/s)", mbps)
                        }

                        self.downloadState = .downloading(fractionCompleted: fraction, description: description)
                        self.loadingStatus = description
                    }
                }
            )

            // Step 3: Load the model from the downloaded folder
            downloadState = .downloaded
            loadingStatus = "Loading \(modelVariant) into memory..."
            downloadState = .loading

            let config = WhisperKitConfig(
                model: modelVariant,
                modelFolder: modelFolder.path,
                download: false  // Already downloaded
            )
            whisper = try await WhisperKit(config)

            isModelLoaded = true
            downloadState = .ready
            loadingStatus = "Ready"
        } catch {
            let message = error.localizedDescription
            downloadState = .failed(message)
            loadingStatus = "Failed to load model"
            errorMessage = message
            throw error
        }
    }

    func transcribe(audioFileURL: URL) async throws -> Transcript {
        guard let whisper = whisper else {
            throw TranscriptionError.modelNotLoaded
        }

        isTranscribing = true
        errorMessage = nil
        defer { isTranscribing = false }

        let results = try await whisper.transcribe(audioPath: audioFileURL.path)

        guard !results.isEmpty else {
            throw TranscriptionError.noResult
        }

        var allSegments: [TranscriptSegment] = []
        var fullText = ""

        for result in results {
            for segment in result.segments {
                let convertedWords: [MeetingManager.WordTiming]? = segment.words?.map { wkWord in
                    MeetingManager.WordTiming(
                        word: wkWord.word,
                        start: wkWord.start,
                        end: wkWord.end,
                        probability: wkWord.probability
                    )
                }

                allSegments.append(TranscriptSegment(
                    startTime: segment.start,
                    endTime: segment.end,
                    text: segment.text.trimmingCharacters(in: CharacterSet.whitespaces),
                    words: convertedWords
                ))
            }
            fullText += result.text
        }

        return Transcript(
            segments: allSegments,
            fullText: fullText.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines),
            language: results.first?.language,
            createdAt: Date()
        )
    }

    enum TranscriptionError: Error, LocalizedError {
        case modelNotLoaded
        case noResult

        var errorDescription: String? {
            switch self {
            case .modelNotLoaded: return "Whisper model not loaded. Please load a model first."
            case .noResult: return "Transcription produced no results."
            }
        }
    }
}
