import SwiftUI

struct WhisperSettingsView: View {
    @State private var selectedModel = "auto"
    @State private var isLoading = false
    @State private var status = "Not loaded"

    private let modelOptions = [
        ("auto", "Auto (Recommended)", "Best model for your hardware"),
        ("tiny", "Tiny", "Fastest, least accurate (~75MB)"),
        ("base", "Base", "Fast, moderate accuracy (~142MB)"),
        ("small", "Small", "Good balance (~466MB)"),
        ("medium", "Medium", "High accuracy (~1.5GB)"),
        ("large-v3", "Large v3", "Best accuracy (~3GB)")
    ]

    var body: some View {
        Form {
            Section {
                Picker("Model", selection: $selectedModel) {
                    ForEach(modelOptions, id: \.0) { model in
                        VStack(alignment: .leading) {
                            Text(model.1)
                        }
                        .tag(model.0)
                    }
                }

                if let info = modelOptions.first(where: { $0.0 == selectedModel }) {
                    Text(info.2)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Whisper Model")
            }

            Section {
                Text("WhisperKit runs OpenAI's Whisper model locally on your Mac using Apple's Neural Engine for fast, private transcription. The model is downloaded on first use.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Auto mode selects the best model for your Mac's capabilities.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("About WhisperKit")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
