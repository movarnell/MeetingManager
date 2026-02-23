import SwiftUI

struct MeetingsSidebarView: View {
    @Environment(MeetingsListViewModel.self) private var listVM
    @State private var showingNewRecording = false

    var body: some View {
        @Bindable var vm = listVM

        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Meetings")
                    .font(.headline)

                Spacer()

                Button {
                    showingNewRecording = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
                .help("New Recording")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                TextField("Search meetings...", text: $vm.searchText)
                    .textFieldStyle(.plain)
                    .font(.body)

                if !vm.searchText.isEmpty {
                    Button {
                        vm.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 12)
            .padding(.bottom, 8)

            Divider()

            // Meeting list
            if vm.filteredMeetings.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text(vm.searchText.isEmpty ? "No meetings yet" : "No matching meetings")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if vm.searchText.isEmpty {
                        Text("Start a new recording to begin")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List(selection: $vm.selectedMeetingId) {
                    ForEach(vm.filteredMeetings) { meeting in
                        MeetingRowView(meeting: meeting)
                            .tag(meeting.id)
                            .contextMenu {
                                Button("Delete", role: .destructive) {
                                    vm.deleteMeeting(meeting)
                                }
                            }
                    }
                    .onDelete { offsets in
                        vm.deleteMeetings(at: offsets)
                    }
                }
                .listStyle(.sidebar)
            }
        }
        .onChange(of: showingNewRecording) { _, show in
            if show {
                listVM.selectedMeetingId = nil
                showingNewRecording = false
            }
        }
    }
}
