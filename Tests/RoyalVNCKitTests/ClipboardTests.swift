import Foundation
import XCTest
@testable import RoyalVNCKit

final class ClipboardTests: XCTestCase {
    func testUnicodeProvideRoundTripPreservesTextAndNormalizesLineEndings() throws {
        let original = "Svenska åäö\n日本語 🙂\r\nfin"
        let packet = ExtendedClipboard(flags: ExtendedClipboard.provide | ExtendedClipboard.text, textValue: original)
        let decoded = try ExtendedClipboard.decode(packet.encoded())
        XCTAssertEqual(decoded.textValue, "Svenska åäö\n日本語 🙂\nfin")
    }

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
        }
    }

    func testMinimumSignedLengthIsRejectedWithoutAllocationOrOverflow() async {
        let connection = FragmentedReader(Data([0, 0, 0, 0x80, 0, 0, 0]))
        do {
            _ = try await VNCProtocol.ServerCutText.receive(connection: connection, logger: VNCPrintLogger())
            XCTFail("An unbounded clipboard message must be rejected")
        } catch { }
    }

    func testLegacyUnicodeFailureDoesNotQueueAnEmptyClipboardUpdate() async {
        await MainActor.run {
            let connection = Self.connection()
            XCTAssertFalse(connection.sendClipboardOnMainQueue("日本語 🙂"))
            XCTAssertTrue(connection.sendClipboardOnMainQueue("åäö"))
            XCTAssertTrue(connection.sendClipboardOnMainQueue(""))
        }
    }

    #if os(macOS)
    func testControlMessagesPreserveClipboardAndDisabledSettingBlocksSynchronization() async throws {
        try await MainActor.run {
            let isolated = try IsolatedPasteboard()
            defer { withExtendedLifetime(isolated) { } }
            let connection = Self.connection()
            connection.clipboard.text = "existing private test text"
            connection.handleClipboardMessage(.init(messageType: 3, text: nil,
                extended: ExtendedClipboard(flags: ExtendedClipboard.actions | 1)))
            XCTAssertEqual(connection.clipboard.text, "existing private test text")
            connection.handleClipboardMessage(.init(messageType: 3, text: nil,
                extended: ExtendedClipboard(flags: ExtendedClipboard.notify | 1)))
            XCTAssertEqual(connection.clipboard.text, "existing private test text")
            connection.pendingClipboardText = "stale local text"
            connection.handleClipboardMessage(.init(messageType: 3, text: "remote text", extended: nil))
            XCTAssertEqual(connection.clipboard.text, "remote text")
            XCTAssertNil(connection.pendingClipboardText)
            // A real empty text update must still clear the clipboard.
            connection.handleClipboardMessage(.init(messageType: 3, text: "", extended: nil))
            XCTAssertEqual(connection.clipboard.text, "")

            let disabled = Self.connection(clipboardEnabled: false)
            disabled.clipboard.text = "keep this text"
            disabled.handleClipboardMessage(.init(messageType: 3, text: "discard", extended: nil))
            disabled.handleClipboardMessage(.init(messageType: 3, text: nil,
                extended: ExtendedClipboard(flags: ExtendedClipboard.actions | 1)))
            XCTAssertEqual(disabled.clipboard.text, "keep this text")
            XCTAssertNil(disabled.serverClipboardCapabilities)
            XCTAssertFalse(disabled.sendClipboardOnMainQueue("discard"))
        }
    }
    #endif

    private static func connection(clipboardEnabled: Bool = true) -> VNCConnection {
        let settings = VNCConnection.Settings(isDebugLoggingEnabled: false, hostname: "localhost", port: 5900,
            isShared: true, isScalingEnabled: true, useDisplayLink: false,
            inputMode: .forwardKeyboardShortcutsIfNotInUseLocally, isClipboardRedirectionEnabled: clipboardEnabled,
            colorDepth: .depth24Bit, frameEncodings: .default)
        let connection = VNCConnection(settings: settings, logger: VNCPrintLogger())
        connection.connectionState = .connected
        return connection
    }
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
