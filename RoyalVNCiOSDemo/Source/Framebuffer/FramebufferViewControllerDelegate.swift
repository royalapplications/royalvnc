import Foundation
import UIKit

import RoyalVNCKit

protocol FramebufferViewControllerDelegate: AnyObject {
	func framebufferViewControllerDidRequestDisconnect(_ framebufferViewController: FramebufferViewController)
	
	func framebufferViewController(_ framebufferViewController: FramebufferViewController,
						 mouseDidMove mousePosition: CGPoint)
	
	func framebufferViewController(_ framebufferViewController: FramebufferViewController,
						 mouseDownAt mousePosition: CGPoint)
	
	func framebufferViewController(_ framebufferViewController: FramebufferViewController,
						 mouseUpAt mousePosition: CGPoint)
	
	func framebufferViewController(_ framebufferViewController: FramebufferViewController,
						 rightMouseDownAt mousePosition: CGPoint)
	
	func framebufferViewController(_ framebufferViewController: FramebufferViewController,
						 rightMouseUpAt mousePosition: CGPoint)
	
	func framebufferViewController(_ framebufferViewController: FramebufferViewController,
						 scrollDelta: CGPoint,
						 mousePosition: CGPoint)
	
	func framebufferViewController(_ framebufferViewController: FramebufferViewController,
						 keyDown key: VNCKeyCode)
	
	func framebufferViewController(_ framebufferViewController: FramebufferViewController,
						 keyUp key: VNCKeyCode)
}
