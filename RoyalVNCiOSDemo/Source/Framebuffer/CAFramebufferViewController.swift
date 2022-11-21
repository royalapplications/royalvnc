import Foundation
import UIKit

import RoyalVNCKit

class CAFramebufferViewController: UIViewController, FramebufferViewController {
	weak var framebufferViewControllerDelegate: FramebufferViewControllerDelegate?
	
	var logger: VNCLogger?
	var settings: VNCConnection.Settings?
	
	private(set) var framebufferSize: CGSize = .zero
	
	private var didLoad = false
	
	override var canBecomeFirstResponder: Bool { return true }
	override var canResignFirstResponder: Bool { return true }
	
	private var textField = UITextField(frame: .init(x: -9999, y: -9999, width: 100, height: 20))
	
	var scaleRatio: CGFloat {
		let containerBounds = view.bounds
		let fbSize = framebufferSize
		
		guard containerBounds.width > 0,
			  containerBounds.height > 0,
			  fbSize.width > 0,
			  fbSize.height > 0 else {
			return 1
		}
		
		let targetAspectRatio = containerBounds.width / containerBounds.height
		let fbAspectRatio = fbSize.width / fbSize.height
		
		let ratio: CGFloat
		
		if fbAspectRatio >= targetAspectRatio {
			ratio = containerBounds.width / framebufferSize.width
		} else {
			ratio = containerBounds.height / framebufferSize.height
		}
		
		// Only allow downscaling, no upscaling
		guard ratio < 1 else { return 1 }
		
		return ratio
	}
	
	var contentRect: CGRect {
		let containerBounds = view.bounds
		let scale = scaleRatio
		
		var rect = CGRect(x: 0, y: 0,
						  width: framebufferSize.width * scale, height: framebufferSize.height * scale)
		
		if rect.size.width < containerBounds.size.width {
			rect.origin.x = (containerBounds.size.width - rect.size.width) / 2.0
		}

		if rect.size.height < containerBounds.size.height {
			rect.origin.y = (containerBounds.size.height - rect.size.height) / 2.0
		}
		
		return rect
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		guard !didLoad else { return }
		didLoad = true
		
		let layer = view.layer
		
		layer.contentsScale = 1
		layer.contentsGravity = .center
		layer.contentsFormat = .RGBA8Uint
		
		layer.minificationFilter = .trilinear
		layer.magnificationFilter = .trilinear
		
		textField.autocorrectionType = .no
		textField.autocapitalizationType = .none
		textField.textContentType = .none
		
		textField.delegate = self
		
		view.addSubview(textField)
		textField.becomeFirstResponder()
	}
	
	@IBAction private func buttonDisconnect_touchUpInside(_ sender: Any) {
		framebufferViewControllerDelegate?.framebufferViewControllerDidRequestDisconnect(self)
	}
}

extension CAFramebufferViewController {
	func frameSizeDidChange(_ size: CGSize) {
		guard settings?.isScalingEnabled ?? true else {
			return
		}
		
		if frameSizeExceedsFramebufferSize(size) {
			// Don't allow upscaling
			view.layer.contentsGravity = .center
		} else {
			// Allow downscaling
			view.layer.contentsGravity = .resizeAspect
		}
	}
	
	func framebuffer(_ framebuffer: VNCFramebuffer,
					 didUpdateRegion updatedRegion: CGRect) {
		let cgImage = framebuffer.cgImage
		
		DispatchQueue.main.async { [weak self] in
			guard let strongSelf = self else { return }
			
			let layer = strongSelf.view.layer
			
			layer.contents = cgImage
		}
	}
}

extension CAFramebufferViewController: UITextFieldDelegate {
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		let key = VNCKeyCode.return
		
		handleKeyPress(key)
		
		return true
	}
	
	func textFieldShouldClear(_ textField: UITextField) -> Bool {
		// TODO: Doesn't appear to do what we want
		let key = VNCKeyCode.delete
		
		handleKeyPress(key)
		
		return true
	}
	
	func textField(_ textField: UITextField,
				   shouldChangeCharactersIn range: NSRange,
				   replacementString string: String) -> Bool {
		let keys = VNCKeyCode.keyCodesFrom(characters: string)
		
		for key in keys {
			handleKeyPress(key)
		}
		
		return true
	}
}
