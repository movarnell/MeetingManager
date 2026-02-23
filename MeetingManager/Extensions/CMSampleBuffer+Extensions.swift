import AVFoundation
import CoreMedia

extension CMSampleBuffer {
    func toPCMBuffer() -> AVAudioPCMBuffer? {
        guard let formatDescription = formatDescription else { return nil }

        let mediaType = CMFormatDescriptionGetMediaType(formatDescription)
        guard mediaType == kCMMediaType_Audio else { return nil }

        let asbdPointer = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription)
        guard let asbd = asbdPointer else { return nil }

        guard let audioFormat = AVAudioFormat(streamDescription: asbd) else {
            return nil
        }

        let numFrames = CMSampleBufferGetNumSamples(self)
        guard numFrames > 0 else { return nil }

        guard let pcmBuffer = AVAudioPCMBuffer(
            pcmFormat: audioFormat,
            frameCapacity: AVAudioFrameCount(numFrames)
        ) else { return nil }

        pcmBuffer.frameLength = AVAudioFrameCount(numFrames)

        guard let blockBuffer = CMSampleBufferGetDataBuffer(self) else { return nil }

        var lengthAtOffset: Int = 0
        var totalLength: Int = 0
        var dataPointer: UnsafeMutablePointer<Int8>?

        let status = CMBlockBufferGetDataPointer(
            blockBuffer,
            atOffset: 0,
            lengthAtOffsetOut: &lengthAtOffset,
            totalLengthOut: &totalLength,
            dataPointerOut: &dataPointer
        )

        guard status == kCMBlockBufferNoErr, let srcData = dataPointer else { return nil }

        if let dest = pcmBuffer.floatChannelData?[0] {
            let bytesToCopy = min(totalLength, Int(pcmBuffer.frameLength) * Int(audioFormat.channelCount) * MemoryLayout<Float>.size)
            memcpy(dest, srcData, bytesToCopy)
        } else if let dest = pcmBuffer.int16ChannelData?[0] {
            let bytesToCopy = min(totalLength, Int(pcmBuffer.frameLength) * Int(audioFormat.channelCount) * MemoryLayout<Int16>.size)
            memcpy(dest, srcData, bytesToCopy)
        }

        return pcmBuffer
    }
}
