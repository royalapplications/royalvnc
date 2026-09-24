#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

public struct VNCRemoteFile: Equatable {
    public let name: String
    public let size: UInt64
    public let modificationTime: UInt32
    public let isDirectory: Bool

    init(_ entry: TightFileTransfer.Entry) {
        name = entry.name
        size = entry.size
        modificationTime = entry.modificationTime
        isDirectory = entry.isDirectory
    }
}

public enum VNCFileTransferEvent {
    case fileList([VNCRemoteFile])
    case downloadData(Data)
    case downloadFinished(modificationTime: UInt32)
    case failed(String)
}
