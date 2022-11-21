import Foundation

protocol VNCFramebufferDelegate: AnyObject {
	func framebuffer(_ framebuffer: VNCFramebuffer,
					 didUpdateRegion updatedRegion: VNCRegion)
	
	func framebuffer(_ framebuffer: VNCFramebuffer,
					 didUpdateDesktopName newDesktopName: String)
	
	func framebuffer(_ framebuffer: VNCFramebuffer,
					 didUpdateCursor cursor: VNCCursor)
	
	func framebuffer(_ framebuffer: VNCFramebuffer,
					 sizeDidChange newSize: VNCSize,
					 screens newScreens: [VNCScreen])
}
