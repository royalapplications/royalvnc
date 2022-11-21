import Foundation
import AppKit

import RoyalVNCKit

class ConfigurationViewController: NSViewController {
	@IBOutlet private weak var textFieldHostname: NSTextField!
	@IBOutlet private weak var textFieldPort: NSTextField!
	
	@IBOutlet private weak var checkBoxShared: NSButton!
	@IBOutlet private weak var checkBoxClipboardRedirection: NSButton!
	@IBOutlet private weak var checkBoxScaling: NSButton!
	@IBOutlet private weak var checkBoxUseDisplayLink: NSButton!
	@IBOutlet private weak var checkBoxDebugLogging: NSButton!
	
	@IBOutlet private weak var popupButtonInputMode: NSPopUpButton!
	@IBOutlet private weak var popupButtonColorDepth: NSPopUpButton!
	@IBOutlet private weak var placeholderViewEncodings: NSView!
	
	private var didLoad = false
	private let initialSettings: VNCConnection.Settings
	private let encodingsConfigurationViewController = EncodingsConfigurationViewController(supportedFrameEncodings: .default)
	
	override var acceptsFirstResponder: Bool { true }
	
	init(settings: VNCConnection.Settings) {
		self.initialSettings = settings
		
		super.init(nibName: "ConfigurationView", bundle: .main)
	}
	
	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		guard !didLoad else { return }
		didLoad = true
		
		let encodingsConfigurationView = encodingsConfigurationViewController.view
		encodingsConfigurationView.frame = placeholderViewEncodings.bounds
		
		placeholderViewEncodings.addSubview(encodingsConfigurationView)
		
		settings = initialSettings
	}
	
	override func becomeFirstResponder() -> Bool {
		textFieldHostname.becomeFirstResponder()
	}
}

extension ConfigurationViewController {
	var settings: VNCConnection.Settings {
		get {
			.init(isDebugLoggingEnabled: isDebugLoggingEnabled,
				  hostname: hostname,
				  port: port,
				  isShared: isShared,
				  isScalingEnabled: isScalingEnabled,
				  useDisplayLink: useDisplayLink,
				  inputMode: inputMode,
				  isClipboardRedirectionEnabled: isClipboardRedirectionEnabled,
				  colorDepth: colorDepth,
				  frameEncodings: frameEncodings)
		}
		set {
			isDebugLoggingEnabled = newValue.isDebugLoggingEnabled
			hostname = newValue.hostname
			port = newValue.port
			isShared = newValue.isShared
			isScalingEnabled = newValue.isScalingEnabled
			useDisplayLink = newValue.useDisplayLink
			inputMode = newValue.inputMode
			isClipboardRedirectionEnabled = newValue.isClipboardRedirectionEnabled
			colorDepth = newValue.colorDepth
			frameEncodings = newValue.frameEncodings
		}
	}
}

private extension ConfigurationViewController {
	var isDebugLoggingEnabled: Bool {
		get { checkBoxDebugLogging.state == .on }
		set { checkBoxDebugLogging.state = newValue ? .on : .off }
	}
	
	var hostname: String {
		get { textFieldHostname.stringValue }
		set { textFieldHostname.stringValue = newValue }
	}
	
	var port: UInt16 {
		get { .init(textFieldPort.integerValue) }
		set { textFieldPort.integerValue = .init(newValue) }
	}
	
	var isShared: Bool {
		get { checkBoxShared.state == .on }
		set { checkBoxShared.state = newValue ? .on : .off }
	}
	
	var isScalingEnabled: Bool {
		get { checkBoxScaling.state == .on }
		set { checkBoxScaling.state = newValue ? .on : .off }
	}
	
	var useDisplayLink: Bool {
		get { checkBoxUseDisplayLink.state == .on }
		set { checkBoxUseDisplayLink.state = newValue ? .on : .off }
	}
	
	var inputMode: VNCConnection.Settings.InputMode {
		get { .init(rawValue: .init(popupButtonInputMode.indexOfSelectedItem)) ?? .forwardKeyboardShortcutsIfNotInUseLocally }
		set { popupButtonInputMode.selectItem(at: .init(newValue.rawValue)) }
	}
	
	var isClipboardRedirectionEnabled: Bool {
		get { checkBoxClipboardRedirection.state == .on }
		set { checkBoxClipboardRedirection.state = newValue ? .on : .off }
	}
	
	var colorDepth: VNCConnection.Settings.ColorDepth {
		get {
			switch popupButtonColorDepth.indexOfSelectedItem {
				case 0:
					return .depth8Bit
				case 1:
					return .depth16Bit
				case 2:
					return .depth24Bit
				default:
					return .depth24Bit
			}
		}
		set {
			switch newValue {
				case .depth8Bit:
					popupButtonColorDepth.selectItem(at: 0)
				case .depth16Bit:
					popupButtonColorDepth.selectItem(at: 1)
				case .depth24Bit:
					popupButtonColorDepth.selectItem(at: 2)
			}
		}
	}
	
	var frameEncodings: [VNCFrameEncodingType] {
		get { encodingsConfigurationViewController.frameEncodings }
		set { encodingsConfigurationViewController.frameEncodings = newValue }
	}
}
