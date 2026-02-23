import Foundation

enum AudioSource: String, CaseIterable, Identifiable, Codable {
    case microphone
    case systemAudio
    case both

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .microphone: return "Microphone"
        case .systemAudio: return "System Audio"
        case .both: return "Both"
        }
    }

    var iconName: String {
        switch self {
        case .microphone: return "mic.fill"
        case .systemAudio: return "speaker.wave.2.fill"
        case .both: return "speaker.wave.2.circle.fill"
        }
    }
}
