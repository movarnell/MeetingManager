import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

struct MeetingNotesView: View {
    let meetingId: UUID
    @State private var notesVM = MeetingNotesViewModel()
    @Environment(MeetingsListViewModel.self) private var listVM

    /// Always read the live meeting so we see transcript updates from the other tab
    private var meeting: Meeting? {
        listVM.meetings.first { $0.id == meetingId }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 12) {
                // Ollama status
                StatusIndicatorView(
                    isOnline: notesVM.isOllamaAvailable,
                    label: notesVM.isOllamaAvailable ? "Ollama Connected" : "Ollama Offline"
                )

                if notesVM.isOllamaAvailable {
                    Picker("Model", selection: Binding(
                        get: { notesVM.selectedModel },
                        set: { notesVM.selectedModel = $0 }
                    )) {
                        ForEach(notesVM.availableModels) { model in
                            Text("\(model.displayName) (\(model.sizeDescription))")
                                .tag(model.name)
                        }
                    }
                    .frame(maxWidth: 250)
                }

                Spacer()

                if notesVM.meetingNotes != nil {
                    Button {
                        if let text = notesVM.copyNotes() {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(text, forType: .string)
                        }
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    ExportOptionsView(
                        meetingNotes: notesVM.meetingNotes!,
                        meetingTitle: meeting?.title ?? "Meeting"
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.bar)

            Divider()

            // Content
            if notesVM.isGenerating {
                streamingView
            } else if let notes = notesVM.meetingNotes {
                renderedNotesView(notes: notes)
            } else {
                emptyStateView
            }
        }
        .onAppear {
            notesVM.meetingNotes = meeting?.meetingNotes
            if let existingFormat = meeting?.meetingNotes?.format {
                notesVM.selectedFormat = existingFormat
            }
            Task { await notesVM.checkOllamaStatus() }
        }
    }

    // MARK: - Streaming View

    private var streamingView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Generating \(notesVM.selectedFormat.displayName.lowercased()) with \(notesVM.selectedModel)...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 8)

                MarkdownRendererView(markdown: notesVM.streamingText)
            }
            .padding(16)
        }
    }

    // MARK: - Rendered Notes View

    private func renderedNotesView(notes: MeetingNotes) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Metadata bar
                HStack(spacing: 12) {
                    Label(notes.modelUsed, systemImage: "brain")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Label(notes.format.displayName, systemImage: notes.format.icon)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Label(DateFormatters.meetingDate.string(from: notes.generatedAt), systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Menu {
                        ForEach(NoteFormat.allCases) { format in
                            Button {
                                notesVM.selectedFormat = format
                                guard let transcript = meeting?.transcript else { return }
                                Task {
                                    await notesVM.regenerateNotes(from: transcript)
                                    saveNotesToMeeting()
                                }
                            } label: {
                                Label(format.displayName, systemImage: format.icon)
                            }
                        }
                    } label: {
                        Label("Regenerate", systemImage: "arrow.clockwise")
                            .font(.caption)
                    }
                    .menuStyle(.borderlessButton)
                    .frame(width: 110)
                }
                .padding(.bottom, 4)

                // Rendered markdown content
                MarkdownRendererView(markdown: notes.rawMarkdown)
            }
            .padding(16)
        }
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(
                    .linearGradient(
                        colors: [.purple.opacity(0.5), .blue.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Meeting Notes Not Generated")
                .font(.title3)
                .fontWeight(.medium)

            if !notesVM.isOllamaAvailable {
                VStack(spacing: 8) {
                    Text("Ollama is not running")
                        .font(.subheadline)
                        .foregroundStyle(.orange)

                    Text("Start Ollama to generate AI-powered meeting notes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if meeting?.transcript == nil {
                Text("Transcribe the recording first, then generate notes")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                // Format picker
                VStack(spacing: 12) {
                    Text("Choose a format")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    formatPicker
                }
            }

            Button {
                guard let transcript = meeting?.transcript else { return }
                Task {
                    await notesVM.generateNotes(from: transcript)
                    saveNotesToMeeting()
                }
            } label: {
                Label("Generate Meeting Notes", systemImage: "sparkles")
                    .fontWeight(.medium)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(!notesVM.isOllamaAvailable || meeting?.transcript == nil)

            if let error = notesVM.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Format Picker

    private var formatPicker: some View {
        HStack(spacing: 10) {
            ForEach(NoteFormat.allCases) { format in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        notesVM.selectedFormat = format
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: format.icon)
                            .font(.system(size: 20))
                            .frame(height: 24)

                        Text(format.displayName)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .lineLimit(1)

                        Text(format.description)
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                            .lineLimit(2, reservesSpace: true)
                            .multilineTextAlignment(.center)
                    }
                    .frame(width: 120, height: 90)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(notesVM.selectedFormat == format
                                  ? Color.accentColor.opacity(0.1)
                                  : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(notesVM.selectedFormat == format
                                    ? Color.accentColor.opacity(0.5)
                                    : Color.secondary.opacity(0.2),
                                    lineWidth: notesVM.selectedFormat == format ? 2 : 1)
                    )
                    .foregroundStyle(notesVM.selectedFormat == format ? .primary : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Helpers

    private func saveNotesToMeeting() {
        guard let notes = notesVM.meetingNotes,
              var updatedMeeting = meeting else { return }
        updatedMeeting.meetingNotes = notes
        listVM.updateMeeting(updatedMeeting)
    }
}
