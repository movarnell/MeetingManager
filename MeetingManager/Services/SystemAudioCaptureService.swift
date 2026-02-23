import ScreenCaptureKit
import AVFoundation
import Observation

@Observable
final class SystemAudioCaptureService: NSObject, @unchecked Sendable {
    private var stream: SCStream?
    private var audioFile: AVAudioFile?
    private let audioQueue = DispatchQueue(label: "com.meetingmanager.systemaudio", qos: .userInitiated)
    private(set) var isCapturing = false
    private(set) var currentLevel: Float = 0
    private(set) var hasPermission = false

    func checkPermission() async -> Bool {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(
                false, onScreenWindowsOnly: false
            )
            hasPermission = !content.displays.isEmpty
            return hasPermission
        } catch {
            hasPermission = false
            return false
        }
    }

    func startCapture(outputURL: URL) async throws {
        let content = try await SCShareableContent.excludingDesktopWindows(
            false, onScreenWindowsOnly: false
        )

        guard let display = content.displays.first else {
            throw CaptureError.noDisplay
        }

        let filter = SCContentFilter(display: display, excludingWindows: [])

        let config = SCStreamConfiguration()
        config.capturesAudio = true
        config.sampleRate = 48000
        config.channelCount = 2
        config.excludesCurrentProcessAudio = true

        // Minimize video overhead - we only want audio
        config.width = 2
        config.height = 2
        config.minimumFrameInterval = CMTime(value: 1, timescale: 1)

        let outputFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 48000,
            channels: 2,
            interleaved: false
        )!

        audioFile = try AVAudioFile(
            forWriting: outputURL,
            settings: outputFormat.settings,
            commonFormat: .pcmFormatFloat32,
            interleaved: false
        )

        let captureStream = SCStream(filter: filter, configuration: config, delegate: self)
        try captureStream.addStreamOutput(self, type: .audio, sampleHandlerQueue: audioQueue)
        try await captureStream.startCapture()
        self.stream = captureStream
        isCapturing = true
    }

    func stopCapture() async {
        if let stream = stream {
            try? await stream.stopCapture()
        }
        stream = nil
        audioFile = nil
        isCapturing = false
        currentLevel = 0
    }

    enum CaptureError: Error, LocalizedError {
        case noDisplay
        case permissionDenied

        var errorDescription: String? {
            switch self {
            case .noDisplay: return "No display found for audio capture"
            case .permissionDenied: return "Screen Recording permission denied"
            }
        }
    }
}

extension SystemAudioCaptureService: SCStreamDelegate {
    nonisolated func stream(_ stream: SCStream, didStopWithError error: Error) {
        Task { @MainActor in
            self.isCapturing = false
            self.currentLevel = 0
        }
    }
}

extension SystemAudioCaptureService: SCStreamOutput {
    nonisolated func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .audio else { return }
        guard let pcmBuffer = sampleBuffer.toPCMBuffer() else { return }

        try? self.audioFile?.write(from: pcmBuffer)

        let level = pcmBuffer.normalizedLevel
        Task { @MainActor in
            self.currentLevel = level
        }
    }
}
