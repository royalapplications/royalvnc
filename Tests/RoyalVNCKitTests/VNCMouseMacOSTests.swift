#if os(macOS)
import AppKit
import XCTest
@testable import RoyalVNCKit

@MainActor
final class VNCMouseMacOSTests: XCTestCase {
    private func fixture() throws -> (VNCCAFramebufferView, VNCConnection, VNCFramebuffer, MouseDelegate) {
        let settings = VNCConnection.Settings(isDebugLoggingEnabled: false, hostname: "localhost", port: 5900,
            isShared: true, isScalingEnabled: true, useDisplayLink: false,
            inputMode: .forwardKeyboardShortcutsIfNotInUseLocally, isClipboardRedirectionEnabled: false,
            colorDepth: .depth24Bit, frameEncodings: .default)
        let connection = VNCConnection(settings: settings, logger: VNCPrintLogger())
        let framebuffer = try VNCFramebuffer(logger: VNCPrintLogger(), size: VNCSize(width: 100, height: 100),
            screens: [], pixelFormat: VNCProtocol.PixelFormat(depth: 24), allocator: nil)
        connection.framebuffer = framebuffer
        let delegate = MouseDelegate()
        let view = VNCCAFramebufferView(frame: NSRect(x: 0, y: 0, width: 200, height: 100),
            framebuffer: framebuffer, connection: connection, connectionDelegate: delegate)
        return (view, connection, framebuffer, delegate)
    }

    private func event(_ type: NSEvent.EventType, x: CGFloat = 100, y: CGFloat = 50) throws -> NSEvent {
        try XCTUnwrap(NSEvent.mouseEvent(with: type, location: NSPoint(x: x, y: y), modifierFlags: [],
            timestamp: 0, windowNumber: 0, context: nil, eventNumber: 0, clickCount: 1, pressure: 0))
    }

    private func pointers(_ connection: VNCConnection) -> [VNCProtocol.PointerEvent] {
        var events: [VNCProtocol.PointerEvent] = []
        while let message = connection.clientToServerMessageQueue.dequeue() {
            if let pointer = message as? VNCProtocol.PointerEvent { events.append(pointer) }
        }
        return events
    }

    func testNormalDragRetainsPressUntilRelease() throws {
        let (view, connection, framebuffer, delegate) = try fixture()
        defer { withExtendedLifetime((framebuffer, delegate)) {} }
        view.mouseDown(with: try event(.leftMouseDown))
        view.mouseDragged(with: try event(.leftMouseDragged, x: 120))
        view.mouseUp(with: try event(.leftMouseUp, x: 130))
        let events = pointers(connection)
        XCTAssertEqual(events.map(\.buttonMask), [1, 1, 0])
        XCTAssertEqual(events.map(\.xPosition), [50, 70, 80])
    }

    func testTopMenuCoordinateAccountsForVerticalLetterboxAndScale() throws {
        let (view, connection, framebuffer, delegate) = try fixture()
        defer { withExtendedLifetime((framebuffer, delegate)) {} }
        view.frame.size = NSSize(width: 50, height: 100)
        // A 100x100 framebuffer scales to 50x50 at y=25. Five view pixels
        // below its top map to the remote menu bar's y=10, not y=60.
        view.mouseMoved(with: try event(.mouseMoved, x: 20, y: 70))
        let point = try XCTUnwrap(pointers(connection).first)
        XCTAssertEqual(point.xPosition, 40)
        XCTAssertEqual(point.yPosition, 10)
    }

    func testReleaseInLetterboxClearsHeldButtonBeforeNextMove() throws {
        let (view, connection, framebuffer, delegate) = try fixture()
        defer { withExtendedLifetime((framebuffer, delegate)) {} }
        view.mouseDown(with: try event(.leftMouseDown))
        view.mouseUp(with: try event(.leftMouseUp, x: 5))
        view.mouseMoved(with: try event(.mouseMoved, x: 110))
        let events = pointers(connection)
        XCTAssertEqual(events.map(\.buttonMask), [1, 0, 0])
        XCTAssertEqual(events.map(\.xPosition), [50, 50, 60])
        XCTAssertTrue(connection.mouseButtonState.isEmpty)
    }

    func testReleaseOutsideViewClearsRightButton() throws {
        let (view, connection, framebuffer, delegate) = try fixture()
        defer { withExtendedLifetime((framebuffer, delegate)) {} }
        view.rightMouseDown(with: try event(.rightMouseDown))
        view.rightMouseUp(with: try event(.rightMouseUp, x: -30, y: 150))
        XCTAssertEqual(pointers(connection).map(\.buttonMask), [4, 0])
        XCTAssertTrue(connection.mouseButtonState.isEmpty)
    }

    func testMiddleButtonReleaseOutsideContent() throws {
        let (view, connection, framebuffer, delegate) = try fixture()
        defer { withExtendedLifetime((framebuffer, delegate)) {} }
        func middleEvent(_ type: NSEvent.EventType, x: CGFloat) throws -> NSEvent {
            let cgEvent = try XCTUnwrap(event(type, x: x).cgEvent)
            cgEvent.setIntegerValueField(.mouseEventButtonNumber, value: 2)
            return try XCTUnwrap(NSEvent(cgEvent: cgEvent))
        }
        view.otherMouseDown(with: try middleEvent(.otherMouseDown, x: 100))
        view.otherMouseDragged(with: try middleEvent(.otherMouseDragged, x: 120))
        view.otherMouseUp(with: try middleEvent(.otherMouseUp, x: -30))
        XCTAssertEqual(pointers(connection).map(\.buttonMask), [2, 2, 0])
        XCTAssertTrue(connection.mouseButtonState.isEmpty)
    }

    func testFocusCleanupReleasesButtonsAndLateDragCannotPressAgain() throws {
        let (view, connection, framebuffer, delegate) = try fixture()
        defer { withExtendedLifetime((framebuffer, delegate)) {} }
        view.mouseDown(with: try event(.leftMouseDown))
        view.rightMouseDown(with: try event(.rightMouseDown))
        _ = view.resignFirstResponder()
        view.mouseDragged(with: try event(.leftMouseDragged, x: 120))
        view.rightMouseDragged(with: try event(.rightMouseDragged, x: 120))
        view.mouseUp(with: try event(.leftMouseUp))
        XCTAssertEqual(pointers(connection).map(\.buttonMask), [1, 5, 4, 0])
        XCTAssertTrue(connection.mouseButtonState.isEmpty)
    }

    func testWindowFocusLossReleasesButtonsAndIgnoresLateDrag() throws {
        try checkFocusLoss(notification: NSWindow.didResignKeyNotification)
    }

    func testApplicationDeactivationReleasesButtonsAndIgnoresLateDrag() throws {
        try checkFocusLoss(notification: NSApplication.didResignActiveNotification)
    }

    private func checkFocusLoss(notification: Notification.Name) throws {
        _ = NSApplication.shared
        let (view, connection, framebuffer, delegate) = try fixture()
        let window = NSWindow(contentRect: view.frame, styleMask: [.borderless],
                              backing: .buffered, defer: false)
        window.contentView = view
        defer { withExtendedLifetime((window, framebuffer, delegate)) {} }
        view.mouseDown(with: try event(.leftMouseDown))
        NotificationCenter.default.post(name: notification,
            object: notification == NSWindow.didResignKeyNotification ? window : NSApp)
        view.mouseDragged(with: try event(.leftMouseDragged, x: 120))
        XCTAssertEqual(pointers(connection).map(\.buttonMask), [1, 0])
        XCTAssertTrue(connection.mouseButtonState.isEmpty)
    }

    func testDetachedViewReleasesButtons() throws {
        _ = NSApplication.shared
        let (view, connection, framebuffer, delegate) = try fixture()
        let window = NSWindow(contentRect: view.frame, styleMask: [.borderless],
                              backing: .buffered, defer: false)
        let container = NSView(frame: view.frame)
        window.contentView = container
        container.addSubview(view)
        defer { withExtendedLifetime((window, framebuffer, delegate)) {} }
        view.mouseDown(with: try event(.leftMouseDown))
        view.removeFromSuperview()
        view.mouseDragged(with: try event(.leftMouseDragged, x: 120))
        XCTAssertEqual(pointers(connection).map(\.buttonMask), [1, 0])
        XCTAssertTrue(connection.mouseButtonState.isEmpty)
    }

    func testDragStartingOutsideContentDoesNotPressRemoteButton() throws {
        let (view, connection, framebuffer, delegate) = try fixture()
        defer { withExtendedLifetime((framebuffer, delegate)) {} }
        view.mouseDown(with: try event(.leftMouseDown, x: 5))
        view.mouseDragged(with: try event(.leftMouseDragged))
        view.mouseUp(with: try event(.leftMouseUp))
        XCTAssertTrue(pointers(connection).isEmpty)
    }
}

private final class MouseDelegate: VNCConnectionDelegate {
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
