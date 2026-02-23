import AVFoundation
import Observation

@Observable
final class MicrophoneCaptureService {
    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private(set) var isCapturing = false
    private(set) var currentLevel: Float = 0
    private(set) var hasPermission = false

    func checkPermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            hasPermission = true
            return true
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .audio)
            hasPermission = granted
            return granted
        default:
            hasPermission = false
            return false
        }
    }

    func startCapture(outputURL: URL) throws {
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        guard inputFormat.sampleRate > 0 else {
            throw CaptureError.noInputDevice
        }

        audioFile = try AVAudioFile(
            forWriting: outputURL,
            settings: inputFormat.settings,
            commonFormat: .pcmFormatFloat32,
            interleaved: false
        )

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
            guard let self = self else { return }
            try? self.audioFile?.write(from: buffer)
            let level = buffer.normalizedLevel
            Task { @MainActor in
                self.currentLevel = level
            }
        }

        engine.prepare()
        try engine.start()
        self.audioEngine = engine
        isCapturing = true
    }

    func stopCapture() {
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        audioFile = nil
        isCapturing = false
        currentLevel = 0
    }

    enum CaptureError: Error, LocalizedError {
        case noInputDevice
        case permissionDenied

        var errorDescription: String? {
            switch self {
            case .noInputDevice: return "No audio input device found"
            case .permissionDenied: return "Microphone access denied"
            }
        }
    }
}
