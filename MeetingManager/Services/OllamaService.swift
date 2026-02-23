import Foundation
import Observation

@Observable
@MainActor
final class OllamaService {
    private let baseURL: URL

    private(set) var isAvailable = false
    private(set) var availableModels: [OllamaModel] = []
    var selectedModel: String = ""
    private(set) var isGenerating = false
    private(set) var errorMessage: String?

    init(baseURL: URL = AppConstants.Ollama.defaultBaseURL) {
        self.baseURL = baseURL
    }

    func checkAvailability() async {
        do {
            let url = baseURL.appendingPathComponent(AppConstants.Ollama.tagsEndpoint)
            var request = URLRequest(url: url)
            request.timeoutInterval = 5
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200
            else {
                isAvailable = false
                return
            }

            let modelList = try JSONDecoder().decode(OllamaModelList.self, from: data)
            availableModels = modelList.models
            isAvailable = true
            errorMessage = nil

            if selectedModel.isEmpty, let first = modelList.models.first {
                selectedModel = first.name
            }
        } catch {
            isAvailable = false
            availableModels = []
            errorMessage = "Cannot connect to Ollama at \(baseURL.absoluteString)"
        }
    }

    func generateMeetingNotes(
        transcript: String,
        format: NoteFormat = .structured,
        onChunk: @escaping @MainActor (String) -> Void
    ) async throws -> MeetingNotes {
        guard !selectedModel.isEmpty else {
            throw OllamaError.modelNotSelected
        }

        isGenerating = true
        errorMessage = nil
        defer { isGenerating = false }

        let request = OllamaChatRequest(
            model: selectedModel,
            messages: [
                OllamaChatMessage(role: "system", content: format.systemPrompt),
                OllamaChatMessage(role: "user", content: "Here is the meeting transcript:\n\n\(transcript)")
            ],
            stream: true
        )

        let url = baseURL.appendingPathComponent(AppConstants.Ollama.chatEndpoint)
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = AppConstants.Ollama.defaultTimeout
        urlRequest.httpBody = try JSONEncoder().encode(request)

        var fullResponse = ""
        let (bytes, response) = try await URLSession.shared.bytes(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200
        else {
            throw OllamaError.requestFailed
        }

        for try await line in bytes.lines {
            guard let data = line.data(using: .utf8) else { continue }
            guard let chunk = try? JSONDecoder().decode(OllamaChatResponseChunk.self, from: data) else { continue }

            if let content = chunk.message?.content {
                fullResponse += content
                await onChunk(content)
            }

            if chunk.done { break }
        }

        return parseMeetingNotes(from: fullResponse, format: format)
    }

    private func parseMeetingNotes(from markdown: String, format: NoteFormat) -> MeetingNotes {
        MeetingNotes(
            summary: extractSection(from: markdown, header: "Summary"),
            keyPoints: extractBulletPoints(from: markdown, header: "Key Points"),
            actionItems: extractBulletPoints(from: markdown, header: "Action Items"),
            rawMarkdown: markdown,
            modelUsed: selectedModel,
            generatedAt: Date(),
            format: format
        )
    }

    private func extractSection(from markdown: String, header: String) -> String {
        let pattern = "## \(header)\n"
        guard let range = markdown.range(of: pattern) else { return "" }
        let rest = String(markdown[range.upperBound...])
        if let nextHeader = rest.range(of: "\n## ") {
            return String(rest[..<nextHeader.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return rest.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func extractBulletPoints(from markdown: String, header: String) -> [String] {
        let section = extractSection(from: markdown, header: header)
        return section
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.hasPrefix("- ") || $0.hasPrefix("* ") }
            .map { String($0.dropFirst(2)).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    enum OllamaError: Error, LocalizedError {
        case requestFailed
        case modelNotSelected

        var errorDescription: String? {
            switch self {
            case .requestFailed: return "Ollama request failed. Make sure Ollama is running."
            case .modelNotSelected: return "No Ollama model selected."
            }
        }
    }
}
