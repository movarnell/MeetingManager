import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

struct TranscriptView: View {
    let meeting: Meeting
    @Binding var selectedTab: MeetingDetailView.DetailTab
    @State private var transcriptionVM = TranscriptionViewModel()
    @State private var showingExportError = false
    @State private var exportError = ""
    @Environment(MeetingsListViewModel.self) private var listVM

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 12) {
                // Search
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                    TextField("Search transcript...", text: $transcriptionVM.searchText)
                        .textFieldStyle(.plain)
                        .font(.body)
                }
                .padding(6)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 6))
                .frame(maxWidth: 300)

                Spacer()

                if transcriptionVM.transcript != nil {
                    // Export menu
                    transcriptExportMenu

                    // Copy button
                    Button {
                        if let text = transcriptionVM.copyTranscript() {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(text, forType: .string)
                        }
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.bar)

            Divider()

            // Content
            if transcriptionVM.isPreparingModel {
                modelDownloadView
            } else if transcriptionVM.isTranscribing {
                transcribingView
            } else if transcriptionVM.transcript != nil {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(transcriptionVM.filteredSegments) { segment in
                            TranscriptSegmentView(segment: segment)
                        }
                    }
                    .padding(16)

                    // Generate Notes prompt at bottom of transcript
                    if meeting.meetingNotes == nil {
                        generateNotesPrompt
                            .padding(.horizontal, 16)
                            .padding(.bottom, 20)
                    }
                }
            } else {
                emptyStateView
            }
        }
        .onAppear {
            transcriptionVM.transcript = meeting.transcript
        }
        .alert("Export Error", isPresented: $showingExportError) {
            Button("OK") { }
        } message: {
            Text(exportError)
        }
    }

    // MARK: - Transcript Export Menu

    private var transcriptExportMenu: some View {
        Menu {
            Button {
                exportTranscript(fileExtension: "md", format: .markdown)
            } label: {
                Label("Markdown (.md)", systemImage: "doc.text")
            }

            Button {
                exportTranscript(fileExtension: "txt", format: .plainText)
            } label: {
                Label("Plain Text (.txt)", systemImage: "doc.plaintext")
            }

            Divider()

            Button {
                exportTranscriptAsPDF()
            } label: {
                Label("PDF (.pdf)", systemImage: "doc.richtext")
            }
        } label: {
            Label("Export", systemImage: "square.and.arrow.up")
                .font(.caption)
        }
        .menuStyle(.borderlessButton)
        .frame(width: 80)
    }

    private func exportTranscript(fileExtension: String, format: StorageService.ExportFormat) {
        guard let transcript = transcriptionVM.transcript else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "\(meeting.title)-transcript.\(fileExtension)"
        panel.canCreateDirectories = true

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                try StorageService.shared.exportTranscript(
                    transcript,
                    title: meeting.title,
                    to: url,
                    format: format
                )
            } catch {
                exportError = error.localizedDescription
                showingExportError = true
            }
        }
    }

    private func exportTranscriptAsPDF() {
        guard let transcript = transcriptionVM.transcript else { return }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "\(meeting.title)-transcript.pdf"
        panel.canCreateDirectories = true

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                let pdfData = Self.generateTranscriptPDF(transcript: transcript, title: meeting.title)
                try pdfData.write(to: url, options: .atomic)
            } catch {
                exportError = error.localizedDescription
                showingExportError = true
            }
        }
    }

    private static func generateTranscriptPDF(transcript: Transcript, title: String) -> Data {
        let pageWidth: CGFloat = 612  // US Letter
        let pageHeight: CGFloat = 792
        let margin: CGFloat = 50
        let contentWidth = pageWidth - margin * 2

        let pdfData = NSMutableData()
        var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)

        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil)
        else {
            return Data()
        }

        var currentY: CGFloat = 0

        func startNewPage() {
            context.beginPDFPage(nil)
            // Flip coordinate system for text drawing
            context.translateBy(x: 0, y: pageHeight)
            context.scaleBy(x: 1.0, y: -1.0)
            currentY = margin
        }

        func endPage() {
            context.endPDFPage()
        }

        func drawText(_ text: String, font: NSFont, color: NSColor, maxWidth: CGFloat) -> CGFloat {
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: color
            ]
            let attrString = NSAttributedString(string: text, attributes: attributes)
            let framesetter = CTFramesetterCreateWithAttributedString(attrString)
            let suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(
                framesetter,
                CFRangeMake(0, attrString.length),
                nil,
                CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
                nil
            )

            let height = ceil(suggestedSize.height)

            // Check if we need a new page
            if currentY + height > pageHeight - margin {
                endPage()
                startNewPage()
            }

            let rect = CGRect(x: margin, y: currentY, width: maxWidth, height: height)
            let path = CGPath(rect: rect, transform: nil)
            let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, attrString.length), path, nil)
            CTFrameDraw(frame, context)
            currentY += height
            return height
        }

        // Start first page
        startNewPage()

        // Title
        let titleFont = NSFont.systemFont(ofSize: 20, weight: .bold)
        _ = drawText("\(title) — Transcript", font: titleFont, color: .black, maxWidth: contentWidth)
        currentY += 8

        // Date
        let metaFont = NSFont.systemFont(ofSize: 10, weight: .regular)
        let dateString = "Generated on \(DateFormatters.meetingDate.string(from: transcript.createdAt))"
        _ = drawText(dateString, font: metaFont, color: .gray, maxWidth: contentWidth)
        currentY += 16

        // Segments
        let timestampFont = NSFont.monospacedSystemFont(ofSize: 9, weight: .medium)
        let textFont = NSFont.systemFont(ofSize: 11, weight: .regular)

        for segment in transcript.segments {
            let start = formatTimestampStatic(segment.startTime)
            let end = formatTimestampStatic(segment.endTime)
            let timestamp = "[\(start) – \(end)]"

            _ = drawText(timestamp, font: timestampFont, color: NSColor.systemBlue, maxWidth: contentWidth)
            currentY += 2
            _ = drawText(segment.text, font: textFont, color: .black, maxWidth: contentWidth)
            currentY += 10
        }

        endPage()
        context.closePDF()

        return pdfData as Data
    }

    private static func formatTimestampStatic(_ seconds: Float) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        }
        return String(format: "%d:%02d", minutes, secs)
    }

    // MARK: - Generate Notes Prompt

    private var generateNotesPrompt: some View {
        VStack(spacing: 12) {
            Divider()
                .padding(.bottom, 4)

            HStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(
                        .linearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Generate Meeting Notes")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Send this transcript to Ollama for AI-powered summary, key points, and action items")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    selectedTab = .notes
                } label: {
                    Label("Go to Notes", systemImage: "arrow.right")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.purple.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.purple.opacity(0.12), lineWidth: 1)
            )
        }
    }

    // MARK: - Model Download / Loading View

    private var modelDownloadView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "arrow.down.circle")
                .font(.system(size: 44))
                .foregroundStyle(
                    .linearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .symbolEffect(.pulse, options: .repeating)

            switch transcriptionVM.downloadState {
            case .determining:
                Text("Determining Best Model")
                    .font(.title3)
                    .fontWeight(.medium)
                Text("Checking your hardware for the optimal Whisper model...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 350)
                ProgressView()
                    .scaleEffect(1.2)

            case .downloading(let fraction, _):
                Text("Downloading Whisper Model")
                    .font(.title3)
                    .fontWeight(.medium)

                if let modelName = transcriptionVM.currentModelName {
                    Text(modelName)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.blue.opacity(0.1), in: Capsule())
                        .foregroundStyle(.blue)
                }

                VStack(spacing: 8) {
                    ProgressView(value: fraction)
                        .progressViewStyle(.linear)
                        .frame(maxWidth: 320)
                        .tint(.blue)

                    Text("\(Int(fraction * 100))% complete")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                Text("This is a one-time download. The model will be cached for future use.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 350)

            case .downloaded, .loading:
                Text("Loading Model")
                    .font(.title3)
                    .fontWeight(.medium)
                Text("Preparing the model for transcription...")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 350)
                ProgressView()
                    .scaleEffect(1.2)

            default:
                EmptyView()
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Transcribing View

    private var transcribingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
            Text("Transcribing Audio")
                .font(.title3)
                .fontWeight(.medium)
            Text(transcriptionVM.loadingStatus)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("This may take a few minutes for long recordings...")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "text.word.spacing")
                .font(.system(size: 48))
                .foregroundStyle(
                    .linearGradient(
                        colors: [.blue.opacity(0.5), .purple.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Transcription Not Generated")
                .font(.title3)
                .fontWeight(.medium)

            Text("Use WhisperKit to transcribe your meeting recording locally")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)

            Button {
                Task {
                    if let transcript = await transcriptionVM.transcribe(meeting: meeting) {
                        // Save transcript back to the meeting and update the list
                        var updatedMeeting = meeting
                        updatedMeeting.transcript = transcript
                        listVM.updateMeeting(updatedMeeting)
                    }
                }
            } label: {
                Label("Transcribe Recording", systemImage: "waveform")
                    .fontWeight(.medium)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(meeting.audioFileURL == nil && meeting.micAudioFileURL == nil && meeting.systemAudioFileURL == nil)

            if let error = transcriptionVM.errorMessage {
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
}
