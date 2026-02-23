import Foundation
import Observation

@Observable
@MainActor
final class AudioRecordingService {
    let micService = MicrophoneCaptureService()
    let systemService = SystemAudioCaptureService()

    private(set) var state: RecordingState = .idle
    private(set) var duration: TimeInterval = 0
    private var timer: Timer?
    private var startTime: Date?
    private var autoSaveTimer: Timer?
    private var currentMeetingId: UUID?

    var micEnabled = true
    var systemAudioEnabled = true

    var micLevel: Float { micService.currentLevel }
    var systemLevel: Float { systemService.currentLevel }

    func startRecording(meetingId: UUID) async throws {
        currentMeetingId = meetingId
        let dir = StorageService.shared.meetingDirectory(for: meetingId)
        try StorageService.shared.ensureDirectoryExists(at: dir)

        if micEnabled {
            let granted = await micService.checkPermission()
            if !granted {
                throw RecordingError.micPermissionDenied
            }
            let micURL = StorageService.shared.audioFileURL(for: meetingId, type: .microphone)
            try micService.startCapture(outputURL: micURL)
        }

        if systemAudioEnabled {
            let granted = await systemService.checkPermission()
            if !granted {
                throw RecordingError.screenRecordingPermissionDenied
            }
            let sysURL = StorageService.shared.audioFileURL(for: meetingId, type: .systemAudio)
            try await systemService.startCapture(outputURL: sysURL)
        }

        startTime = Date()
        state = .recording
        startTimer()
    }

    func stopRecording() async -> TimeInterval {
        state = .stopping

        if micService.isCapturing {
            micService.stopCapture()
        }
        if systemService.isCapturing {
            await systemService.stopCapture()
        }

        stopTimer()
        let finalDuration = duration
        state = .idle
        duration = 0
        currentMeetingId = nil
        return finalDuration
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: AppConstants.Recording.timerUpdateInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let start = self.startTime else { return }
                self.duration = Date().timeIntervalSince(start)
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
    }

    enum RecordingError: Error, LocalizedError {
        case micPermissionDenied
        case screenRecordingPermissionDenied
        case noAudioSourceEnabled

        var errorDescription: String? {
            switch self {
            case .micPermissionDenied:
                return "Microphone permission is required. Please grant access in System Settings > Privacy & Security > Microphone."
            case .screenRecordingPermissionDenied:
                return "Screen Recording permission is required for system audio. Please grant access in System Settings > Privacy & Security > Screen Recording."
            case .noAudioSourceEnabled:
                return "At least one audio source must be enabled."
            }
        }
    }
}
