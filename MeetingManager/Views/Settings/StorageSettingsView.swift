import SwiftUI

struct StorageSettingsView: View {
    @State private var storageSize: String = "Calculating..."
    @State private var meetingCount: Int = 0

    var body: some View {
        Form {
            Section {
                LabeledContent("Location") {
                    HStack {
                        Text("~/Documents/MeetingManager/")
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)

                        Button {
                            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                                .appendingPathComponent("MeetingManager")
                            NSWorkspace.shared.open(url)
                        } label: {
                            Image(systemName: "folder")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }

                LabeledContent("Meetings") {
                    Text("\(meetingCount)")
                        .foregroundStyle(.secondary)
                }

                LabeledContent("Storage Used") {
                    Text(storageSize)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Storage")
            }

            Section {
                Text("Each meeting is stored in its own folder containing audio files, transcript data, and generated notes. All data stays on your Mac.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("About Storage")
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            calculateStorage()
        }
    }

    private func calculateStorage() {
        let meetings = (try? StorageService.shared.loadAllMeetings()) ?? []
        meetingCount = meetings.count

        Task {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let baseDir = docs.appendingPathComponent("MeetingManager")

            guard let enumerator = FileManager.default.enumerator(
                at: baseDir,
                includingPropertiesForKeys: [.fileSizeKey],
                options: [.skipsHiddenFiles]
            ) else {
                storageSize = "0 MB"
                return
            }

            var totalSize: Int64 = 0
            while let url = enumerator.nextObject() as? URL {
                if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += Int64(size)
                }
            }

            let mb = Double(totalSize) / 1_048_576
            if mb >= 1024 {
                storageSize = String(format: "%.1f GB", mb / 1024)
            } else {
                storageSize = String(format: "%.1f MB", mb)
            }
        }
    }
}
