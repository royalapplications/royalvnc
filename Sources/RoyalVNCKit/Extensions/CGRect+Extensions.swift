import Foundation

public extension CGRect {
	func flipped(bounds: CGRect) -> CGRect {
        .init(x: self.minX,
              y: bounds.maxY - self.maxY,
              width: self.width,
              height: self.height)
    }
}
