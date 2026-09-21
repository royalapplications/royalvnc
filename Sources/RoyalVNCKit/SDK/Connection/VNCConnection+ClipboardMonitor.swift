#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif
import Dispatch

extension VNCConnection {
    func startMonitoringClipboard() {
        guard settings.isClipboardRedirectionEnabled else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            serverClipboardCapabilities = nil
            pendingClipboardText = nil
            clipboardMonitor.startMonitoring()
        }
    }

    func stopMonitoringClipboard() {
        guard settings.isClipboardRedirectionEnabled else { return }
        clipboardMonitor.stopMonitoring()
    }

    var maySendClipboard: Bool {
        settings.isClipboardRedirectionEnabled && connectionState.status == .connected
    }

    func handleClipboardMessage(_ message: VNCProtocol.ServerCutText) {
        guard settings.isClipboardRedirectionEnabled, connectionState.status == .connected else { return }
        if let extended = message.extended {
            if extended.flags & ExtendedClipboard.caps != 0 {
                serverClipboardCapabilities = extended
                enqueueClipboard(ExtendedClipboard(flags: ExtendedClipboard.actions | ExtendedClipboard.text,
                                                   sizes: [ExtendedClipboard.text: 0]))
                // A previous legacy attempt might have rejected non-Latin-1 text.
                clipboardMonitor.requestCurrentChange()
            } else if extended.action == ExtendedClipboard.request {
                guard maySendClipboard, extended.formats & ExtendedClipboard.text != 0,
                      let text = pendingClipboardText ?? clipboard.text else { return }
                enqueueClipboard(ExtendedClipboard(flags: ExtendedClipboard.provide | ExtendedClipboard.text, textValue: text))
            } else if extended.action == ExtendedClipboard.peek {
                guard maySendClipboard else { return }
                let available: UInt32 = clipboard.text == nil ? 0 : ExtendedClipboard.text
                enqueueClipboard(ExtendedClipboard(flags: ExtendedClipboard.notify | available))
            } else if extended.action == ExtendedClipboard.notify {
                guard extended.formats & ExtendedClipboard.text != 0,
                      (serverClipboardCapabilities?.flags ?? 0) & ExtendedClipboard.request != 0 else { return }
                enqueueClipboard(ExtendedClipboard(flags: ExtendedClipboard.request | ExtendedClipboard.text))
            }
        }
        guard let text = message.text else { return }
        pendingClipboardText = nil
        clipboard.text = text
        // Receiving text must not echo it back on the next monitor tick.
        clipboardMonitor.acknowledgeCurrentChange()
    }

    @discardableResult
    func enqueueClipboard(_ message: ExtendedClipboard) -> Bool {
        guard let encoded = try? VNCProtocol.ExtendedClientCutText(message) else { return false }
        enqueueClientToServerMessage(encoded)
        return true
    }

    @discardableResult
    func sendClipboardOnMainQueue(_ text: String) -> Bool {
        guard maySendClipboard, let bytes = ExtendedClipboard.textBytes(text) else { return false }
        if let caps = serverClipboardCapabilities, caps.formats & ExtendedClipboard.text != 0 {
            pendingClipboardText = text
            if caps.flags & ExtendedClipboard.notify != 0 {
                return enqueueClipboard(ExtendedClipboard(flags: ExtendedClipboard.notify | ExtendedClipboard.text))
            }
            if caps.flags & ExtendedClipboard.provide != 0,
               UInt32(bytes.count) <= (caps.sizes[ExtendedClipboard.text] ?? 0) {
                return enqueueClipboard(ExtendedClipboard(flags: ExtendedClipboard.provide | ExtendedClipboard.text, textValue: text))
            }
            return false
        }
        // Never replace the remote clipboard with empty text after a failed encoding conversion.
        guard text.data(using: .isoLatin1) != nil else { return false }
        enqueueClientCutTextMessage(text)
        return true
    }
}

extension VNCConnection: VNCClipboardMonitorDelegate {
    func clipboardMonitorShouldMonitor(_ clipboardMonitor: VNCClipboardMonitor) -> Bool { maySendClipboard }
    func clipboardMonitor(_ clipboardMonitor: VNCClipboardMonitor, didChangeText text: String) {
        sendClipboardOnMainQueue(text)
    }
}
