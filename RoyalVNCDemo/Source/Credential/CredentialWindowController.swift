import Foundation
import AppKit
import RoyalVNCKit

class CredentialWindowController: NSWindowController {
	let authenticationType: VNCAuthenticationType
	
	let previousUsername: String
	let previousPassword: String
	
	private var parentWindow: NSWindow?
	private var didLoad = false
	
	@IBOutlet private weak var textFieldUsername: NSTextField!
	@IBOutlet private weak var textFieldPassword: NSSecureTextField!
	
	@IBOutlet private weak var buttonOK: NSButton!
	@IBOutlet private weak var buttonCancel: NSButton!
	
	override var windowNibName: NSNib.Name? { "CredentialWindow" }
	
	init(authenticationType: VNCAuthenticationType,
		 previousUsername: String,
		 previousPassword: String) {
		self.authenticationType = authenticationType
		
		self.previousUsername = previousUsername
		self.previousPassword = previousPassword
		
		super.init(window: nil)
	}
	
	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	// MARK: - UI Events
	override func windowDidLoad() {
		super.windowDidLoad()
		
		guard !didLoad else { return }
		didLoad = true
		
		configureUI()
	}
	
	@IBAction private func buttonOK_action(_ sender: NSButton) {
		handleButtonClicked(.OK)
	}
	
	@IBAction private func buttonCancel_action(_ sender: NSButton) {
		handleButtonClicked(.cancel)
	}
}

extension CredentialWindowController {
	func beginSheet(parentWindow: NSWindow,
					completion: @escaping (VNCCredential?) -> Void) {
		guard let window = window else {
			completion(nil)
			
			return
		}
		
		self.parentWindow = parentWindow
		
		parentWindow.beginSheet(window) { [weak self] modalResponse in
			guard let strongSelf = self,
				modalResponse == .OK else {
				completion(nil)
				
				return
			}
			
			completion(strongSelf.credential)
		}
	}
}

private extension CredentialWindowController {
	func configureUI() {
		textFieldUsername?.isEnabled = authenticationType.requiresUsername
		textFieldPassword?.isEnabled = authenticationType.requiresPassword
		
		username = previousUsername
		password = previousPassword
		
		if authenticationType.requiresUsername {
			window?.makeFirstResponder(textFieldUsername)
		} else {
			window?.makeFirstResponder(textFieldPassword)
		}
	}
	
	func handleButtonClicked(_ modalResponse: NSApplication.ModalResponse) {
		guard let parentWindow = parentWindow,
			  let window = window else {
			return
		}
		
		parentWindow.endSheet(window,
							  returnCode: modalResponse)
	}
	
	var username: String {
		get { textFieldUsername?.stringValue ?? "" }
		set { textFieldUsername?.stringValue = newValue }
	}
	
	var password: String {
		get { textFieldPassword?.stringValue ?? "" }
		set { textFieldPassword?.stringValue = newValue }
	}
	
	var credential: VNCCredential {
		if authenticationType.requiresUsername {
			return VNCUsernamePasswordCredential(username: username,
												 password: password)
		} else {
			return VNCPasswordCredential(password: password)
		}
	}
}
