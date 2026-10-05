#if os(macOS)
import AppKit
import XCTest
@testable import RoyalVNCKit

@MainActor
final class VNCFramebufferCaptureMacOSTests: XCTestCase {
    func testPNGContainsFramebufferPixelsAndOpaqueLetterboxInCorrectOrientation() throws {
        let settings = VNCConnection.Settings(isDebugLoggingEnabled: false, hostname: "localhost", port: 5900,
            isShared: true, isScalingEnabled: true, useDisplayLink: false,
            inputMode: .forwardKeyboardShortcutsIfNotInUseLocally, isClipboardRedirectionEnabled: false,
            colorDepth: .depth24Bit, frameEncodings: .default)
        let connection = VNCConnection(settings: settings, logger: VNCPrintLogger())
        let framebuffer = try VNCFramebuffer(logger: VNCPrintLogger(), size: VNCSize(width: 80, height: 80),
            screens: [], pixelFormat: VNCProtocol.PixelFormat(depth: 24), allocator: nil)
        var red = Data([0, 0, 255, 0])
        var green = Data([0, 255, 0, 0])
        framebuffer.fill(region: VNCRegion(x: 0, y: 0, width: 80, height: 40), withPixel: &red)
        framebuffer.fill(region: VNCRegion(x: 0, y: 40, width: 80, height: 40), withPixel: &green)
        let delegate = CaptureDelegate()
        let view = VNCCAFramebufferView(frame: NSRect(x: 0, y: 0, width: 160, height: 80),
            framebuffer: framebuffer, connection: connection, connectionDelegate: delegate)
        for size in [NSSize(width: 160, height: 80), NSSize(width: 80, height: 40)] {
            view.setFrameSize(size)
            let bitmap = try XCTUnwrap(view.bitmapImageRepForCachingDisplay(in: view.bounds))
            view.cacheDisplay(in: view.bounds, to: bitmap)
            let png = try XCTUnwrap(NSBitmapImageRep(data: XCTUnwrap(bitmap.representation(using: .png, properties: [:]))))
            XCTAssertEqual(png.pixelsWide, Int(view.convertToBacking(view.bounds).width))
            XCTAssertEqual(png.pixelsHigh, Int(view.convertToBacking(view.bounds).height))
            let top = try XCTUnwrap(png.colorAt(x: png.pixelsWide / 2, y: png.pixelsHigh / 4)?.usingColorSpace(.deviceRGB))
            let bottom = try XCTUnwrap(png.colorAt(x: png.pixelsWide / 2, y: png.pixelsHigh * 3 / 4)?.usingColorSpace(.deviceRGB))
            let margin = try XCTUnwrap(png.colorAt(x: 0, y: 0)?.usingColorSpace(.deviceRGB))
            XCTAssertGreaterThan(top.redComponent, 0.9)
            XCTAssertLessThan(top.greenComponent, 0.25)
            XCTAssertGreaterThan(bottom.greenComponent, 0.9)
            XCTAssertLessThan(bottom.redComponent, 0.1)
            for color in [top, bottom, margin] { XCTAssertEqual(color.alphaComponent, 1, accuracy: 0.01) }
            XCTAssertLessThan(margin.redComponent + margin.greenComponent + margin.blueComponent, 0.01)
        }
        withExtendedLifetime((connection, framebuffer, delegate)) {}
    }
}

private final class CaptureDelegate: VNCConnectionDelegate {
    func connection(_ connection: VNCConnection, stateDidChange connectionState: VNCConnection.ConnectionState) {}
    func connection(_ connection: VNCConnection, credentialFor authenticationType: VNCAuthenticationType,
                    completion: @escaping (VNCCredential?) -> Void) { completion(nil) }
    func connection(_ connection: VNCConnection, didCreateFramebuffer framebuffer: VNCFramebuffer) {}
    func connection(_ connection: VNCConnection, didResizeFramebuffer framebuffer: VNCFramebuffer) {}
    func connection(_ connection: VNCConnection, didUpdateFramebuffer framebuffer: VNCFramebuffer,
                    x: UInt16, y: UInt16, width: UInt16, height: UInt16) {}
    func connection(_ connection: VNCConnection, didUpdateCursor cursor: VNCCursor) {}
}
#endif
