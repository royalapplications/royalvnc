import Foundation
import AppKit

import RoyalVNCKit

@main
@objc(AppDelegate)
class AppDelegate: NSObject, NSApplicationDelegate {
	@IBOutlet private weak var menuConnection: NSMenu!
	
	@IBOutlet private weak var menuItemConnectionColorDepth8Bit: NSMenuItem!
	@IBOutlet private weak var menuItemConnectionColorDepth16Bit: NSMenuItem!
	@IBOutlet private weak var menuItemConnectionColorDepth24Bit: NSMenuItem!
	
	private let configurationWindowController = ConfigurationWindowController()
	
	func applicationDidFinishLaunching(_ aNotification: Notification) {
		configurationWindowController.showWindow(self)
	}
    
    func applicationWillTerminate(_ notification: Notification) {
		configurationWindowController.saveSettings()
    }
}

extension AppDelegate: NSMenuDelegate {
	func menuNeedsUpdate(_ menu: NSMenu) {
		guard menu == menuConnection else { return }
		
		let colorDepth = configurationWindowController.colorDepthOfActiveConnection
		
		menuItemConnectionColorDepth8Bit.state = colorDepth == .depth8Bit ? .on : .off
		menuItemConnectionColorDepth16Bit.state = colorDepth == .depth16Bit ? .on : .off
		menuItemConnectionColorDepth24Bit.state = colorDepth == .depth24Bit ? .on : .off
	}
}
