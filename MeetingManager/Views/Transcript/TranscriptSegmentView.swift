import SwiftUI

struct TranscriptSegmentView: View {
    let segment: TranscriptSegment

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timestamp badge
            Text(DateFormatters.formatTimestamp(segment.startTime))
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
                .frame(width: 70, alignment: .trailing)

            // Segment text
            Text(segment.text)
                .font(.body)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 2)
    }
}
