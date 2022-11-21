import Foundation
import AppKit

import RoyalVNCKit

class ConnectionWindowController: NSWindowController {
	override var windowNibName: NSNib.Name? { "ConnectionWindow" }
	
	let settings: VNCConnection.Settings
	weak var delegate: ConnectionWindowControllerDelegate?
	
	var connection: VNCConnection { connectionViewController.connection }
	
	private var didLoad = false
	
	private let connectionViewController: ConnectionViewController
	
	init(settings: VNCConnection.Settings) {
		self.settings = settings
		connectionViewController = .init(settings: settings)
		
		super.init(window: nil)
		
		connectionViewController.delegate = self
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	deinit {
		connectionViewController.delegate = nil
	}
	
	override func windowDidLoad() {
		guard !didLoad else { return }
		didLoad = true
		
		guard let window = window,
			  let contentView = window.contentView else {
			return
		}
		
		window.title = "Connection to \(settings.hostname)"
		
		let connectionView = connectionViewController.view
		connectionView.frame = contentView.bounds
		connectionView.autoresizingMask = [ .minXMargin, .maxXMargin, .minYMargin, .maxYMargin, .width, .height ]
		
		contentView.addSubview(connectionView)
	}
	
	func connect() {
		connectionViewController.connect()
	}
	
	func disconnect() {
		connectionViewController.disconnect()
	}
}

extension ConnectionWindowController: NSWindowDelegate {
	func windowShouldClose(_ sender: NSWindow) -> Bool {
		disconnect()
		
		return false
	}
}

extension ConnectionWindowController: ConnectionViewControllerDelegate {
	func connectionViewControllerDidDisconnect(_ connectionViewController: ConnectionViewController) {
		connectionViewController.delegate = nil
		
		close()
		
		delegate?.connectionWindowControllerDidClose(self)
	}
}
