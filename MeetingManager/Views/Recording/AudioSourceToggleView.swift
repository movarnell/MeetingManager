import SwiftUI

struct AudioSourceToggleView: View {
    let title: String
    let icon: String
    @Binding var isEnabled: Bool
    let level: Float

    var body: some View {
        VStack(spacing: 12) {
            // Icon and toggle
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(isEnabled ? .blue : .secondary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(isEnabled ? "Active" : "Disabled")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Toggle("", isOn: $isEnabled)
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }

            // Mini level indicator
            if isEnabled {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.quaternary)

                        RoundedRectangle(cornerRadius: 2)
                            .fill(levelColor)
                            .frame(width: geo.size.width * CGFloat(level))
                            .animation(.easeOut(duration: 0.08), value: level)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isEnabled ? Color.blue.opacity(0.05) : Color.gray.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isEnabled ? Color.blue.opacity(0.2) : Color.gray.opacity(0.15), lineWidth: 1)
        )
        .frame(width: 200)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }

    private var levelColor: Color {
        if level > 0.85 { return .red }
        if level > 0.65 { return .orange }
        return .green
    }
}
