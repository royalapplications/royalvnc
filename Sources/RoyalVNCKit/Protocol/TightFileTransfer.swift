#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Wire codecs for the TightVNC file-transfer extension. These messages are
/// separate from Extended Clipboard and are used only after Tight advertises
/// the corresponding capabilities.
enum TightFileTransfer {
    static let maximumPathBytes = 4096
    static let maximumListingBytes = 65_535
    static let maximumChunkBytes = 65_535

    struct Entry: Equatable {
        let name: String
        let size: UInt64
        let modificationTime: UInt32
        let isDirectory: Bool
    }

    struct FileChunk: Equatable {
        let data: Data
        let modificationTime: UInt32?
        var isEnd: Bool { data.isEmpty && modificationTime != nil }
    }

    /// Decode the body following server message type 130.
    static func decodeFileList(_ body: Data) throws -> [Entry] {
        guard body.count >= 7 else { throw invalid() }
        let flags = body[0]
        let count = Int(try u16(body, 1))
        let namesLength = Int(try u16(body, 3))
        let compressedLength = Int(try u16(body, 5))
        guard flags & 0x80 == 0,
              namesLength <= maximumListingBytes,
              compressedLength <= maximumListingBytes,
              count <= maximumListingBytes / 8,
              body.count == 7 + count * 8 + compressedLength else { throw invalid() }

        let metadataStart = 7
        let namesStart = metadataStart + count * 8
        let compressedNames = body.subdata(in: namesStart..<body.count)
        let names: Data
        if compressedLength == namesLength {
            names = compressedNames
        } else {
            let stream = ZlibStream()
            names = try stream.decompressedData(compressedData: compressedNames,
                                                uncompressedSize: UInt(namesLength))
        }
        guard names.count == namesLength else { throw invalid() }

        var result: [Entry] = []
        result.reserveCapacity(count)
        var nameOffset = 0
        for index in 0..<count {
            let metadataOffset = metadataStart + index * 8
            let rawSize = try u32(body, metadataOffset)
            let mtime = try u32(body, metadataOffset + 4)
            guard let terminator = names[nameOffset...].firstIndex(of: 0), terminator > nameOffset,
                  let name = String(data: names[nameOffset..<terminator], encoding: .utf8),
                  name != ".", name != "..",
                  !name.contains("/"), !name.contains("\\"),
                  !name.unicodeScalars.contains(where: { $0.value < 0x20 || $0.value == 0x7f }) else {
                throw invalid()
            }
            let isDirectory = rawSize == UInt32.max
            result.append(Entry(name: name,
                                size: isDirectory ? 0 : UInt64(rawSize),
                                modificationTime: mtime,
                                isDirectory: isDirectory))
            nameOffset = terminator + 1
        }
        guard nameOffset == names.count else { throw invalid() }
        return result
    }

    /// Decode the body following server message type 131. A zero-length final
    /// block carries the file modification time as a trailing U32.
    static func decodeDownloadChunk(_ body: Data) throws -> FileChunk {
        guard body.count >= 5 else { throw invalid() }
        let realLength = Int(try u16(body, 1))
        let compressedLength = Int(try u16(body, 3))
        guard realLength <= maximumChunkBytes,
              compressedLength <= maximumChunkBytes else { throw invalid() }
        if realLength == 0 || compressedLength == 0 {
            guard realLength == 0, compressedLength == 0, body.count == 9 else { throw invalid() }
            return FileChunk(data: Data(), modificationTime: try u32(body, 5))
        }
        guard body.count == 5 + compressedLength else { throw invalid() }
        let payload = body.subdata(in: 5..<body.count)
        let data: Data
        if realLength == compressedLength {
            data = payload
        } else {
            let stream = ZlibStream()
            data = try stream.decompressedData(compressedData: payload, uncompressedSize: UInt(realLength))
        }
        guard data.count == realLength else { throw invalid() }
        return FileChunk(data: data, modificationTime: nil)
    }

    static func fileListRequest(directory: String) throws -> Data {
        try pathRequest(type: 130, flags: 0, path: directory)
    }

    static func downloadRequest(path: String, offset: UInt32 = 0) throws -> Data {
        let bytes = try pathBytes(path)
        var packet = Data([131, 0]) // type, zlib level (uncompressed)
        packet.append(UInt16(bytes.count), bigEndian: true)
        packet.append(offset, bigEndian: true)
        packet.append(bytes)
        return packet
    }

    static func uploadRequest(path: String, offset: UInt32 = 0) throws -> Data {
        let bytes = try pathBytes(path)
        var packet = Data([132, 0])
        packet.append(UInt16(bytes.count), bigEndian: true)
        packet.append(offset, bigEndian: true)
        packet.append(bytes)
        return packet
    }

    static func uploadData(_ data: Data, endModificationTime: UInt32? = nil) throws -> Data {
        guard data.count <= maximumChunkBytes else { throw invalid() }
        var packet = Data([133, 0]) // type, zlib level (uncompressed)
        if let endModificationTime {
            guard data.isEmpty else { throw invalid() }
            packet.append(UInt16(0), bigEndian: true)
            packet.append(UInt16(0), bigEndian: true)
            packet.append(endModificationTime, bigEndian: true)
        } else {
            guard !data.isEmpty else { throw invalid() }
            packet.append(UInt16(data.count), bigEndian: true)
            packet.append(UInt16(data.count), bigEndian: true)
            packet.append(data)
        }
        return packet
    }

    private static func pathRequest(type: UInt8, flags: UInt8, path: String) throws -> Data {
        let bytes = try pathBytes(path)
        var packet = Data([type, flags])
        packet.append(UInt16(bytes.count), bigEndian: true)
        packet.append(bytes)
        return packet
    }

    private static func pathBytes(_ path: String) throws -> Data {
        guard !path.isEmpty, !path.utf8.contains(0),
              path.utf8.count <= maximumPathBytes,
              let data = path.data(using: .utf8) else { throw invalid() }
        return data
    }

    private static func u16(_ data: Data, _ offset: Int) throws -> UInt16 {
        guard offset >= 0, data.count - offset >= 2 else { throw invalid() }
        return data.withUnsafeBytes { UInt16(bigEndian: $0.loadUnaligned(fromByteOffset: offset, as: UInt16.self)) }
    }

    private static func u32(_ data: Data, _ offset: Int) throws -> UInt32 {
        guard offset >= 0, data.count - offset >= 4 else { throw invalid() }
        return data.withUnsafeBytes { UInt32(bigEndian: $0.loadUnaligned(fromByteOffset: offset, as: UInt32.self)) }
    }

    private static func invalid() -> VNCError { .protocol(.invalidData) }
}
