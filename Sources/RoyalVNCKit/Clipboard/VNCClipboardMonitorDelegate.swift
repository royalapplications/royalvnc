#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

protocol VNCClipboardMonitorDelegate: AnyObject {
	func clipboardMonitorShouldMonitor(_ clipboardMonitor: VNCClipboardMonitor) -> Bool

	func clipboardMonitor(_ clipboardMonitor: VNCClipboardMonitor,
						  didChangeText text: String)

    func clipboardMonitor(_ clipboardMonitor: VNCClipboardMonitor,
                          didChangeImageData imageData: Data)
}

extension VNCClipboardMonitorDelegate {
    func clipboardMonitor(_ clipboardMonitor: VNCClipboardMonitor, didChangeImageData imageData: Data) {}
}
