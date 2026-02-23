import SwiftUI

struct RecordButtonView: View {
    let state: RecordingState
    let action: () -> Void

    @State private var isPulsing = false

    var body: some View {
        Button(action: action) {
            buttonContent
        }
        .buttonStyle(.plain)
        .disabled(state == .stopping || state == .processing)
        .onChange(of: state) { _, newValue in
            withAnimation(
                newValue == .recording
                    ? .easeInOut(duration: 1.0).repeatForever(autoreverses: true)
                    : .default
            ) {
                isPulsing = newValue == .recording
            }
        }
    }

    private var buttonContent: some View {
        ZStack {
            // Outer pulsing ring
            outerRing

            // Middle ring
            Circle()
                .stroke(Color.red.opacity(0.15), lineWidth: 2)
                .frame(width: 80, height: 80)

            // Main button
            mainButton
        }
    }

    private var outerRing: some View {
        Circle()
            .stroke(
                state == .recording ? Color.red.opacity(0.3) : Color.clear,
                lineWidth: 4
            )
            .frame(width: 88, height: 88)
            .scaleEffect(isPulsing ? 1.3 : 1.0)
    }

    private var mainButton: some View {
        Circle()
            .fill(Color.red)
            .frame(width: 68, height: 68)
            .shadow(color: .red.opacity(0.4), radius: state == .recording ? 12 : 6, y: 2)
            .overlay {
                buttonIcon
            }
    }

    @ViewBuilder
    private var buttonIcon: some View {
        if state == .recording {
            RoundedRectangle(cornerRadius: 6)
                .fill(.white)
                .frame(width: 22, height: 22)
        } else if state == .stopping || state == .processing {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(0.8)
                .tint(.white)
        } else {
            Circle()
                .fill(.white)
                .frame(width: 24, height: 24)
        }
    }
}
