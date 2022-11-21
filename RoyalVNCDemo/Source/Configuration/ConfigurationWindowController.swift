import Foundation
import AppKit

import RoyalVNCKit

class ConfigurationWindowController: NSWindowController {
	@IBOutlet private weak var viewPlaceholderConfiguration: NSView!
	@IBOutlet private weak var buttonConnect: NSButton!
	
	override var windowNibName: NSNib.Name? { "ConfigurationWindow" }
	
	private var didLoad = false
	
	private let configurationViewController = ConfigurationViewController(settings: .fromUserDefaults())
	private var connectionWindowControllers = [ConnectionWindowController]()
	
	// MARK: - UI Events
	override func windowDidLoad() {
		super.windowDidLoad()
		
		guard !didLoad else { return }
		didLoad = true
		
		configureUI()
	}
	
	@IBAction private func buttonConnect_action(_ sender: Any) {
		connect()
	}
}

extension ConfigurationWindowController {
	func saveSettings() {
		configurationViewController.settings.saveToUserDefaults()
	}
	
	var colorDepthOfActiveConnection: VNCConnection.Settings.ColorDepth? {
		guard let activeConnection = activeConnection else {
			return nil
		}
		
		guard let framebuffer = activeConnection.framebuffer else {
			return nil
		}
		
		let colorDepth = framebuffer.colorDepth
		
		return colorDepth
	}
}

private extension ConfigurationWindowController {
	func configureUI() {
		let configView = configurationViewController.view
		configView.frame = viewPlaceholderConfiguration.bounds
		configView.autoresizingMask = [ .minXMargin, .maxXMargin, .minYMargin, .maxYMargin, .width, .height ]
		
		viewPlaceholderConfiguration.addSubview(configView)
		
		window?.recalculateKeyViewLoop()
		window?.makeFirstResponder(configurationViewController)
	}
	
	func connect() {
        guard let window = window else { return }
        
		let settings = configurationViewController.settings
		settings.saveToUserDefaults()
        
		if settings.inputMode.requiresAccessibilityPermissions &&
			!VNCAccessibilityUtils.hasAccessibilityPermissions {
			// Requires accessibility permissions but don't have them right now so ask user
			
            let alert = NSAlert()
            alert.messageText = "Accessibility Permissions"
            alert.informativeText = "Accessibility Permissions are required when the input mode is set to \"Forward all keyboard shortcuts and hot keys\". To continue, please open System Settings and grant the app accessibility permissions."
            
            alert.addButton(withTitle: "Open System Settings")
			alert.addButton(withTitle: "Continue without permissions")
            alert.addButton(withTitle: "Cancel")
            
            alert.beginSheetModal(for: window) { [weak self] response in
				switch response {
					case .alertFirstButtonReturn:
						VNCAccessibilityUtils.openAccessibilityPermissionsPreferencePane()
					case .alertSecondButtonReturn:
						self?.connect(settings: settings)
					default:
						return
				}
                
            }
		} else {
			connect(settings: settings)
		}
	}
    
    func connect(settings: VNCConnection.Settings) {
        let connectionWindowController = ConnectionWindowController(settings: settings)
        connectionWindowController.delegate = self
        
        connectionWindowControllers.append(connectionWindowController)
        
        connectionWindowController.showWindow(self)
        connectionWindowController.connect()
    }
	
	var activeConnection: VNCConnection? {
		return activeConnectionWindowController?.connection
	}
	
	var activeConnectionWindowController: ConnectionWindowController? {
		guard let keyWindow = NSApplication.shared.keyWindow else {
			return nil
		}
		
		guard let keyConnectionWindowController = connectionWindowControllers.first(where: { $0.window == keyWindow }) else {
			return nil
		}
		
		return keyConnectionWindowController
	}
}

extension ConfigurationWindowController: ConnectionWindowControllerDelegate {
	func connectionWindowControllerDidClose(_ connectionWindowController: ConnectionWindowController) {
		connectionWindowController.delegate = nil
		
		connectionWindowControllers.removeAll { $0 == connectionWindowController }
	}
}
