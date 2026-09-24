#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

public extension VNCConnection {
    /// True when the Tight handshake advertised file-list and download messages.
    var canDownloadFiles: Bool { supportsTightFileDownload }

    /// True when the Tight handshake advertised upload request and data messages.
    var canUploadFiles: Bool { supportsTightFileUpload }

    /// True only when both Tight file-transfer directions are available.
    var canTransferFiles: Bool { canDownloadFiles && canUploadFiles }

    func requestFileList(directory: String) throws {
        try enqueueFileTransfer(try TightFileTransfer.fileListRequest(directory: directory), requiresUpload: false)
    }

    func requestFileDownload(path: String, offset: UInt32 = 0) throws {
        try enqueueFileTransfer(try TightFileTransfer.downloadRequest(path: path, offset: offset), requiresUpload: false)
    }

    func requestFileUpload(path: String, offset: UInt32 = 0) throws {
        try enqueueFileTransfer(try TightFileTransfer.uploadRequest(path: path, offset: offset), requiresUpload: true)
    }

    func sendFileUploadData(_ data: Data) throws {
        try enqueueFileTransfer(try TightFileTransfer.uploadData(data), requiresUpload: true)
    }

    func finishFileUpload(modificationTime: UInt32) throws {
        try enqueueFileTransfer(try TightFileTransfer.uploadData(Data(), endModificationTime: modificationTime), requiresUpload: true)
    }

    private func enqueueFileTransfer(_ data: Data, requiresUpload: Bool) throws {
        guard requiresUpload ? canUploadFiles : canDownloadFiles else {
            throw VNCError.protocol(.notImplemented(feature: "TightVNC file transfer"))
        }
        guard connectionState.status == .connected else {
            throw VNCError.connection(.notReady)
        }
        enqueueClientToServerMessage(VNCProtocol.TightFileTransferMessage(data: data))
    }
}
