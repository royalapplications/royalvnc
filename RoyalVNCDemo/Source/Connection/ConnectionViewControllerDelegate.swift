import Foundation

protocol ConnectionViewControllerDelegate: AnyObject {
	func connectionViewControllerDidDisconnect(_ connectionViewController: ConnectionViewController)
}
