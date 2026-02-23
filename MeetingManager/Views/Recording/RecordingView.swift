import SwiftUI

struct RecordingView: View {
    @Environment(MeetingsListViewModel.self) private var listVM
    @State private var recordingVM = RecordingViewModel()

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 32) {
                    Spacer(minLength: 20)

                    // Meeting title
                    VStack(spacing: 8) {
                        TextField("Meeting Title", text: $recordingVM.meetingTitle)
                            .textFieldStyle(.plain)
                            .font(.title2)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 400)
                            .disabled(recordingVM.state.isActive)

                        if recordingVM.meetingTitle.isEmpty && recordingVM.state == .idle {
                            Text("Enter a title or start recording")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }

                    // Audio source toggles
                    HStack(spacing: 16) {
                        AudioSourceToggleView(
                            title: "Microphone",
                            icon: "mic.fill",
                            isEnabled: $recordingVM.micEnabled,
                            level: recordingVM.micLevel
                        )
                        .disabled(recordingVM.state.isActive)

                        AudioSourceToggleView(
                            title: "System Audio",
                            icon: "speaker.wave.2.fill",
                            isEnabled: $recordingVM.systemAudioEnabled,
                            level: recordingVM.systemLevel
                        )
                        .disabled(recordingVM.state.isActive)
                    }

                    // Timer
                    RecordingTimerView(
                        duration: recordingVM.duration,
                        isRecording: recordingVM.state == .recording
                    )

                    // Audio level meters
                    if recordingVM.state == .recording {
                        HStack(spacing: 24) {
                            if recordingVM.micEnabled {
                                AudioLevelMeterView(
                                    level: recordingVM.micLevel,
                                    label: "Microphone"
                                )
                            }
                            if recordingVM.systemAudioEnabled {
                                AudioLevelMeterView(
                                    level: recordingVM.systemLevel,
                                    label: "System"
                                )
                            }
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }

                    // Record button
                    RecordButtonView(state: recordingVM.state) {
                        Task {
                            if recordingVM.state == .idle {
                                do {
                                    let meetingId = try await recordingVM.startRecording()
                                } catch {
                                    // Error is set in the view model
                                }
                            } else if recordingVM.state == .recording {
                                if let meeting = await recordingVM.stopRecording() {
                                    listVM.addOrUpdateMeeting(meeting)
                                }
                            }
                        }
                    }
                    .disabled(!recordingVM.atLeastOneSourceEnabled && recordingVM.state == .idle)

                    // Bookmark button (visible during recording)
                    if recordingVM.state == .recording {
                        Button {
                            recordingVM.addBookmark()
                        } label: {
                            Label("Add Bookmark", systemImage: "bookmark.fill")
                                .font(.subheadline)
                        }
                        .buttonStyle(.bordered)
                        .tint(.orange)
                        .transition(.opacity)
                    }

                    // Error message
                    if let error = recordingVM.errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                    }

                    // Hint
                    if recordingVM.state == .idle && !recordingVM.atLeastOneSourceEnabled {
                        Text("Enable at least one audio source to start recording")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }

                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 40)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: recordingVM.state)
    }
}
