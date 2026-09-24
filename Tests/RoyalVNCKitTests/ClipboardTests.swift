import Foundation
import XCTest
#if canImport(CoreGraphics)
import CoreGraphics
#endif
#if os(macOS)
import AppKit
#endif
@testable import RoyalVNCKit

final class ClipboardTests: XCTestCase {
    func testUnicodeProvideRoundTripPreservesTextAndNormalizesLineEndings() throws {
        let original = "Svenska åäö\n日本語 🙂\r\nfin"
        let packet = ExtendedClipboard(flags: ExtendedClipboard.provide | ExtendedClipboard.text, textValue: original)
        let decoded = try ExtendedClipboard.decode(packet.encoded())
        XCTAssertEqual(decoded.textValue, "Svenska åäö\n日本語 🙂\nfin")
    }

    func testDIBV5ProvideRoundTripAndRejectsMalformedImages() throws {
        let dib = Self.validDIBV5()
        let packet = ExtendedClipboard(flags: ExtendedClipboard.provide | ExtendedClipboard.dib,
                                       imageData: dib)
        XCTAssertEqual(try ExtendedClipboard.decode(packet.encoded()).imageData, dib)

        var malformed = dib
        malformed[0] = 123
        XCTAssertFalse(ExtendedClipboard.isValidDIBV5(malformed))
        var oversized = Self.validDIBV5(width: 2049, height: -1024)
        oversized.removeLast(4)
        XCTAssertFalse(ExtendedClipboard.isValidDIBV5(oversized))
        XCTAssertThrowsError(try ExtendedClipboard(flags: ExtendedClipboard.provide | ExtendedClipboard.dib,
                                                   imageData: malformed).encoded())
    }

    func testClipboardImageCapabilitiesPolicyAndReset() async throws {
        await MainActor.run {
            let connection = Self.connection()
            let dib = Self.validDIBV5()
            let policy = ClipboardImagePolicy()
            connection.clipboardDelegate = policy
            connection.serverClipboardCapabilities = ExtendedClipboard(
                flags: ExtendedClipboard.actions | ExtendedClipboard.text | ExtendedClipboard.dib,
                sizes: [ExtendedClipboard.text: 0, ExtendedClipboard.dib: 0])

            XCTAssertTrue(connection.sendClipboardImageOnMainQueue(dib))
            XCTAssertEqual(connection.pendingClipboardImage, dib)
            connection.resetClipboardSynchronization()
            XCTAssertNil(connection.pendingClipboardImage)

            policy.sending = false
            XCTAssertFalse(connection.sendClipboardImageOnMainQueue(dib))
            policy.sending = true
            connection.serverClipboardCapabilities = ExtendedClipboard(flags: ExtendedClipboard.actions | ExtendedClipboard.text)
            XCTAssertFalse(connection.sendClipboardImageOnMainQueue(dib))

            connection.serverClipboardCapabilities = ExtendedClipboard(
                flags: ExtendedClipboard.actions | ExtendedClipboard.text | ExtendedClipboard.dib,
                sizes: [ExtendedClipboard.text: 0, ExtendedClipboard.dib: 0])
            let incoming = VNCProtocol.ServerCutText(messageType: 3, text: nil,
                extended: ExtendedClipboard(flags: ExtendedClipboard.provide | ExtendedClipboard.dib,
                                            imageData: dib))
            connection.handleClipboardMessage(incoming)
            XCTAssertEqual(policy.received, [dib])
        }
    }

#if os(macOS)
    func testDIBV5BitmapConversionPreservesImagePixels() throws {
        let sourcePixels = Data([255, 0, 0, 255])
        let provider = try XCTUnwrap(CGDataProvider(data: sourcePixels as CFData))
        let image = try XCTUnwrap(CGImage(width: 1, height: 1, bitsPerComponent: 8, bitsPerPixel: 32,
            bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue), provider: provider,
            decode: nil, shouldInterpolate: false, intent: .defaultIntent))
        let dib = try XCTUnwrap(DIBV5Bitmap.encode(image))
        let decoded = try XCTUnwrap(DIBV5Bitmap.decode(dib))
        let pixel = try XCTUnwrap(NSBitmapImageRep(cgImage: decoded).colorAt(x: 0, y: 0)?.usingColorSpace(.deviceRGB))
        XCTAssertGreaterThan(pixel.redComponent, 0.95)
        XCTAssertLessThan(pixel.greenComponent, 0.05)
        XCTAssertLessThan(pixel.blueComponent, 0.05)
    }

    func testDIBV5BitmapConversionPreservesAllPixelsAndRowOrder() throws {
        let pixels = Data([
            255, 0, 0, 255, 0, 255, 0, 255,
            0, 0, 255, 255, 255, 255, 0, 255
        ])
        let provider = try XCTUnwrap(CGDataProvider(data: pixels as CFData))
        let image = try XCTUnwrap(CGImage(width: 2, height: 2, bitsPerComponent: 8, bitsPerPixel: 32,
            bytesPerRow: 8, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue), provider: provider,
            decode: nil, shouldInterpolate: false, intent: .defaultIntent))
        let dib = try XCTUnwrap(VNCClipboardImageCodec.encode(image))
        let decoded = try XCTUnwrap(VNCClipboardImageCodec.decode(dib))
        let source = NSBitmapImageRep(cgImage: image)
        let result = NSBitmapImageRep(cgImage: decoded)
        for y in 0..<2 {
            for x in 0..<2 {
                let expected = try XCTUnwrap(source.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB))
                let actual = try XCTUnwrap(result.colorAt(x: x, y: y)?.usingColorSpace(.deviceRGB))
                XCTAssertEqual(actual.redComponent, expected.redComponent, accuracy: 0.01)
                XCTAssertEqual(actual.greenComponent, expected.greenComponent, accuracy: 0.01)
                XCTAssertEqual(actual.blueComponent, expected.blueComponent, accuracy: 0.01)
            }
        }
    }

    func testDIBV5ImageRoundTripsThroughAnIsolatedPasteboard() throws {
        let pixels = Data([255, 0, 0, 255])
        let provider = try XCTUnwrap(CGDataProvider(data: pixels as CFData))
        let image = try XCTUnwrap(CGImage(width: 1, height: 1, bitsPerComponent: 8, bitsPerPixel: 32,
            bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue), provider: provider,
            decode: nil, shouldInterpolate: false, intent: .defaultIntent))
        let pasteboard = NSPasteboard(name: NSPasteboard.Name("RoyalVNCKitTest-\\(UUID().uuidString)"))
        defer { pasteboard.releaseGlobally() }
        let clipboard = VNCClipboard(pasteboard: pasteboard)
        clipboard.imageData = try XCTUnwrap(VNCClipboardImageCodec.encode(image))
        XCTAssertNotNil(pasteboard.data(forType: .png))

        let roundTripped = try XCTUnwrap(clipboard.imageData)
        let decoded = try XCTUnwrap(VNCClipboardImageCodec.decode(roundTripped))
        let color = try XCTUnwrap(NSBitmapImageRep(cgImage: decoded).colorAt(x: 0, y: 0)?.usingColorSpace(.deviceRGB))
        XCTAssertGreaterThan(color.redComponent, 0.95)
        XCTAssertLessThan(color.greenComponent, 0.05)
        XCTAssertLessThan(color.blueComponent, 0.05)
    }
#endif

    func testProvideUsesIndependentZlibStreams() throws {
        for text in ["one", "日本語", "", "two"] {
            let packet = ExtendedClipboard(flags: ExtendedClipboard.provide | 1, textValue: text)
            XCTAssertEqual(try ExtendedClipboard.decode(packet.encoded()).textValue, text)
        }
    }

    func testAcceptsTigerVNCSyncFlushedClipboardStreamAndRejectsTruncation() throws {
        // Python zlib.compressobj().flush(zlib.Z_SYNC_FLUSH), UInt32 length + "hello\\0".
        let payload = Data([16, 0, 0, 1, 120, 156, 98, 96, 96, 96, 203, 72, 205, 201, 201, 103, 0, 0, 0, 0, 255, 255])
        XCTAssertEqual(try ExtendedClipboard.decode(payload).textValue, "hello")
        XCTAssertThrowsError(try ExtendedClipboard.decode(Data(payload.dropLast())))
    }

    func testCapabilitiesAndNotificationsDoNotBecomeEmptyClipboardText() throws {
        let caps = ExtendedClipboard(flags: ExtendedClipboard.actions | 1 | 0x8000,
                                     sizes: [1: 0, 0x8000: 128])
        let decoded = try ExtendedClipboard.decode(caps.encoded())
        XCTAssertNil(decoded.textValue)
        XCTAssertEqual(decoded.sizes, [1: 0, 0x8000: 128])
        XCTAssertNil(try ExtendedClipboard.decode(ExtendedClipboard(flags: ExtendedClipboard.notify | 1).encoded()).textValue)
    }

    func testRejectsMalformedAndOversizedPackets() {
        let invalid: [Data] = [
            Data(), Data([1, 0, 0]),
            Data([1, 0, 0, 1]), // Caps missing its format size.
            Data([10, 0, 0, 1]), // More than one non-Caps action.
            Data([8, 0, 0, 1, 0]), // Trailing bytes after Notify.
            Data([16, 0, 0, 1, 1, 2, 3]), // Invalid zlib stream.
            Data(repeating: 0, count: ExtendedClipboard.maximumPacketBytes + 1)
        ]
        for packet in invalid { XCTAssertThrowsError(try ExtendedClipboard.decode(packet)) }
        XCTAssertThrowsError(try ExtendedClipboard(flags: ExtendedClipboard.provide | 1,
                                                   textValue: String(repeating: "x", count: ExtendedClipboard.maximumTextBytes)).encoded())
        XCTAssertThrowsError(try ExtendedClipboard(flags: ExtendedClipboard.provide | 1, textValue: "a\0b").encoded())
    }

    func testReadsFragmentedUnicodeAndFollowingLegacyMessages() async throws {
        let extended = try ExtendedClipboard(flags: ExtendedClipboard.provide | 1, textValue: "日本語 🙂").encoded()
        var bytes = Data([0, 0, 0])
        bytes.append(UInt32(bitPattern: -Int32(extended.count)), bigEndian: true)
        bytes.append(extended)
        bytes.append(contentsOf: [0, 0, 0, 0, 0, 0, 3, 0xe5, 0xe4, 0xf6])
        let connection = FragmentedReader(bytes)
        let first = try await VNCProtocol.ServerCutText.receive(connection: connection, logger: VNCPrintLogger())
        let next = try await VNCProtocol.ServerCutText.receive(connection: connection, logger: VNCPrintLogger())
        XCTAssertEqual(first.text, "日本語 🙂")
        XCTAssertEqual(next.text, "åäö")
        XCTAssertTrue(connection.bytes.isEmpty)
    }

    func testRejectsTrailingCompressedDataAndExpandedOversizedText() async throws {
        var payload = try ExtendedClipboard(flags: ExtendedClipboard.provide | 1, textValue: "safe").encoded()
        payload.append(0)
        XCTAssertThrowsError(try ExtendedClipboard.decode(payload))
        await MainActor.run {
            let connection = Self.connection()
            connection.serverClipboardCapabilities = ExtendedClipboard(flags: ExtendedClipboard.actions | 1)
            XCTAssertFalse(connection.sendClipboardOnMainQueue(String(repeating: "\n", count: ExtendedClipboard.maximumTextBytes / 2)))
            XCTAssertFalse(connection.sendClipboardOnMainQueue("before\0after"))
            XCTAssertNil(connection.pendingClipboardText)
            XCTAssertTrue(connection.sendClipboardOnMainQueue("safe\ntext"))
            XCTAssertEqual(connection.pendingClipboardText, "safe\ntext")
            connection.resetClipboardSynchronization()
            XCTAssertNil(connection.pendingClipboardText)
        }
    }

    func testMinimumSignedLengthIsRejectedWithoutAllocationOrOverflow() async {
        let connection = FragmentedReader(Data([0, 0, 0, 0x80, 0, 0, 0]))
        do {
            _ = try await VNCProtocol.ServerCutText.receive(connection: connection, logger: VNCPrintLogger())
            XCTFail("An unbounded clipboard message must be rejected")
        } catch { }
    }

    func testPolicyIsolatesInactiveConnectionsAndCapsNeverClearClipboard() async {
        await MainActor.run {
            let first = Self.connection()
            let second = Self.connection()
            let active = ClipboardPolicy(active: true)
            let inactive = ClipboardPolicy(active: false)
            first.clipboardDelegate = active
            second.clipboardDelegate = inactive
            let message = VNCProtocol.ServerCutText(messageType: 3, text: "server text", extended: nil)
            first.handleClipboardMessage(message)
            second.handleClipboardMessage(message)
            XCTAssertEqual(active.received, ["server text"])
            XCTAssertTrue(inactive.received.isEmpty)
            XCTAssertTrue(first.clipboardMonitorShouldMonitor(first.clipboardMonitor))
            XCTAssertFalse(second.clipboardMonitorShouldMonitor(second.clipboardMonitor))
            first.handleClipboardMessage(.init(messageType: 3, text: nil,
                                               extended: ExtendedClipboard(flags: ExtendedClipboard.actions | 1)))
            XCTAssertEqual(active.received, ["server text"])
            active.active = false
            inactive.active = true
            XCTAssertFalse(first.sendClipboardOnMainQueue("private text"))
            XCTAssertTrue(second.sendClipboardOnMainQueue("chosen session"))
        }
    }

    func testLegacyUnicodeFailureDoesNotQueueAnEmptyClipboardUpdate() async {
        await MainActor.run {
            let connection = Self.connection()
            XCTAssertFalse(connection.sendClipboardOnMainQueue("日本語 🙂"))
            XCTAssertTrue(connection.sendClipboardOnMainQueue("åäö"))
            XCTAssertTrue(connection.sendClipboardOnMainQueue(""))
        }
    }

    private static func connection() -> VNCConnection {
        let settings = VNCConnection.Settings(isDebugLoggingEnabled: false, hostname: "localhost", port: 5900,
            isShared: true, isScalingEnabled: true, useDisplayLink: false,
            inputMode: .forwardKeyboardShortcutsIfNotInUseLocally, isClipboardRedirectionEnabled: true,
            colorDepth: .depth24Bit, frameEncodings: .default)
        let connection = VNCConnection(settings: settings, logger: VNCPrintLogger())
        connection.connectionState = .connected
        return connection
    }

    private static func validDIBV5(width: Int32 = 1, height: Int32 = -1) -> Data {
        var data = Data(repeating: 0, count: 124)
        func write32(_ value: UInt32, at offset: Int) {
            data.replaceSubrange(offset..<(offset + 4), with: value.littleEndianBytes)
        }
        func write16(_ value: UInt16, at offset: Int) {
            data.replaceSubrange(offset..<(offset + 2), with: value.littleEndianBytes)
        }
        write32(124, at: 0)
        write32(UInt32(bitPattern: width), at: 4)
        write32(UInt32(bitPattern: height), at: 8)
        write16(1, at: 12)
        write16(32, at: 14)
        write32(3, at: 16) // BI_BITFIELDS
        write32(UInt32(abs(height)) * UInt32(width) * 4, at: 20)
        write32(0x00ff0000, at: 40)
        write32(0x0000ff00, at: 44)
        write32(0x000000ff, at: 48)
        write32(0xff000000, at: 52)
        write32(0x73524742, at: 56) // LCS_sRGB
        data.append(contentsOf: [0, 0, 255, 255])
        return data
    }
}

private final class ClipboardImagePolicy: VNCClipboardDelegate {
    var sending = true
    var received: [Data] = []
    func connectionShouldSendClipboard(_ connection: VNCConnection) -> Bool { sending }
    func connectionShouldReceiveClipboard(_ connection: VNCConnection) -> Bool { true }
    func connection(_ connection: VNCConnection, didReceiveClipboardText text: String) {}
    func connectionShouldSendClipboardImage(_ connection: VNCConnection) -> Bool { sending }
    func connection(_ connection: VNCConnection, didReceiveClipboardImageData imageData: Data) {
        received.append(imageData)
    }
}

private extension UInt16 {
    var littleEndianBytes: [UInt8] { withUnsafeBytes(of: littleEndian, Array.init) }
}

private extension UInt32 {
    var littleEndianBytes: [UInt8] { withUnsafeBytes(of: littleEndian, Array.init) }
}

private final class ClipboardPolicy: VNCClipboardDelegate {
    var active: Bool
    var received: [String] = []
    init(active: Bool) { self.active = active }
    func connectionShouldSendClipboard(_ connection: VNCConnection) -> Bool { active }
    func connection(_ connection: VNCConnection, didReceiveClipboardText text: String) { received.append(text) }
}

private final class FragmentedReader: NetworkConnectionReading {
    var bytes: Data
    init(_ bytes: Data) { self.bytes = bytes }
    func read(minimumLength: Int, maximumLength: Int) async throws -> Data {
        guard !bytes.isEmpty else { throw VNCError.protocol(.invalidData) }
        let count = min(2, maximumLength, bytes.count)
        let result = Data(bytes.prefix(count))
        bytes = Data(bytes.dropFirst(count))
        return result
    }
}
