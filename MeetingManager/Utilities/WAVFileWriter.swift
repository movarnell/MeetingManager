import AVFoundation
import Foundation

final class WAVFileWriter {
    private let fileURL: URL
    private var audioFile: AVAudioFile?
    private let format: AVAudioFormat

    init(outputURL: URL, sampleRate: Double, channels: UInt32 = 1) throws {
        self.fileURL = outputURL
        self.format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: channels,
            interleaved: false
        )!

        self.audioFile = try AVAudioFile(
            forWriting: outputURL,
            settings: format.settings,
            commonFormat: .pcmFormatFloat32,
            interleaved: false
        )
    }

    func write(buffer: AVAudioPCMBuffer) throws {
        try audioFile?.write(from: buffer)
    }

    func close() {
        audioFile = nil
    }

    var outputFormat: AVAudioFormat { format }
}
