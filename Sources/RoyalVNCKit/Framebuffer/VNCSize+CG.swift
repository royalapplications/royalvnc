#if canImport(CoreGraphics)
import Foundation
import CoreGraphics

public extension VNCSize {
    init(cgSize: CGSize) {
        self.width = .init(cgSize.width)
        self.height = .init(cgSize.height)
    }
    
	var cgSize: CGSize {
        .init(width: CGFloat(width),
              height: CGFloat(height))
	}
}

public extension CGSize {
	var vncSize: VNCSize {
		.init(cgSize: self)
	}
}
#endif
