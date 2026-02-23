import SwiftUI

struct MeetingDetailView: View {
    let meetingId: UUID
    @State private var selectedTab: DetailTab = .transcript
    @Environment(MeetingsListViewModel.self) private var listVM

    /// Always read the live meeting from the list so transcript/notes updates propagate
    private var meeting: Meeting? {
        listVM.meetings.first { $0.id == meetingId }
    }

    enum DetailTab: String, CaseIterable {
        case transcript = "Transcript"
        case notes = "Meeting Notes"

        var icon: String {
            switch self {
            case .transcript: return "text.word.spacing"
            case .notes: return "doc.text"
            }
        }
    }

    var body: some View {
        if let meeting {
        VStack(spacing: 0) {
            // Meeting header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(meeting.title)
                            .font(.title2)
                            .fontWeight(.semibold)

                        HStack(spacing: 12) {
                            Label(
                                DateFormatters.meetingDate.string(from: meeting.createdAt),
                                systemImage: "calendar"
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)

                            if meeting.duration > 0 {
                                Label(
                                    DateFormatters.formatDuration(meeting.duration),
                                    systemImage: "clock"
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }

                            if meeting.micAudioFileURL != nil {
                                Label("Mic", systemImage: "mic.fill")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }

                            if meeting.systemAudioFileURL != nil {
                                Label("System", systemImage: "speaker.wave.2.fill")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                        }
                    }

                    Spacer()
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.bar)

            // Tab bar
            HStack(spacing: 0) {
                ForEach(DetailTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = tab
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.caption)
                            Text(tab.rawValue)
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            selectedTab == tab
                                ? Color.accentColor.opacity(0.1)
                                : Color.clear,
                            in: RoundedRectangle(cornerRadius: 6)
                        )
                        .foregroundStyle(selectedTab == tab ? .blue : .secondary)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(.bar)

            Divider()

            // Tab content
            switch selectedTab {
            case .transcript:
                TranscriptView(meeting: meeting, selectedTab: $selectedTab)
            case .notes:
                MeetingNotesView(meetingId: meetingId)
            }
        }
        } else {
            ContentUnavailableView("Meeting Not Found", systemImage: "exclamationmark.triangle")
        }
    }
}
