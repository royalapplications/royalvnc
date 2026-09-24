import Foundation
import XCTest
@testable import RoyalVNCKit

/// Opt-in test against an independent TigerVNC server, tunneled to localhost.
/// The fixture writes a remote Unicode marker after the ready file appears and
/// verifies the outgoing marker with an X11 clipboard reader.
final class ClipboardInteropTests: XCTestCase {
    func testTigerVNCUnicodeClipboardBothDirections() throws {
        guard let readyPath = ProcessInfo.processInfo.environment["ROYAL_VNC_INTEROP_READY"] else {
            throw XCTSkip("Requires the disposable TigerVNC fixture")
        }
        let settings = VNCConnection.Settings(isDebugLoggingEnabled: false, hostname: "127.0.0.1", port: 5906,
            isShared: true, isScalingEnabled: true, useDisplayLink: false,
            inputMode: .forwardKeyboardShortcutsIfNotInUseLocally, isClipboardRedirectionEnabled: true,
            colorDepth: .depth24Bit, frameEncodings: .default)
        let connection = VNCConnection(settings: settings, logger: VNCPrintLogger())
        let received = expectation(description: "Remote Unicode clipboard")
        let policy = InteropPolicy(received: received)
        connection.clipboardDelegate = policy
        connection.connect()
        defer { connection.disconnect(); try? FileManager.default.removeItem(atPath: readyPath) }
        let connected = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            connection.connectionState.status == .connected && connection.serverClipboardCapabilities != nil
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [connected], timeout: 15), .completed)
        try Data().write(to: URL(fileURLWithPath: readyPath))
        wait(for: [received], timeout: 15)
        // Explicit text only: the fixture must never read the host's real clipboard.
        connection.clipboardMonitor.stopMonitoring()
        policy.sending = true
        XCTAssertTrue(connection.sendClipboardOnMainQueue("local åäö 日本語 🙂\nsecond line"))
        policy.sending = false
        // Permit the peer's Request for our queued marker, but not monitor ticks.
        policy.outgoingMarker = connection.pendingClipboardText
        let drained = expectation(description: "Peer reads queued marker")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { drained.fulfill() }
        wait(for: [drained], timeout: 5)
    }
}

private final class InteropPolicy: VNCClipboardDelegate {
    let received: XCTestExpectation
    var sending = false
    var outgoingMarker: String?
    init(received: XCTestExpectation) { self.received = received }
    func connectionShouldSendClipboard(_ connection: VNCConnection) -> Bool {
        // Once queued, the clipboard monitor is stopped before enabling requests.
        if outgoingMarker != nil { return true }
        return sending
    }
    func connectionShouldReceiveClipboard(_ connection: VNCConnection) -> Bool { true }
    func connection(_ connection: VNCConnection, didReceiveClipboardText text: String) {
        if text == "remote åäö 日本語 🙂\nsecond line" { received.fulfill() }
    }
}
