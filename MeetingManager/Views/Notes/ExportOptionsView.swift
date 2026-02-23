import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

struct ExportOptionsView: View {
    let meetingNotes: MeetingNotes
    let meetingTitle: String
    @State private var showingExportError = false
    @State private var exportError: String = ""

    var body: some View {
        Menu {
            Button {
                exportFile(format: .markdown, fileExtension: "md")
            } label: {
                Label("Markdown (.md)", systemImage: "doc.text")
            }

            Button {
                exportFile(format: .plainText, fileExtension: "txt")
            } label: {
                Label("Plain Text (.txt)", systemImage: "doc.plaintext")
            }

            Divider()

            Button {
                exportNotesAsPDF()
            } label: {
                Label("PDF (.pdf)", systemImage: "doc.richtext")
            }

            Divider()

            Button {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(meetingNotes.rawMarkdown, forType: .string)
            } label: {
                Label("Copy to Clipboard", systemImage: "doc.on.doc")
            }
        } label: {
            Label("Export", systemImage: "square.and.arrow.up")
                .font(.caption)
        }
        .menuStyle(.borderlessButton)
        .frame(width: 80)
        .alert("Export Error", isPresented: $showingExportError) {
            Button("OK") { }
        } message: {
            Text(exportError)
        }
    }

    private func exportFile(format: StorageService.ExportFormat, fileExtension: String) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "\(meetingTitle)-notes.\(fileExtension)"
        panel.canCreateDirectories = true

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                try StorageService.shared.exportNotes(meetingNotes, to: url, format: format)
            } catch {
                exportError = error.localizedDescription
                showingExportError = true
            }
        }
    }

    private func exportNotesAsPDF() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "\(meetingTitle)-notes.pdf"
        panel.canCreateDirectories = true

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                let pdfData = Self.generateNotesPDF(notes: meetingNotes, title: meetingTitle)
                try pdfData.write(to: url, options: .atomic)
            } catch {
                exportError = error.localizedDescription
                showingExportError = true
            }
        }
    }

    private static func generateNotesPDF(notes: MeetingNotes, title: String) -> Data {
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

        startNewPage()

        // Title
        let titleFont = NSFont.systemFont(ofSize: 20, weight: .bold)
        _ = drawText("\(title) — Meeting Notes", font: titleFont, color: .black, maxWidth: contentWidth)
        currentY += 4

        // Metadata
        let metaFont = NSFont.systemFont(ofSize: 10, weight: .regular)
        let metaText = "Generated on \(DateFormatters.meetingDate.string(from: notes.generatedAt)) using \(notes.modelUsed)"
        _ = drawText(metaText, font: metaFont, color: .gray, maxWidth: contentWidth)
        currentY += 16

        // Render each line of markdown simply
        let headingFont = NSFont.systemFont(ofSize: 14, weight: .bold)
        let bodyFont = NSFont.systemFont(ofSize: 11, weight: .regular)

        let lines = notes.rawMarkdown.components(separatedBy: "\n")
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                currentY += 6
                continue
            }

            if trimmed.hasPrefix("## ") {
                currentY += 10
                let heading = String(trimmed.dropFirst(3))
                _ = drawText(heading, font: headingFont, color: .black, maxWidth: contentWidth)
                currentY += 4
            } else if trimmed.hasPrefix("# ") {
                let heading = String(trimmed.dropFirst(2))
                _ = drawText(heading, font: titleFont, color: .black, maxWidth: contentWidth)
                currentY += 6
            } else {
                // Strip basic markdown formatting for PDF
                var clean = trimmed
                    .replacingOccurrences(of: "**", with: "")
                    .replacingOccurrences(of: "__", with: "")
                    .replacingOccurrences(of: "- [ ] ", with: "  \u{2022} ")
                    .replacingOccurrences(of: "- [x] ", with: "  \u{2713} ")
                if clean.hasPrefix("- ") || clean.hasPrefix("* ") {
                    clean = "  \u{2022} " + String(clean.dropFirst(2))
                }
                _ = drawText(clean, font: bodyFont, color: .black, maxWidth: contentWidth)
                currentY += 2
            }
        }

        endPage()
        context.closePDF()

        return pdfData as Data
    }
}
