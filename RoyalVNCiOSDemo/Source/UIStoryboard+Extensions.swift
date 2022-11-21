import Foundation
import UIKit

extension UIStoryboard {
	func credentialViewController() -> CredentialViewController {
		guard let ctrl = instantiateViewController(withIdentifier: "CredentialViewController") as? CredentialViewController else {
			fatalError("Failed to instantiate view controller")
		}
		
		return ctrl
	}
	
	func caFramebufferViewController() -> CAFramebufferViewController {
		guard let ctrl = instantiateViewController(withIdentifier: "CAFramebufferViewController") as? CAFramebufferViewController else {
			fatalError("Failed to instantiate view controller")
		}
		
		return ctrl
	}
}
