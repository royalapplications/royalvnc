#if os(macOS)
import Foundation
import AppKit

public extension VNCCursor {
	var nsCursor: NSCursor {
		guard !isEmpty else {
			return Self.emptyNSCursor
		}
		
		guard let image = self.nsImage else {
			return Self.emptyNSCursor
		}
		
		let cursor = NSCursor(image: image,
							  hotSpot: hotspot.cgPoint)
		
		return cursor
	}
}

private extension VNCCursor {
	static var emptyNSCursor: NSCursor {
		// TODO: Should use a "dot" cursor like in other VNC clients
		
		.arrow
	}
	
	var nsImage: NSImage? {
		guard let cgImage = cgImage else { return nil }

		let nsImage = NSImage(cgImage: cgImage, size: size.cgSize)
		
		return nsImage
	}
}
#endif
