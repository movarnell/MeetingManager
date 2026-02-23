import Foundation

final class StorageService: @unchecked Sendable {
    static let shared = StorageService()

    private let baseDirectory: URL
    private let fileManager = FileManager.default
    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }()
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.baseDirectory = docs.appendingPathComponent("MeetingManager", isDirectory: true)
        try? ensureDirectoryExists(at: baseDirectory)
    }

    func meetingDirectory(for meetingId: UUID) -> URL {
        baseDirectory.appendingPathComponent(meetingId.uuidString, isDirectory: true)
    }

    func ensureDirectoryExists(at url: URL) throws {
        if !fileManager.fileExists(atPath: url.path) {
            try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }

    func saveMeeting(_ meeting: Meeting) throws {
        let dir = meetingDirectory(for: meeting.id)
        try ensureDirectoryExists(at: dir)
        let fileURL = dir.appendingPathComponent("meeting.json")
        let data = try encoder.encode(meeting)
        try data.write(to: fileURL, options: .atomic)
    }

    func loadMeeting(id: UUID) throws -> Meeting {
        let fileURL = meetingDirectory(for: id).appendingPathComponent("meeting.json")
        let data = try Data(contentsOf: fileURL)
        return try decoder.decode(Meeting.self, from: data)
    }

    func loadAllMeetings() throws -> [Meeting] {
        guard fileManager.fileExists(atPath: baseDirectory.path) else { return [] }

        let contents = try fileManager.contentsOfDirectory(
            at: baseDirectory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        var meetings: [Meeting] = []
        for dir in contents {
            let jsonFile = dir.appendingPathComponent("meeting.json")
            guard fileManager.fileExists(atPath: jsonFile.path) else { continue }
            do {
                let data = try Data(contentsOf: jsonFile)
                let meeting = try decoder.decode(Meeting.self, from: data)
                meetings.append(meeting)
            } catch {
                // Skip corrupted meetings
                continue
            }
        }
        return meetings.sorted { $0.createdAt > $1.createdAt }
    }

    func deleteMeeting(id: UUID) throws {
        let dir = meetingDirectory(for: id)
        if fileManager.fileExists(atPath: dir.path) {
            try fileManager.removeItem(at: dir)
        }
    }

    func audioFileURL(for meetingId: UUID, type: AudioFileType) -> URL {
        let dir = meetingDirectory(for: meetingId)
        return dir.appendingPathComponent(type.filename)
    }

    func exportNotes(_ notes: MeetingNotes, to url: URL, format: ExportFormat) throws {
        let content: String
        switch format {
        case .markdown:
            content = notes.rawMarkdown
        case .plainText:
            content = notes.rawMarkdown
                .replacingOccurrences(of: "## ", with: "")
                .replacingOccurrences(of: "**", with: "")
                .replacingOccurrences(of: "- [ ] ", with: "  * ")
                .replacingOccurrences(of: "- ", with: "  * ")
        }
        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    func exportTranscript(_ transcript: Transcript, title: String, to url: URL, format: ExportFormat) throws {
        let content: String
        switch format {
        case .markdown:
            content = formatTranscriptAsMarkdown(transcript, title: title)
        case .plainText:
            content = formatTranscriptAsPlainText(transcript, title: title)
        }
        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    private func formatTranscriptAsMarkdown(_ transcript: Transcript, title: String) -> String {
        var lines: [String] = []
        lines.append("# \(title) — Transcript")
        lines.append("")
        lines.append("*Generated on \(DateFormatters.meetingDate.string(from: transcript.createdAt))*")
        if let language = transcript.language {
            lines.append("*Language: \(language)*")
        }
        lines.append("")
        lines.append("---")
        lines.append("")

        for segment in transcript.segments {
            let start = formatTimestamp(segment.startTime)
            let end = formatTimestamp(segment.endTime)
            lines.append("**[\(start) – \(end)]** \(segment.text)")
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    private func formatTranscriptAsPlainText(_ transcript: Transcript, title: String) -> String {
        var lines: [String] = []
        lines.append("\(title) — Transcript")
        lines.append("")
        lines.append("Generated on \(DateFormatters.meetingDate.string(from: transcript.createdAt))")
        if let language = transcript.language {
            lines.append("Language: \(language)")
        }
        lines.append("")

        for segment in transcript.segments {
            let start = formatTimestamp(segment.startTime)
            let end = formatTimestamp(segment.endTime)
            lines.append("[\(start) – \(end)] \(segment.text)")
        }

        return lines.joined(separator: "\n")
    }

    private func formatTimestamp(_ seconds: Float) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }

    enum AudioFileType {
        case microphone
        case systemAudio
        case mixed

        var filename: String {
            switch self {
            case .microphone: return "mic-audio.wav"
            case .systemAudio: return "system-audio.wav"
            case .mixed: return "mixed-audio.wav"
            }
        }
    }

    enum ExportFormat {
        case markdown
        case plainText
    }
}
