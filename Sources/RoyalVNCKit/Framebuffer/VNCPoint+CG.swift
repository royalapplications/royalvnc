#if canImport(CoreGraphics)
import Foundation
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
