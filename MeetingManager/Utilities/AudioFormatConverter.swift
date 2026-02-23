import AVFoundation

final class AudioFormatConverter {
    static func convert(
        inputURL: URL,
        outputURL: URL,
        targetSampleRate: Double = 16000,
        targetChannels: UInt32 = 1
    ) async throws {
        let inputFile = try AVAudioFile(forReading: inputURL)
        let inputFormat = inputFile.processingFormat

        let outputFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: targetSampleRate,
            channels: targetChannels,
            interleaved: false
        )!

        let outputFile = try AVAudioFile(
            forWriting: outputURL,
            settings: outputFormat.settings,
            commonFormat: .pcmFormatFloat32,
            interleaved: false
        )

        guard let converter = AVAudioConverter(from: inputFormat, to: outputFormat) else {
            throw ConversionError.converterCreationFailed
        }

        let bufferSize: AVAudioFrameCount = 4096
        let inputBuffer = AVAudioPCMBuffer(pcmFormat: inputFormat, frameCapacity: bufferSize)!

        let ratio = targetSampleRate / inputFormat.sampleRate
        let outputBufferSize = AVAudioFrameCount(Double(bufferSize) * ratio) + 1
        let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: outputBufferSize)!

        while true {
            do {
                try inputFile.read(into: inputBuffer)
            } catch {
                break
            }

            if inputBuffer.frameLength == 0 { break }

            var error: NSError?
            var inputConsumed = false

            let capturedBuffer = inputBuffer
            converter.convert(to: outputBuffer, error: &error) { _, outStatus in
                if inputConsumed {
                    outStatus.pointee = .noDataNow
                    return nil
                }
                outStatus.pointee = .haveData
                inputConsumed = true
                return capturedBuffer
            }

            if let error = error {
                throw ConversionError.conversionFailed(error)
            }

            if outputBuffer.frameLength > 0 {
                try outputFile.write(from: outputBuffer)
            }
        }
    }

    enum ConversionError: Error, LocalizedError {
        case converterCreationFailed
        case conversionFailed(NSError)

        var errorDescription: String? {
            switch self {
            case .converterCreationFailed:
                return "Failed to create audio converter"
            case .conversionFailed(let error):
                return "Audio conversion failed: \(error.localizedDescription)"
            }
        }
    }
}
