import AVFoundation

extension AVAudioPCMBuffer {
    var rmsLevel: Float {
        guard let channelData = floatChannelData?[0] else { return 0 }
        let count = Int(frameLength)
        guard count > 0 else { return 0 }

        var sum: Float = 0
        for i in 0..<count {
            let sample = channelData[i]
            sum += sample * sample
        }
        let rms = sqrt(sum / Float(count))
        return rms
    }

    var normalizedLevel: Float {
        let rms = rmsLevel
        guard rms > 0 else { return 0 }
        let db = 20 * log10(max(rms, 1e-7))
        let normalized = max(0, min(1, (db + 60) / 60))
        return normalized
    }

    func resample(to targetFormat: AVAudioFormat) -> AVAudioPCMBuffer? {
        guard let converter = AVAudioConverter(from: format, to: targetFormat) else {
            return nil
        }

        let ratio = targetFormat.sampleRate / format.sampleRate
        let outputFrameCount = AVAudioFrameCount(Double(frameLength) * ratio)

        guard let outputBuffer = AVAudioPCMBuffer(
            pcmFormat: targetFormat,
            frameCapacity: outputFrameCount
        ) else { return nil }

        var error: NSError?
        var inputConsumed = false

        converter.convert(to: outputBuffer, error: &error) { _, outStatus in
            if inputConsumed {
                outStatus.pointee = .noDataNow
                return nil
            }
            outStatus.pointee = .haveData
            inputConsumed = true
            return self
        }

        if let error = error {
            print("Resample error: \(error)")
            return nil
        }

        return outputBuffer
    }
}
