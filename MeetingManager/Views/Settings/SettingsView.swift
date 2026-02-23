import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            OllamaSettingsView()
                .tabItem {
                    Label("Ollama", systemImage: "brain")
                }

            WhisperSettingsView()
                .tabItem {
                    Label("Transcription", systemImage: "waveform")
                }

            StorageSettingsView()
                .tabItem {
                    Label("Storage", systemImage: "folder")
                }
        }
        .frame(width: 480, height: 320)
    }
}
