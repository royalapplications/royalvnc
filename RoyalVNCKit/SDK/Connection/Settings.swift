import Foundation

public extension VNCConnection {
	@objc(VNCConnectionSettings)
	class Settings: NSObject {
		@objc
		public let isDebugLoggingEnabled: Bool
		
		@objc
		public let hostname: String
		
		@objc
		public let port: UInt16
		
		@objc
		public let isShared: Bool
		
		@objc
		public let isScalingEnabled: Bool
		
		@objc
		public let useDisplayLink: Bool
		
		@objc
		public let inputMode: InputMode
		
		@objc
		public let isClipboardRedirectionEnabled: Bool
		
		@objc
		public let colorDepth: ColorDepth
		
		public let frameEncodings: [VNCFrameEncodingType]
		
		@objc(frameEncodings)
		public var _objc_frameEncodings: [Int64] {
			frameEncodings.map({ $0.rawValue.rawValue })
		}
		
		public init(isDebugLoggingEnabled: Bool,
					hostname: String,
					port: UInt16,
					isShared: Bool,
					isScalingEnabled: Bool,
					useDisplayLink: Bool,
					inputMode: InputMode,
					isClipboardRedirectionEnabled: Bool,
					colorDepth: ColorDepth,
					frameEncodings: [VNCFrameEncodingType]) {
			self.isDebugLoggingEnabled = isDebugLoggingEnabled
			
			self.hostname = hostname
			self.port = port
			
			self.isShared = isShared
			
			self.isScalingEnabled = isScalingEnabled
			self.useDisplayLink = useDisplayLink
			
			self.inputMode = inputMode
			
			self.isClipboardRedirectionEnabled = isClipboardRedirectionEnabled
			
			self.colorDepth = colorDepth
			self.frameEncodings = frameEncodings
		}
		
		@objc
		public convenience init(isDebugLoggingEnabled: Bool,
								hostname: String,
								port: UInt16,
								isShared: Bool,
								isScalingEnabled: Bool,
								useDisplayLink: Bool,
								inputMode: InputMode,
								isClipboardRedirectionEnabled: Bool,
								colorDepth: ColorDepth,
								frameEncodings: [Int64]) {
			let frameEncodingsSwift: [VNCFrameEncodingType] = frameEncodings.compactMap({
				guard let objcFrameEncodingType = _ObjC_VNCFrameEncodingType(rawValue: $0) else { return nil }
				
				return VNCFrameEncodingType.fromObjCFrameEncodingType(objcFrameEncodingType)
			})
			
			self.init(isDebugLoggingEnabled: isDebugLoggingEnabled,
					  hostname: hostname,
					  port: port,
					  isShared: isShared,
					  isScalingEnabled: isScalingEnabled,
					  useDisplayLink: useDisplayLink,
					  inputMode: inputMode,
					  isClipboardRedirectionEnabled: isClipboardRedirectionEnabled,
					  colorDepth: colorDepth,
					  frameEncodings: frameEncodingsSwift)
		}
	}
}

public extension VNCConnection.Settings {
	@objc(VNCInputMode)
	enum InputMode: UInt32 {
		case none
		
		case forwardKeyboardShortcutsIfNotInUseLocally
		case forwardKeyboardShortcutsEvenIfInUseLocally
		case forwardAllKeyboardShortcutsAndHotKeys
	}
	
	@objc(VNCColorDepth)
	enum ColorDepth: UInt8 {
		case depth8Bit = 8   // 256 Colors
		case depth16Bit = 16
		case depth24Bit = 24
	}
}

#if os(macOS)
public extension VNCConnection.Settings.InputMode {
	var requiresAccessibilityPermissions: Bool {
		self == .forwardAllKeyboardShortcutsAndHotKeys
	}
}

@objc(VNCInputModeUtils)
// swiftlint:disable:next type_name
public class _ObjC_VNCInputModeUtils: NSObject {
	@objc
	public static func inputModeRequiresAccessibilityPermissions(_ inputMode: VNCConnection.Settings.InputMode) -> Bool {
		inputMode.requiresAccessibilityPermissions
	}
}
#endif
