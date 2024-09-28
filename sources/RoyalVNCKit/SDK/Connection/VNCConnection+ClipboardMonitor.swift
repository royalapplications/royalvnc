import Foundation

extension VNCConnection {
	func startMonitoringClipboard() {
		guard settings.isClipboardRedirectionEnabled else { return }
		
		clipboardMonitor.startMonitoring()
	}
	
	func stopMonitoringClipboard() {
		guard settings.isClipboardRedirectionEnabled else { return }
		
		clipboardMonitor.stopMonitoring()
	}
}

// MARK: - VNCClipboardMonitorDelegate
extension VNCConnection: VNCClipboardMonitorDelegate {
	func clipboardMonitorShouldMonitor(_ clipboardMonitor: VNCClipboardMonitor) -> Bool {
		let isConnected = connectionState.status == .connected
		
		return isConnected
	}
	
	func clipboardMonitor(_ clipboardMonitor: VNCClipboardMonitor,
						  didChangeText text: String) {
		logger.logDebug("Clipboard Monitor did change text")
		
		guard settings.isClipboardRedirectionEnabled else { return }
		
		enqueueClientCutTextMessage(text)
	}
}
