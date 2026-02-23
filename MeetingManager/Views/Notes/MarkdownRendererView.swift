import SwiftUI

struct MarkdownRendererView: View {
    let markdown: String

    private var blocks: [MarkdownBlock] {
        parseMarkdown(markdown)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                blockView(for: block)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .textSelection(.enabled)
    }

    @ViewBuilder
    private func blockView(for block: MarkdownBlock) -> some View {
        switch block {
        case .heading1(let text):
            Text(renderInline(text))
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top, 16)
                .padding(.bottom, 6)

        case .heading2(let text):
            VStack(alignment: .leading, spacing: 0) {
                Text(renderInline(text))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Rectangle()
                    .fill(.quaternary)
                    .frame(height: 1)
                    .padding(.top, 4)
            }
            .padding(.top, 20)
            .padding(.bottom, 8)

        case .heading3(let text):
            Text(renderInline(text))
                .font(.headline)
                .fontWeight(.medium)
                .padding(.top, 14)
                .padding(.bottom, 4)

        case .bullet(let text):
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Circle()
                    .fill(.secondary)
                    .frame(width: 5, height: 5)
                    .offset(y: 1)
                Text(renderInline(text))
                    .font(.body)
            }
            .padding(.leading, 12)
            .padding(.vertical, 2)

        case .checkbox(let text, let checked):
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: checked ? "checkmark.square.fill" : "square")
                    .font(.system(size: 13))
                    .foregroundStyle(checked ? .green : .secondary)
                Text(renderInline(text))
                    .font(.body)
                    .strikethrough(checked, color: .secondary)
                    .foregroundStyle(checked ? .secondary : .primary)
            }
            .padding(.leading, 12)
            .padding(.vertical, 2)

        case .paragraph(let text):
            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(renderInline(text))
                    .font(.body)
                    .padding(.vertical, 3)
            }

        case .divider:
            Rectangle()
                .fill(.quaternary)
                .frame(height: 1)
                .padding(.vertical, 10)

        case .blank:
            Spacer()
                .frame(height: 6)
        }
    }

    // MARK: - Inline Markdown Rendering

    private func renderInline(_ text: String) -> AttributedString {
        // Try Apple's built-in markdown parser first
        if let attributed = try? AttributedString(
            markdown: text,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            return attributed
        }
        // Fallback to plain text
        return AttributedString(text)
    }

    // MARK: - Block-Level Markdown Parsing

    private func parseMarkdown(_ raw: String) -> [MarkdownBlock] {
        let lines = raw.components(separatedBy: "\n")
        var blocks: [MarkdownBlock] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                // Collapse consecutive blanks
                if case .blank = blocks.last {
                    continue
                }
                blocks.append(.blank)
            } else if trimmed.hasPrefix("### ") {
                blocks.append(.heading3(String(trimmed.dropFirst(4))))
            } else if trimmed.hasPrefix("## ") {
                blocks.append(.heading2(String(trimmed.dropFirst(3))))
            } else if trimmed.hasPrefix("# ") {
                blocks.append(.heading1(String(trimmed.dropFirst(2))))
            } else if trimmed.hasPrefix("---") || trimmed.hasPrefix("***") || trimmed.hasPrefix("___") {
                blocks.append(.divider)
            } else if trimmed.hasPrefix("- [x] ") || trimmed.hasPrefix("- [X] ") {
                blocks.append(.checkbox(String(trimmed.dropFirst(6)), true))
            } else if trimmed.hasPrefix("- [ ] ") {
                blocks.append(.checkbox(String(trimmed.dropFirst(6)), false))
            } else if trimmed.hasPrefix("- ") {
                blocks.append(.bullet(String(trimmed.dropFirst(2))))
            } else if trimmed.hasPrefix("* ") {
                blocks.append(.bullet(String(trimmed.dropFirst(2))))
            } else {
                // Merge consecutive paragraphs
                if case .paragraph(let existing) = blocks.last {
                    blocks[blocks.count - 1] = .paragraph(existing + " " + trimmed)
                } else {
                    blocks.append(.paragraph(trimmed))
                }
            }
        }

        return blocks
    }
}

private enum MarkdownBlock {
    case heading1(String)
    case heading2(String)
    case heading3(String)
    case bullet(String)
    case checkbox(String, Bool)
    case paragraph(String)
    case divider
    case blank
}
