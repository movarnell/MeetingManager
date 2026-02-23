import Foundation

extension Data {
    static func wavHeader(
        sampleRate: Int,
        channels: Int,
        bitsPerSample: Int,
        dataSize: Int
    ) -> Data {
        var header = Data()
        let byteRate = sampleRate * channels * (bitsPerSample / 8)
        let blockAlign = channels * (bitsPerSample / 8)

        // RIFF chunk
        header.append(contentsOf: "RIFF".utf8)
        appendLittleEndian(&header, UInt32(36 + dataSize))
        header.append(contentsOf: "WAVE".utf8)

        // fmt sub-chunk
        header.append(contentsOf: "fmt ".utf8)
        appendLittleEndian(&header, UInt32(16))
        // Audio format: 3 = IEEE Float, 1 = PCM
        let audioFormat: UInt16 = bitsPerSample == 32 ? 3 : 1
        appendLittleEndian(&header, audioFormat)
        appendLittleEndian(&header, UInt16(channels))
        appendLittleEndian(&header, UInt32(sampleRate))
        appendLittleEndian(&header, UInt32(byteRate))
        appendLittleEndian(&header, UInt16(blockAlign))
        appendLittleEndian(&header, UInt16(bitsPerSample))

        // data sub-chunk
        header.append(contentsOf: "data".utf8)
        appendLittleEndian(&header, UInt32(dataSize))

        return header
    }

    private static func appendLittleEndian(_ data: inout Data, _ value: UInt32) {
        var le = value.littleEndian
        Swift.withUnsafeBytes(of: &le) { data.append(contentsOf: $0) }
    }

    private static func appendLittleEndian(_ data: inout Data, _ value: UInt16) {
        var le = value.littleEndian
        Swift.withUnsafeBytes(of: &le) { data.append(contentsOf: $0) }
    }
}
