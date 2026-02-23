import Foundation

struct Transcript: Codable {
    var segments: [TranscriptSegment]
    var fullText: String
    var language: String?
    var createdAt: Date

    init(segments: [TranscriptSegment], fullText: String, language: String? = nil, createdAt: Date = Date()) {
        self.segments = segments
        self.fullText = fullText
        self.language = language
        self.createdAt = createdAt
    }
}

struct TranscriptSegment: Identifiable, Codable {
    let id: UUID
    var startTime: Float
    var endTime: Float
    var text: String
    var words: [WordTiming]?

    init(id: UUID = UUID(), startTime: Float, endTime: Float, text: String, words: [WordTiming]? = nil) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.text = text
        self.words = words
    }
}

struct WordTiming: Codable {
    var word: String
    var start: Float
    var end: Float
    var probability: Float
}
