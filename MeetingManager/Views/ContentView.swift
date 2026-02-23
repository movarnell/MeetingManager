import SwiftUI

struct ContentView: View {
    @Environment(MeetingsListViewModel.self) private var listVM
    @State private var showingNewRecording = false

    var body: some View {
        @Bindable var vm = listVM

        NavigationSplitView {
            MeetingsSidebarView()
                .navigationSplitViewColumnWidth(
                    min: AppConstants.UI.sidebarMinWidth,
                    ideal: AppConstants.UI.sidebarIdealWidth
                )
        } detail: {
            if showingNewRecording || listVM.selectedMeetingId == nil && listVM.meetings.isEmpty {
                RecordingView()
            } else if let meetingId = listVM.selectedMeetingId, listVM.selectedMeeting != nil {
                MeetingDetailView(meetingId: meetingId)
            } else {
                EmptyStateView(
                    title: "No Meeting Selected",
                    subtitle: "Select a meeting from the sidebar or start a new recording",
                    systemImage: "waveform.badge.plus",
                    action: { showingNewRecording = true },
                    actionTitle: "New Recording"
                )
            }
        }
        .frame(
            minWidth: AppConstants.UI.windowMinWidth,
            minHeight: AppConstants.UI.windowMinHeight
        )
        .onAppear {
            listVM.loadMeetings()
        }
        .onChange(of: listVM.selectedMeetingId) { _, newValue in
            if newValue != nil {
                showingNewRecording = false
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewRecording = true
                    listVM.selectedMeetingId = nil
                } label: {
                    Label("New Recording", systemImage: "plus")
                }
                .keyboardShortcut("n", modifiers: [.command])
            }
        }
    }
}
