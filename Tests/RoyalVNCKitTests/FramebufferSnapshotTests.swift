#if canImport(CoreImage) && canImport(IOSurface)
import CoreGraphics
import XCTest
@testable import RoyalVNCKit

final class FramebufferSnapshotTests: XCTestCase {
    func testImageRetainsPixelsWhenFramebufferChangesBeforeDrawing() throws {
        let framebuffer = try VNCFramebuffer(logger: VNCPrintLogger(),
            size: VNCSize(width: 4, height: 4), screens: [],
            pixelFormat: VNCProtocol.PixelFormat(depth: 24), allocator: nil)
        var red = Data([0, 0, 255, 0])
        framebuffer.fill(region: framebuffer.fullRegion, withPixel: &red)
        let first = try XCTUnwrap(framebuffer.cgImage)
        var blue = Data([255, 0, 0, 0])
        framebuffer.fill(region: framebuffer.fullRegion, withPixel: &blue)
        let second = try XCTUnwrap(framebuffer.cgImage)
        XCTAssertEqual(try pixel(first), [255, 0, 0, 255], "An image already handed to a layer must not change with the next network update")
        XCTAssertEqual(try pixel(second), [0, 0, 255, 255])
    }

    private func pixel(_ image: CGImage) throws -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: 4 * 4 * 4)
        try bytes.withUnsafeMutableBytes { storage in
            let context = try XCTUnwrap(CGContext(data: storage.baseAddress,
                width: 4, height: 4, bitsPerComponent: 8, bytesPerRow: 16,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
            context.draw(image, in: CGRect(x: 0, y: 0, width: 4, height: 4))
        }
        return Array(bytes.prefix(4))
    }
}
#endif
