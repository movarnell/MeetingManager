import Foundation

enum RecordingState: Equatable {
    case idle
    case recording
    case paused
    case stopping
    case processing

    var isActive: Bool {
        switch self {
        case .recording, .paused:
            return true
        default:
            return false
        }
    }

    var displayText: String {
        switch self {
        case .idle: return "Ready to Record"
        case .recording: return "Recording"
        case .paused: return "Paused"
        case .stopping: return "Stopping..."
        case .processing: return "Processing..."
        }
    }
}
