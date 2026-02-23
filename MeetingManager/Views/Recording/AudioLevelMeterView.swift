import SwiftUI

struct AudioLevelMeterView: View {
    let level: Float
    let label: String
    var barCount: Int = 20

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 2) {
                ForEach(0..<barCount, id: \.self) { index in
                    let threshold = Float(index) / Float(barCount)
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(barColor(for: index))
                        .opacity(level >= threshold ? 1.0 : 0.12)
                        .frame(width: 8)
                        .animation(.easeOut(duration: 0.08), value: level)
                }
            }
            .frame(height: 28)
            .padding(.horizontal, 4)

            Text(label)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
    }

    private func barColor(for index: Int) -> Color {
        let ratio = Float(index) / Float(barCount)
        if ratio > 0.85 { return .red }
        if ratio > 0.65 { return .orange }
        if ratio > 0.45 { return .yellow }
        return .green
    }
}
