import SwiftUI

struct OllamaSettingsView: View {
    @State private var settingsVM = SettingsViewModel()

    var body: some View {
        Form {
            Section {
                HStack {
                    TextField("Ollama URL", text: $settingsVM.ollamaURL)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        Task { await settingsVM.checkOllamaConnection() }
                    } label: {
                        if settingsVM.isCheckingOllama {
                            ProgressView()
                                .scaleEffect(0.6)
                        } else {
                            Text("Test")
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(settingsVM.isCheckingOllama)
                }

                HStack(spacing: 8) {
                    Image(systemName: settingsVM.ollamaStatus.iconName)
                        .foregroundStyle(
                            settingsVM.ollamaStatus == .connected ? .green :
                            settingsVM.ollamaStatus == .disconnected ? .red : .secondary
                        )
                    Text("Status: \(settingsVM.ollamaStatus.displayText)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Connection")
            }

            Section {
                Text("Ollama runs locally and processes your meeting transcripts to generate structured notes. Make sure Ollama is installed and running before generating notes.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Link("Download Ollama", destination: URL(string: "https://ollama.com")!)
                    .font(.caption)
            } header: {
                Text("About Ollama")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
