import Foundation
import Observation

@Observable
@MainActor
final class SettingsViewModel {
    var ollamaURL: String = AppConstants.Ollama.defaultBaseURL.absoluteString
    var isCheckingOllama: Bool = false
    var ollamaStatus: ConnectionStatus = .unknown

    var whisperModelName: String = "auto"
    var isLoadingModel: Bool = false
    var whisperStatus: String = "Not loaded"

    enum ConnectionStatus {
        case unknown
        case connected
        case disconnected

        var displayText: String {
            switch self {
            case .unknown: return "Not checked"
            case .connected: return "Connected"
            case .disconnected: return "Disconnected"
            }
        }

        var iconName: String {
            switch self {
            case .unknown: return "questionmark.circle"
            case .connected: return "checkmark.circle.fill"
            case .disconnected: return "xmark.circle.fill"
            }
        }
    }

    func checkOllamaConnection() async {
        isCheckingOllama = true
        defer { isCheckingOllama = false }

        guard let url = URL(string: ollamaURL) else {
            ollamaStatus = .disconnected
            return
        }

        do {
            let tagURL = url.appendingPathComponent("api/tags")
            var request = URLRequest(url: tagURL)
            request.timeoutInterval = 5
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                ollamaStatus = .connected
            } else {
                ollamaStatus = .disconnected
            }
        } catch {
            ollamaStatus = .disconnected
        }
    }
}
