import Foundation
import UIKit

import RoyalVNCKit

class CredentialViewController: UIViewController {
	var authenticationType: VNCAuthenticationType?
	
	var previousUsername: String?
	var previousPassword: String?
	
	var completion: ((_ credential: VNCCredential?) -> Void)?
	
	private var didLoad = false
	
	@IBOutlet private weak var textFieldUsername: UITextField!
	@IBOutlet private weak var textFieldPassword: UITextField!
	
	private enum Button {
		case ok
		case cancel
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		guard !didLoad else { return }
		didLoad = true
		
		configureUI()
	}
	
	@IBAction private func buttonCancel_touchUpInside(_ sender: Any) {
		handleButtonClicked(.cancel)
	}
	
	@IBAction private func buttonOK_touchUpInside(_ sender: Any) {
		handleButtonClicked(.ok)
	}
}

private extension CredentialViewController {
	func configureUI() {
		definesPresentationContext = true
		
		textFieldUsername.isEnabled = authenticationType?.requiresUsername ?? false
		textFieldPassword.isEnabled = authenticationType?.requiresPassword ?? false
		
		username = previousUsername ?? ""
		password = previousPassword ?? ""
		
		if authenticationType?.requiresUsername ?? false {
			textFieldUsername.becomeFirstResponder()
		} else {
			textFieldPassword.becomeFirstResponder()
		}
	}
	
	private func handleButtonClicked(_ button: Button) {
		dismiss(animated: true)
		
		let credential = button == .ok
			? self.credential
			: nil
		
		completion?(credential)
	}
	
	var credential: VNCCredential {
		if authenticationType?.requiresUsername ?? false {
			return VNCUsernamePasswordCredential(username: username,
												 password: password)
		} else {
			return VNCPasswordCredential(password: password)
		}
	}
	
	var username: String {
		get { textFieldUsername.text ?? "" }
		set { textFieldUsername.text = newValue }
	}
	
	var password: String {
		get { textFieldPassword.text ?? "" }
		set { textFieldPassword.text = newValue }
	}
}
