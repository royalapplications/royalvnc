#if os(macOS)
import AppKit
import ObjectiveC
import XCTest

/// Redirects SDK construction to a named, disposable pasteboard. Never reads or
/// writes NSPasteboard.general. Used only by serial XCTest cases on the main thread.
final class IsolatedPasteboard {
    let pasteboard = NSPasteboard.withUniqueName()
    private let getter: Method
    private let original: IMP
    private let replacement: IMP

    init() throws {
        XCTAssertTrue(Thread.isMainThread)
        getter = try XCTUnwrap(class_getClassMethod(NSPasteboard.self, #selector(getter: NSPasteboard.general)))
        let board = pasteboard
        let block: @convention(block) (AnyObject) -> NSPasteboard = { _ in board }
        replacement = imp_implementationWithBlock(block)
        original = method_setImplementation(getter, replacement)
    }

    deinit {
        method_setImplementation(getter, original)
        imp_removeBlock(replacement)
        pasteboard.releaseGlobally()
    }
}
#endif
