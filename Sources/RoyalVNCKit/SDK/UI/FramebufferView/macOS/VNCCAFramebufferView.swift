#if os(macOS)
import Foundation
import AppKit
import Carbon

@objc(VNCCAFramebufferView)
public class VNCCAFramebufferView: NSView, VNCFramebufferView {
    @objc
	public private(set) weak var connection: VNCConnection?
	
    @objc
	public let settings: VNCConnection.Settings
	
    @objc
	public var accumulatedScrollDeltaX: CGFloat = 0
	
    @objc
	public var accumulatedScrollDeltaY: CGFloat = 0
	
    @objc
	private(set) weak var framebuffer: VNCFramebuffer?
	
    @objc
	private(set) public var framebufferSize: CGSize
	
    @objc
	private(set) public var scrollStep: CGFloat = 12
	
    @objc
	public var currentCursor: NSCursor {
		didSet {
			resetCursorRects()
		}
	}
	
    @objc
	public var scaleRatio: CGFloat {
		let containerBounds = bounds
		let fbSize = framebufferSize
		
		guard containerBounds.width > 0,
			  containerBounds.height > 0,
			  fbSize.width > 0,
			  fbSize.height > 0 else {
			return 1
		}
		
		let targetAspectRatio = containerBounds.width / containerBounds.height
		let fbAspectRatio = fbSize.width / fbSize.height
		
		let ratio: CGFloat
		
		if fbAspectRatio >= targetAspectRatio {
			ratio = containerBounds.width / framebufferSize.width
		} else {
			ratio = containerBounds.height / framebufferSize.height
		}
		
		// Only allow downscaling, no upscaling
		guard ratio < 1 else { return 1 }
		
		return ratio
	}
	
    @objc
	public var contentRect: CGRect {
		let containerBounds = bounds
		let scale = scaleRatio
		
		var rect = CGRect(x: 0, y: 0,
						  width: framebufferSize.width * scale, height: framebufferSize.height * scale)
		
		if rect.size.width < containerBounds.size.width {
			rect.origin.x = (containerBounds.size.width - rect.size.width) / 2.0
		}

		if rect.size.height < containerBounds.size.height {
			rect.origin.y = (containerBounds.size.height - rect.size.height) / 2.0
		}
		
		return rect
	}
	
    @objc
	public var lastModifierFlags: NSEvent.ModifierFlags = [ ]
	
	public override var canBecomeKeyView: Bool { true }
	public override var acceptsFirstResponder: Bool { true }
	
	private var displayLink: DisplayLink?
	private var trackingArea: NSTrackingArea?
	private var previousHotKeyMode: UnsafeMutableRawPointer?
    
    @objc
	public init(frame frameRect: CGRect,
				framebuffer: VNCFramebuffer,
				connection: VNCConnection) {
		self.framebufferSize = framebuffer.size.cgSize
		self.framebuffer = framebuffer
		self.connection = connection
		self.settings = connection.settings
		self.currentCursor = VNCCursor.empty.nsCursor
		
		super.init(frame: frameRect)
		
		wantsLayer = true
		
		guard let layer = layer else {
			fatalError("CAFramebufferView failed to get layer")
		}
		
		// Set some properties that might(!) boost performance a bit
		layer.drawsAsynchronously = true
		layer.isOpaque = true
		layer.masksToBounds = false
		layer.allowsEdgeAntialiasing = false
		layer.backgroundColor = .clear
		
		layer.contentsScale = 1
		layer.contentsGravity = .center
		layer.contentsFormat = .RGBA8Uint
		
		layer.minificationFilter = .trilinear
		layer.magnificationFilter = .trilinear
		
		frameSizeDidChange(frameRect.size)
	}
	
	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	deinit {
		removeDisplayLink()
		
		deregisterHotKeys()
	}
	
	public override func viewDidMoveToWindow() {
		addDisplayLink()
	}
	
	func removeDisplayLink() {
		guard settings.useDisplayLink else { return }
		guard let oldDisplayLink = self.displayLink else { return }
		
		oldDisplayLink.delegate = nil
		oldDisplayLink.isEnabled = false
		
		self.displayLink = nil
	}
	
	func addDisplayLink() {
		guard settings.useDisplayLink else { return }
		
		removeDisplayLink()
		
		guard let window = window,
			  let screen = window.screen ?? NSScreen.main else {
			return
		}
		
		guard let displayLink = DisplayLink(screen: screen) else {
			return
		}
		
		displayLink.delegate = self
		
		self.displayLink = displayLink
		
		displayLink.isEnabled = true
	}
	
	public override func updateTrackingAreas() {
		if let trackingArea = trackingArea {
			removeTrackingArea(trackingArea)
		}
		
		let newTrackingArea = NSTrackingArea(rect: bounds,
											 options: [ .activeInKeyWindow, .inVisibleRect, .mouseMoved ],
											 owner: self,
											 userInfo: nil)
		
		self.trackingArea = newTrackingArea
		self.addTrackingArea(newTrackingArea)
	}
    
	@discardableResult
	public override func becomeFirstResponder() -> Bool {
        if window?.isKeyWindow ?? false {
            registerHotKeys()
        }
        
        return true
    }
    
	public override func resignFirstResponder() -> Bool {
        deregisterHotKeys()
        
        return true
    }
	
	public override func resetCursorRects() {
		discardCursorRects()
		
		addCursorRect(visibleRect, cursor: currentCursor)
	}
	
	public override var frame: NSRect {
		get {
			super.frame
		}
		set {
			super.frame = newValue
			
			frameSizeDidChange(newValue.size)
		}
	}
	
	public override func mouseMoved(with event: NSEvent) { handleMouseMoved(with: event) }
	
	public override func mouseDown(with event: NSEvent) { handleMouseDown(with: event) }
	public override func mouseDragged(with event: NSEvent) { handleMouseDragged(with: event) }
	public override func mouseUp(with event: NSEvent) { handleMouseUp(with: event) }
	
	public override func rightMouseDown(with event: NSEvent) { handleRightMouseDown(with: event) }
	public override func rightMouseDragged(with event: NSEvent) { handleRightMouseDragged(with: event) }
	public override func rightMouseUp(with event: NSEvent) { handleRightMouseUp(with: event) }
	
	public override func otherMouseDown(with event: NSEvent) { handleOtherMouseDown(with: event) }
	public override func otherMouseUp(with event: NSEvent) { handleOtherMouseUp(with: event) }
	public override func otherMouseDragged(with event: NSEvent) { handleOtherMouseDragged(with: event) }
	
	public override func scrollWheel(with event: NSEvent) { handleScrollWheel(with: event) }
	
	public override func keyDown(with event: NSEvent) { handleKeyDown(with: event) }
	public override func keyUp(with event: NSEvent) { handleKeyUp(with: event) }
	public override func flagsChanged(with event: NSEvent) { handleFlagsChanged(with: event) }
	public override func performKeyEquivalent(with event: NSEvent) -> Bool { return handlePerformKeyEquivalent(with: event) }
}

extension VNCCAFramebufferView {
	public func connection(_ connection: VNCConnection,
						   framebuffer: VNCFramebuffer,
						   didUpdateRegion updatedRegion: CGRect) {
		// NOTE: If we ever take the updatedRegion into consideration, we will likely need to flip the coordinates on macOS
		
		guard !settings.useDisplayLink,
			  displayLink == nil else {
			return
		}
		
		updateImage(framebuffer.cgImage)
	}
	
	public func connection(_ connection: VNCConnection,
						   didUpdateCursor cursor: VNCCursor) {
		DispatchQueue.main.async { [weak self] in
			self?.currentCursor = cursor.nsCursor
		}
	}
}

// MARK: - Positions
private extension VNCCAFramebufferView {
	func scaledContentRelativePosition(of event: NSEvent) -> CGPoint? {
		let viewRelativePosition = viewRelativePosition(of: event)
		
		let contentRect = contentRect
		
		guard contentRect.contains(viewRelativePosition) else { return nil }
		
		let scaledPosition = CGPoint(x: (viewRelativePosition.x - contentRect.origin.x) / scaleRatio,
									 y: (viewRelativePosition.y - contentRect.origin.y) / scaleRatio)
		
		return scaledPosition
	}
	
	func viewRelativePosition(of event: NSEvent) -> CGPoint {
		var position = convert(event.locationInWindow, from: nil)
		position.y = bounds.size.height - position.y
		
		return position
	}
}

// MARK: - Mouse Input
extension VNCCAFramebufferView {
	func handleMouseMoved(with event: NSEvent) {
		guard let position = scaledContentRelativePosition(of: event) else { return }
		
		connection?.mouseMove(position)
	}
	
	func handleMouseDown(with event: NSEvent) {
		window?.makeFirstResponder(self)
		becomeFirstResponder()
		
		guard let position = scaledContentRelativePosition(of: event) else { return }
		
		connection?.mouseDown(position)
	}
	
	func handleMouseDragged(with event: NSEvent) {
		guard let position = scaledContentRelativePosition(of: event) else { return }
		
		connection?.mouseDown(position)
	}
	
	func handleMouseUp(with event: NSEvent) {
		guard let position = scaledContentRelativePosition(of: event) else { return }
		
		connection?.mouseUp(position)
	}
	
	func handleRightMouseDown(with event: NSEvent) {
		guard let position = scaledContentRelativePosition(of: event) else { return }
		
		connection?.rightMouseDown(position)
	}
	
	func handleRightMouseDragged(with event: NSEvent) {
		guard let position = scaledContentRelativePosition(of: event) else { return }
		
		connection?.rightMouseDown(position)
	}
	
	func handleRightMouseUp(with event: NSEvent) {
		guard let position = scaledContentRelativePosition(of: event) else { return }
		
		connection?.mouseUp(position)
	}
	
	func handleOtherMouseDown(with event: NSEvent) {
		guard isMiddleButton(event: event) else { return }
		
		guard let position = scaledContentRelativePosition(of: event) else { return }
		
		connection?.middleMouseDown(position)
	}
	
	func handleOtherMouseDragged(with event: NSEvent) {
		guard isMiddleButton(event: event) else { return }
		
		guard let position = scaledContentRelativePosition(of: event) else { return }
		
		connection?.middleMouseDown(position)
	}
	
	func handleOtherMouseUp(with event: NSEvent) {
		guard isMiddleButton(event: event) else { return }
		
		guard let position = scaledContentRelativePosition(of: event) else { return }
		
		connection?.mouseUp(position)
	}
	
	func handleScrollWheel(with event: NSEvent) {
		guard let position = scaledContentRelativePosition(of: event) else { return }
		
		let scrollDelta = CGPoint(x: event.scrollingDeltaX,
								  y: event.scrollingDeltaY)
		
		handleScrollWheel(scrollDelta: scrollDelta,
						  hasPreciseScrollingDeltas: event.hasPreciseScrollingDeltas,
						  mousePosition: position)
	}
	
	func isMiddleButton(event: NSEvent) -> Bool {
		let isIt = event.buttonNumber == 2
		
		return isIt
	}
}

// MARK: - Keyboard Input
extension VNCCAFramebufferView {
	func handleKey(event: NSEvent?) {
		guard let event = event else { return }
		
		if event.type == .keyDown {
			handleKeyDown(with: event)
		} else if event.type == .keyUp {
			handleKeyUp(with: event)
		}
	}
	
	func handleKeyDown(with event: NSEvent?) {
		guard let event = event,
			let connection = self.connection else {
			return
		}
		
		let keyCodes = keyCodesFrom(event: event)
		
		for keyCode in keyCodes {
			connection.keyDown(keyCode)
		}
	}
	
	func handleKeyUp(with event: NSEvent?) {
		guard let event = event,
			let connection = self.connection else {
			return
		}
		
		let keyCodes = keyCodesFrom(event: event)
		
		for keyCode in keyCodes {
			connection.keyUp(keyCode)
		}
	}
	
	func handleFlagsChanged(with event: NSEvent) {
		let currentFlags = event.modifierFlags
		let lastFlags = lastModifierFlags
		
		let modifiers = KeyboardModifiers(currentFlags: currentFlags,
										  lastFlags: lastFlags)
		
		lastModifierFlags = currentFlags
		
		let events = modifiers.events
		
		for event in events {
			handleKey(event: event)
		}
	}
	
	func handlePerformKeyEquivalent(with event: NSEvent) -> Bool {
        // swiftlint:disable:next control_statement
		guard (settings.inputMode == .forwardKeyboardShortcutsEvenIfInUseLocally || settings.inputMode == .forwardAllKeyboardShortcutsAndHotKeys),
			  let window = window,
			  (window.firstResponder == window || window.firstResponder == self) else {
			return false
		}
		
		let flags = event.modifierFlags
		
		guard flags.contains(.shift) ||
				flags.contains(.control) ||
				flags.contains(.option) ||
				flags.contains(.command) else {
			return false
		}
		
		handleKeyDown(with: event)
		handleKeyUp(with: event)
		
		return true
	}
	
	func keyCodesFrom(event: NSEvent) -> [VNCKeyCode] {
		let characters = event.charactersIgnoringModifiers
		let keyCode = CGKeyCode(event.keyCode)
		
		let keys = VNCKeyCode.keyCodesFrom(cgKeyCode: keyCode,
										   characters: characters)
		
		if keys.isEmpty {
			connection?.logger.logError("Ignoring unconvertable key press (Key Code: \(event.keyCode))")
		}
		
		return keys
	}
}

private extension VNCCAFramebufferView {
    func updateImage(_ image: CGImage?) {
        DispatchQueue.main.async { [weak self] in
            guard let self,
                  let layer = self.layer else {
                return
            }
            
            layer.contents = image
        }
    }
    
    func frameSizeDidChange(_ size: CGSize) {
        guard settings.isScalingEnabled,
              let layer = layer else {
            return
        }
        
        if frameSizeExceedsFramebufferSize(size) {
            // Don't allow upscaling
            layer.contentsGravity = .center
        } else {
            // Allow downscaling
            layer.contentsGravity = .resizeAspect
        }
    }
    
    func registerHotKeys() {
        guard settings.inputMode == .forwardAllKeyboardShortcutsAndHotKeys else {
            return
        }
        
        deregisterHotKeys()
        
        // This requires Accessibilty permissions which can be requested using `VNCAccessibilityUtils`
        self.previousHotKeyMode = PushSymbolicHotKeyMode(.init(kHIHotKeyModeAllDisabled))
    }
    
    func deregisterHotKeys() {
        if let previousHotKeyMode = previousHotKeyMode {
            PopSymbolicHotKeyMode(previousHotKeyMode)
        }
        
        self.previousHotKeyMode = nil
    }
}

extension VNCCAFramebufferView: DisplayLinkDelegate {
	func displayLinkDidUpdate(_ displayLink: DisplayLink) {
		updateImage(framebuffer?.cgImage)
	}
}
#endif
