import Foundation

// MARK: - GET /api/tags response

struct OllamaModelList: Codable {
    let models: [OllamaModel]
}

struct OllamaModel: Codable, Identifiable {
    let name: String
    let modifiedAt: String
    let size: Int

    var id: String { name }

    var displayName: String {
        name.components(separatedBy: ":").first ?? name
    }

    var sizeDescription: String {
        let gb = Double(size) / 1_073_741_824
        if gb >= 1.0 {
            return String(format: "%.1f GB", gb)
        }
        let mb = Double(size) / 1_048_576
        return String(format: "%.0f MB", mb)
    }

    enum CodingKeys: String, CodingKey {
        case name
        case modifiedAt = "modified_at"
        case size
    }
}

// MARK: - POST /api/chat request

struct OllamaChatRequest: Codable {
    let model: String
    let messages: [OllamaChatMessage]
    let stream: Bool
}

struct OllamaChatMessage: Codable {
    let role: String
    let content: String
}

// MARK: - Streaming response chunk

struct OllamaChatResponseChunk: Codable {
    let model: String?
    let message: OllamaChatResponseMessage?
    let done: Bool
}

struct OllamaChatResponseMessage: Codable {
    let role: String
    let content: String
}
