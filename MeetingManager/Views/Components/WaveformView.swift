import SwiftUI

struct WaveformView: View {
    let level: Float
    let barCount: Int
    let color: Color

    @State private var animatedLevels: [Float]

    init(level: Float, barCount: Int = 30, color: Color = .blue) {
        self.level = level
        self.barCount = barCount
        self.color = color
        _animatedLevels = State(initialValue: Array(repeating: 0, count: barCount))
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(
                        color.opacity(0.3 + Double(animatedLevels[index]) * 0.7)
                    )
                    .frame(width: 3, height: CGFloat(animatedLevels[index]) * 40 + 3)
            }
        }
        .frame(height: 44)
        .onChange(of: level) { _, newLevel in
            withAnimation(.easeOut(duration: 0.1)) {
                var updated = animatedLevels
                for i in 0..<(barCount - 1) {
                    updated[i] = updated[i + 1]
                }
                let jitter = Float.random(in: -0.1...0.1)
                updated[barCount - 1] = max(0, min(1, newLevel + jitter))
                animatedLevels = updated
            }
        }
    }
}
