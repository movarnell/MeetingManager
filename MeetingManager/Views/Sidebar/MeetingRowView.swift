import SwiftUI

struct MeetingRowView: View {
    let meeting: Meeting

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(meeting.title)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                if meeting.isRecording {
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                }
            }

            HStack(spacing: 8) {
                Text(DateFormatters.meetingDate.string(from: meeting.createdAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if meeting.duration > 0 {
                    Text(DateFormatters.formatDuration(meeting.duration))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !meeting.tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(meeting.tags.prefix(3), id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 10))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.1), in: Capsule())
                            .foregroundStyle(.blue)
                    }
                    if meeting.tags.count > 3 {
                        Text("+\(meeting.tags.count - 3)")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            HStack(spacing: 12) {
                if meeting.transcript != nil {
                    Label("Transcribed", systemImage: "text.word.spacing")
                        .font(.system(size: 10))
                        .foregroundStyle(.green)
                }
                if meeting.meetingNotes != nil {
                    Label("Notes", systemImage: "doc.text")
                        .font(.system(size: 10))
                        .foregroundStyle(.purple)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
