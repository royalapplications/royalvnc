import Foundation

@_implementationOnly import Z

/// RFB Extended Clipboard messages use a separate, bounded zlib stream per Provide.
/// See https://github.com/rfbproto/rfbproto/blob/master/rfbproto.rst#extended-clipboard-pseudo-encoding
struct ExtendedClipboard {
    static let text: UInt32 = 1
    static let dib: UInt32 = 1 << 3
    static let caps: UInt32 = 1 << 24
    static let request: UInt32 = 1 << 25
    static let peek: UInt32 = 1 << 26
    static let notify: UInt32 = 1 << 27
    static let provide: UInt32 = 1 << 28
    static let actions: UInt32 = caps | request | peek | notify | provide
    static let maximumTextBytes = 1024 * 1024
    static let maximumImageBytes = 8 * 1024 * 1024
    static let maximumPacketBytes = maximumImageBytes + 4096

    let flags: UInt32
    var sizes: [UInt32: UInt32] = [:]
    var textValue: String?
    var imageData: Data?
    var formats: UInt32 { flags & 0xffff }
    var action: UInt32 { flags & 0xff000000 }

    static func textBytes(_ text: String) -> Data? {
        guard !text.contains("\0"), text.utf8.count < maximumTextBytes else { return nil }
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\n", with: "\r\n")
        let bytes = Data(normalized.utf8) + Data([0])
        return bytes.count <= maximumTextBytes ? bytes : nil
    }

    static func decode(_ data: Data) throws -> Self {
        guard data.count >= 4, data.count <= maximumPacketBytes else { throw invalid() }
        var offset = 0
        let flags = try readUInt32(data, offset: &offset)
        var result = Self(flags: flags)
        if flags & caps != 0 {
            for bit in 0..<16 where flags & (1 << bit) != 0 {
                result.sizes[1 << bit] = try readUInt32(data, offset: &offset)
            }
        } else if result.action == provide {
            let plain = try inflate(Data(data.dropFirst(4)))
            var cursor = 0
            for bit in 0..<16 where flags & (1 << bit) != 0 {
                let length = Int(try readUInt32(plain, offset: &cursor))
                guard length <= plain.count - cursor else { throw invalid() }
                let bytes = plain.subdata(in: cursor..<(cursor + length))
                cursor += length
                if bit == 0 {
                    guard length > 0, length <= maximumTextBytes, bytes.last == 0,
                          let text = String(data: bytes.dropLast(), encoding: .utf8),
                          !text.contains("\0") else { throw invalid() }
                    result.textValue = text.replacingOccurrences(of: "\r\n", with: "\n")
                } else if bit == 3 {
                    guard Self.isValidDIBV5(bytes) else { throw invalid() }
                    result.imageData = bytes
                }
            }
            guard cursor == plain.count else { throw invalid() }
            offset = data.count
        } else {
            guard [request, peek, notify].contains(result.action) else { throw invalid() }
        }
        guard offset == data.count else { throw invalid() }
        return result
    }

    func encoded() throws -> Data {
        var result = Data()
        result.append(flags, bigEndian: true)
        if flags & Self.caps != 0 {
            for bit in 0..<16 where flags & (1 << bit) != 0 {
                result.append(sizes[1 << bit] ?? 0, bigEndian: true)
            }
        } else if action == Self.provide {
            let supportedFormats = Self.text | Self.dib
            guard formats != 0, formats & ~supportedFormats == 0 else { throw Self.invalid() }
            var plain = Data()
            for format in [Self.text, Self.dib] where formats & format != 0 {
                let bytes: Data
                if format == Self.text, let textValue, let text = Self.textBytes(textValue) {
                    bytes = text
                } else if format == Self.dib, let imageData, Self.isValidDIBV5(imageData) {
                    bytes = imageData
                } else {
                    throw Self.invalid()
                }
                plain.append(UInt32(bytes.count), bigEndian: true)
                plain.append(bytes)
            }
            result.append(try Self.deflate(plain))
        } else {
            guard [Self.request, Self.peek, Self.notify].contains(action) else { throw Self.invalid() }
        }
        return result
    }

    /// Validates the bounded 32-bit, uncompressed subset used by macOS clipboard
    /// conversion. The RFB format is a BITMAPV5HEADER without a BMP file header.
    static func isValidDIBV5(_ data: Data) -> Bool {
        guard data.count >= 124,
              littleUInt32(data, at: 0) == 124,
              littleUInt16(data, at: 12) == 1,
              littleUInt16(data, at: 14) == 32,
              littleUInt32(data, at: 112) == 0,
              littleUInt32(data, at: 116) == 0 else { return false }
        let width = Int32(bitPattern: littleUInt32(data, at: 4))
        let rawHeight = Int32(bitPattern: littleUInt32(data, at: 8))
        guard width > 0, rawHeight != 0, rawHeight != Int32.min else { return false }
        let compression = littleUInt32(data, at: 16)
        guard compression == 0 || compression == 3 || compression == 6 else { return false }
        let rowBytes = UInt64(width) * 4
        let pixelBytes = rowBytes * UInt64(abs(rawHeight))
        guard pixelBytes <= UInt64(maximumImageBytes),
              data.count == 124 + Int(pixelBytes) else { return false }
        let declaredImageBytes = littleUInt32(data, at: 20)
        guard declaredImageBytes == 0 || UInt64(declaredImageBytes) == pixelBytes else { return false }
        if compression == 3 || compression == 6 {
            let masks = stride(from: 40, through: 52, by: 4).map { littleUInt32(data, at: $0) }
            guard masks[0] != 0, masks[1] != 0, masks[2] != 0,
                  masks.indices.allSatisfy({ index in
                      masks[index] == 0 || masks.indices.allSatisfy { other in
                          other <= index || masks[index] & masks[other] == 0
                      }
                  }),
                  compression != 6 || masks[3] != 0 else { return false }
        }
        return true
    }

    private static func littleUInt16(_ data: Data, at offset: Int) -> UInt16 {
        data.withUnsafeBytes { UInt16(littleEndian: $0.loadUnaligned(fromByteOffset: offset, as: UInt16.self)) }
    }

    private static func littleUInt32(_ data: Data, at offset: Int) -> UInt32 {
        data.withUnsafeBytes { UInt32(littleEndian: $0.loadUnaligned(fromByteOffset: offset, as: UInt32.self)) }
    }

    static func readUInt32(_ data: Data, offset: inout Int) throws -> UInt32 {
        guard offset >= 0, data.count - offset >= 4 else { throw invalid() }
        let value = data.withUnsafeBytes { UInt32(bigEndian: $0.loadUnaligned(fromByteOffset: offset, as: UInt32.self)) }
        offset += 4
        return value
    }

    private static func deflate(_ data: Data) throws -> Data {
        var length = compressBound(uLong(data.count))
        var output = Data(count: Int(length))
        let status = output.withUnsafeMutableBytes { destination in
            data.withUnsafeBytes { source in
                compress2(destination.bindMemory(to: Bytef.self).baseAddress!, &length,
                          source.bindMemory(to: Bytef.self).baseAddress!, uLong(data.count), Z_DEFAULT_COMPRESSION)
            }
        }
        guard status == Z_OK else { throw invalid() }
        output.count = Int(length)
        return output
    }

    private static func inflate(_ data: Data) throws -> Data {
        guard !data.isEmpty else { throw invalid() }
        // Fixed upper bound also limits malicious compressed clipboard payloads.
        var stream = z_stream()
        guard inflateInit_(&stream, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size)) == Z_OK else { throw invalid() }
        defer { inflateEnd(&stream) }
        var output = Data(count: maximumPacketBytes + 64)
        let status = output.withUnsafeMutableBytes { destination in
            data.withUnsafeBytes { source in
                stream.next_in = UnsafeMutablePointer(mutating: source.bindMemory(to: Bytef.self).baseAddress!)
                stream.avail_in = UInt32(data.count)
                stream.next_out = destination.bindMemory(to: Bytef.self).baseAddress!
                stream.avail_out = UInt32(destination.count)
                return Z.inflate(&stream, Z_SYNC_FLUSH)
            }
        }
        // TigerVNC terminates each independent payload with Z_SYNC_FLUSH instead
        // of Z_FINISH. Accept either complete form, never a truncated payload.
        let flushed = status == Z_OK && data.suffix(4) == Data([0, 0, 255, 255])
        guard (status == Z_STREAM_END || flushed), stream.avail_in == 0, stream.avail_out > 0 else { throw invalid() }
        output.count = Int(stream.total_out)
        return output
    }

    private static func invalid() -> VNCError { .protocol(.invalidData) }
}

extension VNCProtocol {
    struct ExtendedClientCutText: VNCSendableMessage {
        let messageType: UInt8 = 6
        let payload: Data
        init(_ message: ExtendedClipboard) throws { payload = try message.encoded() }
        var data: Data {
            var data = Data([messageType, 0, 0, 0])
            data.append(UInt32(bitPattern: -Int32(payload.count)), bigEndian: true)
            data.append(payload)
            return data
        }
        func send(connection: NetworkConnectionWriting) async throws {
            try await connection.write(data: data)
        }
    }
}
