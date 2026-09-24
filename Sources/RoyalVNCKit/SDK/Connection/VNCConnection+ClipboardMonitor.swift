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
        settings.isClipboardRedirectionEnabled && connectionState.status == .connected &&
            (clipboardDelegate?.connectionShouldSendClipboard(self) ?? true)
    }

    func handleClipboardMessage(_ message: VNCProtocol.ServerCutText) {
        guard settings.isClipboardRedirectionEnabled, connectionState.status == .connected else { return }
        if let extended = message.extended {
            if extended.flags & ExtendedClipboard.caps != 0 {
                serverClipboardCapabilities = extended
                let formats = ExtendedClipboard.text | ExtendedClipboard.dib
                enqueueClipboard(ExtendedClipboard(flags: ExtendedClipboard.actions | formats,
                                                   sizes: [ExtendedClipboard.text: 0, ExtendedClipboard.dib: 0]))
                // A previous legacy attempt might have rejected non-Latin-1 text.
                clipboardMonitor.requestCurrentChange()
            } else if extended.action == ExtendedClipboard.request {
                guard maySendClipboard else { return }
                if extended.formats & ExtendedClipboard.dib != 0,
                   let image = pendingClipboardImage ?? clipboard.imageData,
                   ExtendedClipboard.isValidDIBV5(image) {
                    enqueueClipboard(ExtendedClipboard(flags: ExtendedClipboard.provide | ExtendedClipboard.dib,
                                                       imageData: image))
                } else if extended.formats & ExtendedClipboard.text != 0,
                          let text = pendingClipboardText ?? clipboard.text {
                    enqueueClipboard(ExtendedClipboard(flags: ExtendedClipboard.provide | ExtendedClipboard.text,
                                                       textValue: text))
                }
            } else if extended.action == ExtendedClipboard.peek {
                guard maySendClipboard else { return }
                var available: UInt32 = clipboard.text == nil ? 0 : ExtendedClipboard.text
                if clipboard.imageData != nil { available |= ExtendedClipboard.dib }
                enqueueClipboard(ExtendedClipboard(flags: ExtendedClipboard.notify | available))
            } else if extended.action == ExtendedClipboard.notify {
                guard clipboardDelegate?.connectionShouldReceiveClipboard(self) ?? true,
                      extended.formats & (ExtendedClipboard.text | ExtendedClipboard.dib) != 0,
                      (serverClipboardCapabilities?.flags ?? 0) & ExtendedClipboard.request != 0 else { return }
                let selectedFormat = extended.formats & ExtendedClipboard.dib != 0
                    ? ExtendedClipboard.dib : ExtendedClipboard.text
                enqueueClipboard(ExtendedClipboard(flags: ExtendedClipboard.request | selectedFormat))
            }
        }
        guard clipboardDelegate?.connectionShouldReceiveClipboard(self) ?? true else { return }
        if let image = message.extended?.imageData {
            if let clipboardDelegate {
                clipboardDelegate.connection(self, didReceiveClipboardImageData: image)
            } else {
                clipboard.imageData = image
            }
        } else if let text = message.text {
            if let clipboardDelegate {
                clipboardDelegate.connection(self, didReceiveClipboardText: text)
            } else {
                clipboard.text = text
            }
        }
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

    @discardableResult
    func sendClipboardImageOnMainQueue(_ imageData: Data) -> Bool {
        guard settings.isClipboardRedirectionEnabled, connectionState.status == .connected,
              clipboardDelegate?.connectionShouldSendClipboardImage(self) ?? true,
              ExtendedClipboard.isValidDIBV5(imageData),
              let capabilities = serverClipboardCapabilities,
              capabilities.formats & ExtendedClipboard.dib != 0 else { return false }
        pendingClipboardImage = imageData
        if capabilities.flags & ExtendedClipboard.notify != 0 {
            return enqueueClipboard(ExtendedClipboard(flags: ExtendedClipboard.notify | ExtendedClipboard.dib))
        }
        if capabilities.flags & ExtendedClipboard.provide != 0,
           UInt32(imageData.count) <= (capabilities.sizes[ExtendedClipboard.dib] ?? 0) {
            return enqueueClipboard(ExtendedClipboard(flags: ExtendedClipboard.provide | ExtendedClipboard.dib,
                                                       imageData: imageData))
        }
        return false
    }
}

public extension VNCConnection {
    /// Discards unsent text and treats the current clipboard as already seen.
    /// Call on the main queue when activating or deactivating a session so text
    /// copied in another session is not uploaded after switching tabs.
    func resetClipboardSynchronization() {
        dispatchPrecondition(condition: .onQueue(.main))
        pendingClipboardText = nil
        pendingClipboardImage = nil
        clipboardMonitor.acknowledgeCurrentChange()
    }

    /// Sends text without requiring a system clipboard write. The result is false if
    /// clipboard policy, negotiated formats or size limits prevent sending it.
    func sendClipboardText(_ text: String) async -> Bool {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async { [weak self] in
                continuation.resume(returning: self?.sendClipboardOnMainQueue(text) ?? false)
            }
        }
    }
}

extension VNCConnection: VNCClipboardMonitorDelegate {
    func clipboardMonitorShouldMonitor(_ clipboardMonitor: VNCClipboardMonitor) -> Bool { maySendClipboard }
    func clipboardMonitor(_ clipboardMonitor: VNCClipboardMonitor, didChangeText text: String) {
        sendClipboardOnMainQueue(text)
    }
    func clipboardMonitor(_ clipboardMonitor: VNCClipboardMonitor, didChangeImageData imageData: Data) {
        sendClipboardImageOnMainQueue(imageData)
    }
}
