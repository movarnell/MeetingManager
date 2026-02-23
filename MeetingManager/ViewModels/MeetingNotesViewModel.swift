import Foundation
import Observation

@Observable
@MainActor
final class MeetingNotesViewModel {
    let ollamaService = OllamaService()

    var meetingNotes: MeetingNotes?
    var streamingText: String = ""
    var errorMessage: String?
    var selectedFormat: NoteFormat = .structured

    var isGenerating: Bool { ollamaService.isGenerating }
    var isOllamaAvailable: Bool { ollamaService.isAvailable }
    var availableModels: [OllamaModel] { ollamaService.availableModels }

    var selectedModel: String {
        get { ollamaService.selectedModel }
        set { ollamaService.selectedModel = newValue }
    }

    func checkOllamaStatus() async {
        await ollamaService.checkAvailability()
    }

    func generateNotes(from transcript: Transcript) async {
        streamingText = ""
        errorMessage = nil

        do {
            meetingNotes = try await ollamaService.generateMeetingNotes(
                transcript: transcript.fullText,
                format: selectedFormat
            ) { [weak self] chunk in
                self?.streamingText += chunk
            }
        } catch {
            errorMessage = "Note generation failed: \(error.localizedDescription)"
        }
    }

    func regenerateNotes(from transcript: Transcript) async {
        meetingNotes = nil
        streamingText = ""
        await generateNotes(from: transcript)
    }

    func copyNotes() -> String? {
        meetingNotes?.rawMarkdown
    }

    func exportNotes(to url: URL, format: StorageService.ExportFormat) {
        guard let notes = meetingNotes else { return }
        do {
            try StorageService.shared.exportNotes(notes, to: url, format: format)
        } catch {
            errorMessage = "Export failed: \(error.localizedDescription)"
        }
    }
}
