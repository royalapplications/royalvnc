import Foundation

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

class VNCClipboard {
	#if os(macOS)
	let pasteboard: NSPasteboard
	#elseif os(iOS)
	let pasteboard: UIPasteboard
	#endif
	
	init() {
		self.pasteboard = .general
	}
}

extension VNCClipboard {
	var text: String? {
		get {
			#if os(macOS)
			let text = pasteboard.string(forType: .string)
			#elseif os(iOS)
			let text = pasteboard.string
			#endif

			return text
		}
		set {
			#if os(macOS)
			pasteboard.clearContents()

			pasteboard.setString(newValue ?? "", forType: .string)
			#elseif os(iOS)
			pasteboard.string = newValue
			#endif
		}
	}
}

extension VNCClipboard {
	var changeCount: Int {
		pasteboard.changeCount
	}
}
