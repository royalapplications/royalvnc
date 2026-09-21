#if os(macOS)
import AppKit
import XCTest
@testable import RoyalVNCKit

/// Opt-in test against an independent TigerVNC server tunneled to localhost.
/// The fixture writes a remote Unicode marker after the ready file appears and
/// verifies the outgoing marker with an independent X11 clipboard reader.
final class ClipboardInteropTests: XCTestCase {
    func testTigerVNCUnicodeClipboardBothDirections() throws {
        guard let readyPath = ProcessInfo.processInfo.environment["ROYAL_VNC_INTEROP_READY"] else {
            throw XCTSkip("Requires the disposable TigerVNC fixture")
        }
        let isolated = try IsolatedPasteboard()
        let board = isolated.pasteboard
        let settings = VNCConnection.Settings(isDebugLoggingEnabled: false, hostname: "127.0.0.1", port: 5906,
            isShared: true, isScalingEnabled: true, useDisplayLink: false,
            inputMode: .forwardKeyboardShortcutsIfNotInUseLocally, isClipboardRedirectionEnabled: true,
            colorDepth: .depth24Bit, frameEncodings: .default)
        let connection = VNCConnection(settings: settings, logger: VNCPrintLogger())
        connection.connect()
        defer {
            connection.clipboardMonitor.stopMonitoring()
            connection.disconnect()
            try? FileManager.default.removeItem(atPath: readyPath)
            withExtendedLifetime(isolated) { }
        }
        let connected = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            connection.connectionState.status == .connected && connection.serverClipboardCapabilities != nil
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [connected], timeout: 15), .completed)
        try Data().write(to: URL(fileURLWithPath: readyPath))
        let received = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            board.string(forType: .string) == "remote åäö 日本語 🙂\nsecond line"
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [received], timeout: 15), .completed)
        board.clearContents()
        XCTAssertTrue(board.setString("local åäö 日本語 🙂\nsecond line", forType: .string))
        // Exercise the real clipboard monitor and Request/Provide exchange.
        let drained = expectation(description: "Peer reads local Unicode marker")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { drained.fulfill() }
        wait(for: [drained], timeout: 5)
        XCTAssertEqual(connection.connectionState.status, .connected)
    }
}
#endif
