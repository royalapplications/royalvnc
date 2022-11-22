// swiftlint:disable unused_setter_value

import Foundation
import UIKit

import RoyalVNCKit

class ConfigurationViewController: UIViewController {
	@IBOutlet private weak var textFieldHostname: UITextField!
	@IBOutlet private weak var textFieldPort: UITextField!
	
	@IBOutlet private weak var switchShared: UISwitch!
	@IBOutlet private weak var switchClipboard: UISwitch!
	@IBOutlet private weak var switchScaling: UISwitch!
	@IBOutlet private weak var switchUseDisplayLink: UISwitch!
	@IBOutlet private weak var switchDebugLogging: UISwitch!
	@IBOutlet private weak var popupButtonInputMode: UIButton!
	
	@IBOutlet private weak var buttonConnect: UIButton!
	
	@IBOutlet private weak var imageViewStatus: UIImageView!
	@IBOutlet private weak var textFieldStatus: UILabel!
	
	private var connection: VNCConnection?
	
	private var credentialViewController: CredentialViewController?
	private var framebufferViewController: FramebufferViewController?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		settings = .fromUserDefaults()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		settings.saveToUserDefaults()
	}
	
	@IBAction private func buttonConnect_touchUpInside(_ sender: Any) {
		if connection != nil {
			disconnect()
		} else {
			connect()
		}
	}
}

// MARK: - Settings
private extension ConfigurationViewController {
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
	
	var isDebugLoggingEnabled: Bool {
		get { switchDebugLogging.isOn }
		set { switchDebugLogging.isOn = newValue }
	}
	
	var hostname: String {
		get { textFieldHostname.text ?? "" }
		set { textFieldHostname.text = newValue }
	}
	
	var port: UInt16 {
		get { .init(textFieldPort.text ?? "5900") ?? 5900 }
		set { textFieldPort.text = .init(newValue) }
	}
	
	var isShared: Bool {
		get { switchShared.isOn }
		set { switchShared.isOn = newValue }
	}
	
	var isScalingEnabled: Bool {
		get { switchScaling.isOn }
		set { switchScaling.isOn = newValue }
	}
	
	var useDisplayLink: Bool {
		get { switchUseDisplayLink.isOn }
		set { switchUseDisplayLink.isOn = newValue }
	}
	
	var inputMode: VNCConnection.Settings.InputMode {
		get {
			// TODO
			.forwardAllKeyboardShortcutsAndHotKeys
		}
		set {
			// TODO
		}
	}
	
	var isClipboardRedirectionEnabled: Bool {
		get { switchClipboard.isOn }
		set { switchClipboard.isOn = newValue }
	}
	
	var colorDepth: VNCConnection.Settings.ColorDepth {
		get {
			// TODO
			.depth24Bit
		}
		set {
			// TODO
		}
	}
	
	var frameEncodings: [VNCFrameEncodingType] {
		get {
			// TODO
			.default
		}
		set {
			// TODO
		}
	}
}

// MARK: - State
private extension ConfigurationViewController {
	var statusText: String {
		get { textFieldStatus.text ?? "" }
		set { textFieldStatus.text = newValue }
	}
	
	var statusImage: UIImage {
		get { imageViewStatus.image ?? UIImage(systemName: "stop")! }
		set { imageViewStatus.image = newValue }
	}
	
	var connectButtonText: String {
		get { buttonConnect.currentTitle ?? "" }
		set { buttonConnect.setTitle(newValue, for: .normal) }
	}
	
	var connectButtonIsEnabled: Bool {
		get { buttonConnect.isEnabled }
		set { buttonConnect.isEnabled = newValue }
	}
}

// MARK: - Connection
private extension ConfigurationViewController {
	func connect() {
		settings.saveToUserDefaults()
		
		destroyConnection()
		
		destroyFramebufferView()
		
		let settings = self.settings
		
		let connection = VNCConnection(settings: settings)
		connection.delegate = self
		
		self.connection = connection
		
		connection.connect()
	}
	
	func disconnect() {
		guard connection?.connectionState.status != .disconnected else { return }
		
		connection?.disconnect()
	}
	
	func destroyConnection() {
		connection?.delegate = nil
		
		connection = nil
	}
	
	func createFramebufferViewController(size: CGSize,
										 isScalingEnabled: Bool) {
		if let oldViewController = framebufferViewController {
			oldViewController.framebufferViewControllerDelegate = nil
			oldViewController.dismiss(animated: true)
		}

		framebufferViewController = nil
		
		guard let storyboard = storyboard else {
			fatalError("No storyboard")
		}

		let viewController = storyboard.caFramebufferViewController()
		// TODO: CAFramebufferViewController(frame: rect, framebufferSize: size)

		if isScalingEnabled {
			viewController.view.autoresizingMask = [
				.flexibleLeftMargin, .flexibleRightMargin,
				.flexibleTopMargin, .flexibleBottomMargin,
				.flexibleWidth, .flexibleHeight
			]
		}
		
		viewController.logger = connection?.logger
		viewController.settings = settings

		// TODO
//		if isScalingEnabled {
//			scrollView.hasVerticalScroller = false
//			scrollView.hasHorizontalScroller = false
//		} else {
//			scrollView.hasVerticalScroller = true
//			scrollView.hasHorizontalScroller = true
//		}
//
//		scrollView.documentView = view
		
		viewController.modalPresentationStyle = .overFullScreen
		viewController.modalTransitionStyle = .crossDissolve
		
		present(viewController,
				animated: true)

		viewController.framebufferViewControllerDelegate = self

		framebufferViewController = viewController
	}
	
	func destroyFramebufferView() {
		guard let framebufferViewController = framebufferViewController else { return }

		framebufferViewController.framebufferViewControllerDelegate = nil

		framebufferViewController.dismiss(animated: true)

		self.framebufferViewController = nil
	}
}

// MARK: - VNCConnectionDelegate
extension ConfigurationViewController: VNCConnectionDelegate {
	func connection(_ connection: VNCConnection,
					stateDidChange connectionState: VNCConnection.ConnectionState) {
		let statusText: String
		let statusImage: UIImage
		
		let buttonText: String
		let buttonEnabled: Bool
		
		var destroyConnection = false
		
		switch connectionState.status {
			case .connecting:
				statusText = "Connecting…"
				statusImage = .init(systemName: "shuffle")!
				
				buttonText = "Disconnect"
				buttonEnabled = true
			case .disconnecting:
				statusText = "Disconnecting…"
				statusImage = .init(systemName: "shuffle")!
				
				buttonText = "Disconnect"
				buttonEnabled = false
			case .connected:
				statusText = "Connected"
				statusImage = .init(systemName: "play")!
				
				buttonText = "Disconnect"
				buttonEnabled = true
			case .disconnected:
				destroyConnection = true
				
				if let error = connectionState.error {
					statusText = "Disconnected with Error: \(error.localizedDescription)"
					statusImage = .init(systemName: "exclamationmark.triangle")!
				} else {
					statusText = "Disconnected"
					statusImage = .init(systemName: "stop")!
				}
				
				buttonText = "Connect"
				buttonEnabled = true
		}
		
		DispatchQueue.main.async { [weak self] in
			guard let strongSelf = self else { return }
			
			strongSelf.statusImage = statusImage
			strongSelf.statusText = statusText
			
			strongSelf.connectButtonText = buttonText
			strongSelf.connectButtonIsEnabled = buttonEnabled
			
			if destroyConnection {
				strongSelf.destroyFramebufferView()
				strongSelf.destroyConnection()
			}
		}
	}
	
	func connection(_ connection: VNCConnection,
					credentialFor authenticationType: VNCAuthenticationType,
					completion: @escaping (VNCCredential?) -> Void) {
		DispatchQueue.main.async { [weak self] in
			guard let strongSelf = self,
				  let storyboard = strongSelf.storyboard else {
				completion(nil)
				
				return
			}
			
			let settings = connection.settings
			
			let viewController = storyboard.credentialViewController()
			
			viewController.authenticationType = authenticationType
			
			let cachedUsername = settings.cachedUsername
			let cachedPassword = settings.cachedPassword
			
			viewController.previousUsername = cachedUsername
			viewController.previousPassword = cachedPassword
			
			viewController.modalPresentationStyle = .overCurrentContext
			viewController.modalTransitionStyle = .crossDissolve
			
			strongSelf.credentialViewController = viewController
			
			viewController.completion = { credential in
				strongSelf.credentialViewController = nil
				
				if let credential = credential {
					if let userPassCred = credential as? VNCUsernamePasswordCredential {
						if userPassCred.username != cachedUsername {
							settings.cachedUsername = userPassCred.username
						}
						
						if userPassCred.password != cachedPassword {
							settings.cachedPassword = userPassCred.password
						}
					} else if let passCred = credential as? VNCPasswordCredential {
						if passCred.password != cachedPassword {
							settings.cachedPassword = passCred.password
						}
					}
				}
				
				completion(credential)
			}
			
			strongSelf.present(viewController,
							   animated: true)
		}
	}
	
	func connection(_ connection: VNCConnection,
					didCreateFramebuffer framebuffer: VNCFramebuffer) {
		DispatchQueue.main.async { [weak self] in
			guard let strongSelf = self else { return }
			
			strongSelf.createFramebufferViewController(size: framebuffer.size.cgSize,
													   isScalingEnabled: connection.settings.isScalingEnabled)
		}
	}
	
	func connection(_ connection: VNCConnection,
					didResizeFramebuffer framebuffer: VNCFramebuffer) {
		// TODO
	}
	
	func connection(_ connection: VNCConnection,
					framebuffer: VNCFramebuffer,
					didUpdateRegion updatedRegion: CGRect) {
		framebufferViewController?.framebuffer(framebuffer,
											   didUpdateRegion: updatedRegion)
	}
	
	func connection(_ connection: VNCConnection,
					didUpdateCursor cursor: VNCCursor) {
		// TODO: Support cursors on iOS
	}
}

// MARK: - Framebuffer View Delegate
extension ConfigurationViewController: FramebufferViewControllerDelegate {
	func framebufferViewControllerDidRequestDisconnect(_ framebufferViewController: FramebufferViewController) {
		connection?.disconnect()
	}
	
	func framebufferViewController(_ framebufferViewController: FramebufferViewController,
								   mouseDidMove mousePosition: CGPoint) {
		
	}
	
	func framebufferViewController(_ framebufferViewController: FramebufferViewController,
								   mouseDownAt mousePosition: CGPoint) {
		
	}
	
	func framebufferViewController(_ framebufferViewController: FramebufferViewController,
								   mouseUpAt mousePosition: CGPoint) {
		
	}
	
	func framebufferViewController(_ framebufferViewController: FramebufferViewController,
								   rightMouseDownAt mousePosition: CGPoint) {
		
	}
	
	func framebufferViewController(_ framebufferViewController: FramebufferViewController,
								   rightMouseUpAt mousePosition: CGPoint) {
		
	}
	
	func framebufferViewController(_ framebufferViewController: FramebufferViewController,
								   scrollDelta: CGPoint,
								   mousePosition: CGPoint) {
		
	}
	
	func framebufferViewController(_ framebufferViewController: FramebufferViewController,
								   keyDown key: VNCKeyCode) {
		connection?.keyDown(key)
	}
	
	func framebufferViewController(_ framebufferViewController: FramebufferViewController,
								   keyUp key: VNCKeyCode) {
		connection?.keyUp(key)
	}
}
