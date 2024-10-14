#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

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
#if os(macOS) || os(iOS)
		self.pasteboard = .general
#endif
	}
}

extension VNCClipboard {
	var text: String? {
		get {
#if os(macOS)
			let text = pasteboard.string(forType: .string)
#elseif os(iOS)
			let text = pasteboard.string
#else
			let text: String? = nil
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
#if os(macOS) || os(iOS)
		pasteboard.changeCount
#else
		0
#endif
	}
}
