#if os(macOS)
import CoreGraphics
import XCTest
@testable import RoyalVNCKit

final class VNCKeyboardLayoutTests: XCTestCase {
    func testKeyUpReleasesTheSymbolSentForKeyDown() {
        var tracker = VNCKeyEventTracker()

        let keyDown = tracker.keyDown(for: CGKeyCode(19), characters: "@")
        let repeatedKeyDown = tracker.keyDown(for: CGKeyCode(19), characters: "2")
        let keyUp = tracker.keyUp(for: CGKeyCode(19))

        XCTAssertEqual(keyDown.map(\.rawValue), [0x40])
        XCTAssertEqual(repeatedKeyDown, keyDown)
        XCTAssertEqual(keyUp, keyDown)
        XCTAssertTrue(tracker.keyUp(for: CGKeyCode(19)).isEmpty)
    }

    func testResolvedCharactersFromDifferentLayoutsMapToTheirOwnKeysyms() {
        var tracker = VNCKeyEventTracker()

        let qwertzY = tracker.keyDown(for: CGKeyCode(6), characters: "y")
        XCTAssertEqual(qwertzY.map(\.rawValue), [0x79])
        _ = tracker.keyUp(for: CGKeyCode(6))

        let swedishCharacters: [(String, UInt32)] = [("å", 0xE5), ("ä", 0xE4), ("ö", 0xF6)]
        for (character, keysym) in swedishCharacters {
            let key = tracker.keyDown(for: CGKeyCode(0xFFFF), characters: character)
            XCTAssertEqual(key.map(\.rawValue), [keysym])
            XCTAssertEqual(tracker.keyUp(for: CGKeyCode(0xFFFF)), key)
        }
    }

    func testInternationalCharactersUseValidUnicodeKeysyms() {
        var tracker = VNCKeyEventTracker()
        let characters: [(String, UInt32)] = [
            ("é", 0xE9),          // Latin-1 character used by AZERTY layouts.
            ("€", 0x010020AC),    // Unicode keysym for characters above Latin-1.
            ("日", 0x010065E5),    // CJK input.
            ("🙂", 0x0101F642)     // Supplementary-plane Unicode input.
        ]

        for (index, item) in characters.enumerated() {
            let keyCode = CGKeyCode(0xFF00 + index)
            let keyDown = tracker.keyDown(for: keyCode, characters: item.0)
            XCTAssertEqual(keyDown.map(\.rawValue), [item.1], item.0)
            XCTAssertEqual(tracker.keyUp(for: keyCode), keyDown, item.0)
        }
    }

    func testSwedishOptionTwoSendsAndReleasesBothKeys() {
        var tracker = VNCKeyEventTracker()
        let optionDown = KeyboardModifiers(currentFlags: [.leftOption], lastFlags: []).events
        XCTAssertEqual(optionDown.count, 1)
        let optionKey = optionDown[0]
        let optionKeys = tracker.keyDown(for: CGKeyCode(optionKey.keyCode),
                                         characters: optionKey.charactersIgnoringModifiers)

        let numberKeys = tracker.keyDown(for: CGKeyCode(19), characters: "2")
        let releasedNumberKeys = tracker.keyUp(for: CGKeyCode(19))

        let optionUp = KeyboardModifiers(currentFlags: [], lastFlags: [.leftOption]).events
        XCTAssertEqual(optionUp.count, 1)
        let releasedOptionKeys = tracker.keyUp(for: CGKeyCode(optionUp[0].keyCode))

        XCTAssertEqual(optionKeys.map(\.rawValue), [0xFFE9])
        XCTAssertEqual(numberKeys.map(\.rawValue), [0x32])
        XCTAssertEqual(releasedNumberKeys, numberKeys)
        XCTAssertEqual(releasedOptionKeys, optionKeys)
    }

    func testReleaseAllReturnsEveryOutstandingKeyOnce() {
        var tracker = VNCKeyEventTracker()
        _ = tracker.keyDown(for: CGKeyCode(0xFFFF), characters: "å")
        _ = tracker.keyDown(for: CGKeyCode(0xFFFE), characters: "ä")

        XCTAssertEqual(tracker.releaseAll().map(\.rawValue), [0xE4, 0xE5])
        XCTAssertTrue(tracker.releaseAll().isEmpty)
    }
}
#endif
