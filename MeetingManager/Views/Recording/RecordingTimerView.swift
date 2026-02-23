import SwiftUI

struct RecordingTimerView: View {
    let duration: TimeInterval
    let isRecording: Bool

    var body: some View {
        HStack(spacing: 8) {
            if isRecording {
                Circle()
                    .fill(.red)
                    .frame(width: 10, height: 10)
                    .opacity(pulseOpacity)
            }

            Text(DateFormatters.formatDuration(duration))
                .font(.system(size: 42, weight: .light, design: .monospaced))
                .foregroundStyle(isRecording ? .primary : .secondary)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.1), value: duration)
        }
    }

    @State private var pulseOpacity: Double = 1.0

    init(duration: TimeInterval, isRecording: Bool = false) {
        self.duration = duration
        self.isRecording = isRecording
    }
}
