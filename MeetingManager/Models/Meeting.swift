import Foundation

struct Meeting: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var tags: [String]
    var createdAt: Date
    var duration: TimeInterval
    var audioFileURL: URL?
    var systemAudioFileURL: URL?
    var micAudioFileURL: URL?
    var transcript: Transcript?
    var meetingNotes: MeetingNotes?
    var isRecording: Bool
    var bookmarks: [MeetingBookmark]

    init(title: String = "Untitled Meeting") {
        self.id = UUID()
        self.title = title
        self.tags = []
        self.createdAt = Date()
        self.duration = 0
        self.isRecording = false
        self.bookmarks = []
    }

    static func == (lhs: Meeting, rhs: Meeting) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct MeetingBookmark: Identifiable, Codable {
    let id: UUID
    let timestamp: TimeInterval
    var label: String

    init(timestamp: TimeInterval, label: String = "Bookmark") {
        self.id = UUID()
        self.timestamp = timestamp
        self.label = label
    }
}
