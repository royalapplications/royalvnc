#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

/// Optional clipboard policy for applications managing more than one connection.
/// All callbacks run on the main queue. Without a delegate the connection retains
/// automatic synchronization with the system clipboard.
public protocol VNCClipboardDelegate: AnyObject {
    /// Return false to suspend outgoing clipboard synchronization for this connection.
    func connectionShouldSendClipboard(_ connection: VNCConnection) -> Bool

    /// Return false to reject remote text and remote clipboard notifications.
    func connectionShouldReceiveClipboard(_ connection: VNCConnection) -> Bool

    /// A delegate owns delivery of incoming text, including any system clipboard write.
    /// Inactive connections may ignore this callback to keep their clipboards isolated.
    func connection(_ connection: VNCConnection, didReceiveClipboardText text: String)

    /// Return false to suspend outgoing image synchronization for this connection.
    func connectionShouldSendClipboardImage(_ connection: VNCConnection) -> Bool

    /// A delegate owns delivery of received DIB V5 image data to its platform clipboard.
    func connection(_ connection: VNCConnection, didReceiveClipboardImageData imageData: Data)
}

public extension VNCClipboardDelegate {
    func connectionShouldReceiveClipboard(_ connection: VNCConnection) -> Bool {
        connectionShouldSendClipboard(connection)
    }

    func connectionShouldSendClipboardImage(_ connection: VNCConnection) -> Bool {
        connectionShouldSendClipboard(connection)
    }

    func connection(_ connection: VNCConnection, didReceiveClipboardImageData imageData: Data) {}
}
