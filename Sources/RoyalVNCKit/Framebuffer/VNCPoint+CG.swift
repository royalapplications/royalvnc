#if canImport(CoreGraphics)
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

import CoreGraphics

public extension VNCPoint {
    init(cgPoint: CGPoint) {
        self.x = .init(cgPoint.x)
        self.y = .init(cgPoint.y)
    }

	var cgPoint: CGPoint {
        .init(x: CGFloat(x),
              y: CGFloat(y))
	}
}

public extension CGPoint {
	var vncPoint: VNCPoint {
		.init(cgPoint: self)
	}
}
#endif
