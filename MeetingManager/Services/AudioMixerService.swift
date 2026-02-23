import AVFoundation

final class AudioMixerService {
    static func mixAudioFiles(
        micFileURL: URL?,
        systemFileURL: URL?,
        outputURL: URL,
        targetSampleRate: Double = 16000
    ) async throws {
        let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: targetSampleRate,
            channels: 1,
            interleaved: false
        )!

        // If only one source exists, just convert it
        if let micURL = micFileURL, systemFileURL == nil {
            try await AudioFormatConverter.convert(
                inputURL: micURL,
                outputURL: outputURL,
                targetSampleRate: targetSampleRate,
                targetChannels: 1
            )
            return
        }

        if let sysURL = systemFileURL, micFileURL == nil {
            try await AudioFormatConverter.convert(
                inputURL: sysURL,
                outputURL: outputURL,
                targetSampleRate: targetSampleRate,
                targetChannels: 1
            )
            return
        }

        // Mix both sources
        guard let micURL = micFileURL, let sysURL = systemFileURL else {
            throw MixError.noInputFiles
        }

        let micFile = try AVAudioFile(forReading: micURL)
        let sysFile = try AVAudioFile(forReading: sysURL)

        // Create converters to target format
        guard let micConverter = AVAudioConverter(from: micFile.processingFormat, to: targetFormat),
              let sysConverter = AVAudioConverter(from: sysFile.processingFormat, to: targetFormat)
        else {
            throw MixError.converterCreationFailed
        }

        let outputFile = try AVAudioFile(
            forWriting: outputURL,
            settings: targetFormat.settings,
            commonFormat: .pcmFormatFloat32,
            interleaved: false
        )

        let bufferSize: AVAudioFrameCount = 4096

        let micInputBuffer = AVAudioPCMBuffer(pcmFormat: micFile.processingFormat, frameCapacity: bufferSize)!
        let sysInputBuffer = AVAudioPCMBuffer(pcmFormat: sysFile.processingFormat, frameCapacity: bufferSize)!

        let ratio = targetSampleRate / max(micFile.processingFormat.sampleRate, sysFile.processingFormat.sampleRate)
        let outputBufferSize = AVAudioFrameCount(Double(bufferSize) * ratio) + 256
        let micOutputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: outputBufferSize)!
        let sysOutputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: outputBufferSize)!
        let mixBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: outputBufferSize)!

        while true {
            var micFrames: AVAudioFrameCount = 0
            var sysFrames: AVAudioFrameCount = 0

            // Read and convert mic audio
            do {
                try micFile.read(into: micInputBuffer)
                if micInputBuffer.frameLength > 0 {
                    var error: NSError?
                    var consumed = false
                    let captured = micInputBuffer
                    micConverter.convert(to: micOutputBuffer, error: &error) { _, outStatus in
                        if consumed { outStatus.pointee = .noDataNow; return nil }
                        outStatus.pointee = .haveData
                        consumed = true
                        return captured
                    }
                    micFrames = micOutputBuffer.frameLength
                }
            } catch { }

            // Read and convert system audio
            do {
                try sysFile.read(into: sysInputBuffer)
                if sysInputBuffer.frameLength > 0 {
                    var error: NSError?
                    var consumed = false
                    let captured = sysInputBuffer
                    sysConverter.convert(to: sysOutputBuffer, error: &error) { _, outStatus in
                        if consumed { outStatus.pointee = .noDataNow; return nil }
                        outStatus.pointee = .haveData
                        consumed = true
                        return captured
                    }
                    sysFrames = sysOutputBuffer.frameLength
                }
            } catch { }

            if micFrames == 0 && sysFrames == 0 { break }

            // Mix the two buffers
            let frameCount = max(micFrames, sysFrames)
            mixBuffer.frameLength = frameCount

            guard let mixData = mixBuffer.floatChannelData?[0],
                  let micData = micOutputBuffer.floatChannelData?[0],
                  let sysData = sysOutputBuffer.floatChannelData?[0]
            else { break }

            for i in 0..<Int(frameCount) {
                let micSample: Float = i < Int(micFrames) ? micData[i] : 0
                let sysSample: Float = i < Int(sysFrames) ? sysData[i] : 0
                // Average mix with headroom
                mixData[i] = (micSample + sysSample) * 0.5
            }

            try outputFile.write(from: mixBuffer)
        }
    }

    enum MixError: Error, LocalizedError {
        case noInputFiles
        case converterCreationFailed

        var errorDescription: String? {
            switch self {
            case .noInputFiles: return "No audio files to mix"
            case .converterCreationFailed: return "Failed to create audio format converter"
            }
        }
    }
}
