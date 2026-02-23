import SwiftUI

struct StatusIndicatorView: View {
    let isOnline: Bool
    var label: String?

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isOnline ? Color.green : Color.red)
                .frame(width: 8, height: 8)
                .shadow(color: isOnline ? .green.opacity(0.5) : .red.opacity(0.5), radius: 3)

            if let label = label {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
