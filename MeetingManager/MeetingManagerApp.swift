import SwiftUI

@main
struct MeetingManagerApp: App {
    @State private var listVM = MeetingsListViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(listVM)
        }
        .defaultSize(width: 1100, height: 700)
        .commands {
            CommandGroup(after: .newItem) {
                Button("New Recording") {
                    listVM.selectedMeetingId = nil
                    NSApp.activate(ignoringOtherApps: true)
                }
                .keyboardShortcut("r", modifiers: [.command])
            }
        }

        Settings {
            SettingsView()
        }

        MenuBarExtra("MeetingManager", systemImage: "waveform.circle.fill") {
            MenuBarView()
                .environment(listVM)
        }
    }
}
