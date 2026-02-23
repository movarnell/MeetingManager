import SwiftUI

struct EmptyStateView: View {
    let title: String
    let subtitle: String
    let systemImage: String
    var action: (() -> Void)?
    var actionTitle: String?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 56))
                .foregroundStyle(
                    .linearGradient(
                        colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(title)
                .font(.title2)
                .fontWeight(.semibold)

            Text(subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)

            if let action = action, let actionTitle = actionTitle {
                Button(action: action) {
                    Text(actionTitle)
                        .fontWeight(.medium)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
