import Foundation

protocol VNCClipboardMonitorDelegate: AnyObject {
	func clipboardMonitorShouldMonitor(_ clipboardMonitor: VNCClipboardMonitor) -> Bool
	
	func clipboardMonitor(_ clipboardMonitor: VNCClipboardMonitor,
						  didChangeText text: String)
}
