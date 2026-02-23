import SwiftUI

struct MenuBarView: View {
    @Environment(MeetingsListViewModel.self) private var listVM

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button("New Recording...") {
                NSApp.activate(ignoringOtherApps: true)
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])

            Divider()

            if listVM.meetings.isEmpty {
                Text("No recordings yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
            } else {
                Text("Recent Meetings")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 8)

                ForEach(listVM.meetings.prefix(5)) { meeting in
                    Button {
                        listVM.selectedMeetingId = meeting.id
                        NSApp.activate(ignoringOtherApps: true)
                    } label: {
                        HStack {
                            Text(meeting.title)
                                .lineLimit(1)
                            Spacer()
                            Text(DateFormatters.relativeDate.localizedString(for: meeting.createdAt, relativeTo: Date()))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Divider()

            Button("Quit MeetingManager") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(4)
    }
}
