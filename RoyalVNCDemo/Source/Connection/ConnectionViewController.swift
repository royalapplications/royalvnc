import Foundation
import AppKit

import RoyalVNCKit

class ConnectionViewController: NSViewController {
	@IBOutlet private weak var progressIndicator: NSProgressIndicator!
	@IBOutlet private weak var textFieldStatus: NSTextField!
	@IBOutlet private weak var framebufferScrollView: VNCScrollView!
	
	weak var delegate: ConnectionViewControllerDelegate?
	
	let connection: VNCConnection
	
	private var framebufferView: VNCCAFramebufferView?
	private var credentialWindowController: CredentialWindowController?
	
	init(settings: VNCConnection.Settings) {
		self.connection = .init(settings: settings)
		
		super.init(nibName: "ConnectionView", bundle: .main)
		
		self.connection.delegate = self
	}
	
	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	deinit {
		connection.delegate = nil
	}
}

extension ConnectionViewController {
	func connect() {
		connection.connect()
	}
	
	func disconnect() {
		guard connection.connectionState.status != .disconnected else { return }
		
		connection.disconnect()
	}
}

private extension ConnectionViewController {
	func showProgress(statusText: String) {
		progressIndicator.startAnimation(nil)
		progressIndicator.isHidden = false
		
		textFieldStatus.stringValue = statusText
		textFieldStatus.isHidden = false
	}
	
	func hideProgress() {
		progressIndicator.stopAnimation(nil)
		progressIndicator.isHidden = true
		
		textFieldStatus.isHidden = true
	}
	
	func createFramebufferView(connection: VNCConnection,
							   framebuffer: VNCFramebuffer) {
		createFramebufferView(connection: connection,
							  framebuffer: framebuffer,
							  in: framebufferScrollView,
							  makeFirstResponder: true)
	}
	
	@discardableResult
	func createFramebufferView(connection: VNCConnection,
							   framebuffer: VNCFramebuffer,
							   in scrollView: VNCScrollView,
							   makeFirstResponder: Bool) -> VNCFramebufferView {
		destroyFramebufferView()
		
		let isScalingEnabled = connection.settings.isScalingEnabled
		
		let viewSize = isScalingEnabled
			? scrollView.bounds.size
			: framebuffer.size.cgSize
		
		let rect = CGRect(origin: .zero,
						  size: viewSize)
		
		let view = VNCCAFramebufferView(frame: rect,
										framebuffer: framebuffer,
										connection: connection)
		
		if isScalingEnabled {
			view.autoresizingMask = [
				.minXMargin, .maxXMargin,
				.minYMargin, .maxYMargin,
				.width, .height
			]
			
			scrollView.hasVerticalScroller = false
			scrollView.hasHorizontalScroller = false
		} else {
			scrollView.hasVerticalScroller = true
			scrollView.hasHorizontalScroller = true
		}
		
		scrollView.documentView = view
		
		framebufferView = view
		
		if makeFirstResponder {
			view.window?.makeFirstResponder(view)
		}
		
		return view
	}
	
	func destroyFramebufferView() {
		guard let framebufferView = framebufferView else { return }
		
		framebufferView.removeFromSuperview()
		
		self.framebufferView = nil
	}
	
	func handleConnectionStateDidChange(_ connectionState: VNCConnection.ConnectionState) {
		let statusText: String?
		
		var didCloseConnection = false
		
		switch connectionState.status {
			case .connecting:
				statusText = "Connecting…"
			case .disconnecting:
				statusText = "Disconnecting…"
			case .connected:
				statusText = nil
			case .disconnected:
				statusText = nil
				
				didCloseConnection = true
		}
		
		if let statusText = statusText {
			showProgress(statusText: statusText)
		} else {
			hideProgress()
		}
		
		guard didCloseConnection else {
			return
		}
		
		handleConnectionDidClose(error: connectionState.error)
	}
	
	func handleConnectionDidClose(error: Error?) {
		connection.delegate = nil
		
		destroyFramebufferView()
		
		presentError(error) {
			self.delegate?.connectionViewControllerDidDisconnect(self)
		}
	}
	
	func presentError(_ error: Error?,
					  completion: @escaping () -> Void) {
		guard let error = error else {
			completion()
			
			return
		}
		
		let vncError = error as? VNCError
		let shouldDisplayError = vncError?.shouldDisplayToUser ?? true
		
		guard shouldDisplayError else {
			completion()
			
			return
		}
		
		let errorText = error.localizedDescription
		
		let alert = NSAlert()
		alert.alertStyle = .warning
		alert.messageText = "Disconnected with Error"
		alert.informativeText = errorText
		
		alert.addButton(withTitle: "OK")
		
		if let window = view.window {
			alert.beginSheetModal(for: window) { _ in
				completion()
			}
		} else {
			alert.runModal()
			
			completion()
		}
	}
	
	func credentialFor(authenticationType: VNCAuthenticationType,
					   completion: @escaping (VNCCredential?) -> Void) {
		guard let window = view.window else {
			completion(nil)
			
			return
		}
		
		let settings = connection.settings
		
		let cachedUsername = settings.cachedUsername
		let cachedPassword = settings.cachedPassword
		
		let windowController = CredentialWindowController(authenticationType: authenticationType,
														  previousUsername: cachedUsername,
														  previousPassword: cachedPassword)
		
		credentialWindowController = windowController
		
		windowController.beginSheet(parentWindow: window) { [weak self] credential in
			self?.credentialWindowController = nil
			
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
	}
}

extension ConnectionViewController {
	@IBAction private func setColorDepth8Bit(_ sender: Any) {
		connection.updateColorDepth(.depth8Bit)
	}
	
	@IBAction private func setColorDepth16Bit(_ sender: Any) {
		connection.updateColorDepth(.depth16Bit)
	}
	
	@IBAction private func setColorDepth24Bit(_ sender: Any) {
		connection.updateColorDepth(.depth24Bit)
	}
}

extension ConnectionViewController: VNCConnectionDelegate {
	func connection(_ connection: VNCConnection,
					stateDidChange connectionState: VNCConnection.ConnectionState) {
		DispatchQueue.main.async { [weak self] in
			self?.handleConnectionStateDidChange(connectionState)
		}
	}
	
	func connection(_ connection: VNCConnection,
					credentialFor authenticationType: VNCAuthenticationType,
					completion: @escaping (VNCCredential?) -> Void) {
		DispatchQueue.main.async { [weak self] in
			guard let strongSelf = self else {
				completion(nil)
				
				return
			}
			
			strongSelf.credentialFor(authenticationType: authenticationType,
									 completion: completion)
		}
	}
	
	func connection(_ connection: VNCConnection,
					didCreateFramebuffer framebuffer: VNCFramebuffer) {
		DispatchQueue.main.async { [weak self] in
			guard let strongSelf = self else { return }
			
			strongSelf.createFramebufferView(connection: connection,
											 framebuffer: framebuffer)
		}
	}
	
	func connection(_ connection: VNCConnection,
					didResizeFramebuffer framebuffer: VNCFramebuffer) {
		DispatchQueue.main.async { [weak self] in
			guard let strongSelf = self else { return }
			
			strongSelf.createFramebufferView(connection: connection,
											 framebuffer: framebuffer)
		}
	}
	
	func connection(_ connection: VNCConnection,
					framebuffer: VNCFramebuffer,
					didUpdateRegion updatedRegion: CGRect) {
		framebufferView?.connection(connection,
									framebuffer: framebuffer,
									didUpdateRegion: updatedRegion)
	}
	
	func connection(_ connection: VNCConnection,
					didUpdateCursor cursor: VNCCursor) {
		framebufferView?.connection(connection,
									didUpdateCursor: cursor)
	}
}
