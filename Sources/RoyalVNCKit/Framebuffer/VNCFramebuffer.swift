#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

#if canImport(CoreGraphics)
import CoreGraphics
#endif

#if canImport(CoreImage)
import CoreImage
#endif

#if canImport(IOSurface)
import IOSurface
#endif

#if os(macOS)
import AppKit
#endif

#if canImport(ObjectiveC)
@objc(VNCFramebuffer)
#endif
public final class VNCFramebuffer: NSObjectOrAnyObject {
	// MARK: - Public Properties
	public let size: VNCSize
	
#if canImport(CoreGraphics)
#if canImport(ObjectiveC)
	@objc(size)
#endif
	public let cgSize: CGSize
#endif
	
	public let fullRegion: VNCRegion

#if canImport(CoreGraphics)
#if canImport(ObjectiveC)
	@objc(fullRegion)
#endif
	public let cgFullRegion: CGRect
#endif

#if canImport(IOSurface)
#if canImport(ObjectiveC)
	@objc
#endif
	public let surface: IOSurface
#else
	public let buffer: UnsafeMutableRawPointer
	private let bufferLock = Spinlock()
#endif
    
    public let surfaceByteCount: Int
	
#if canImport(ObjectiveC)
	@objc
#endif
	public private(set) var screens: [VNCScreen]
	
#if canImport(ObjectiveC)
	@objc
#endif
	public var colorDepth: VNCConnection.Settings.ColorDepth {
		guard let depth = VNCConnection.Settings.ColorDepth(rawValue: .init(sourceProperties.colorDepth)) else {
			fatalError("Failed to convert color depth")
		}
		
		return depth
	}
	
	// MARK: - Internal Properties
	let sourcePixelFormat: VNCProtocol.PixelFormat
	weak var delegate: VNCFramebufferDelegate?
	let logger: VNCLogger
	
	let sourceProperties: Properties
	let destinationProperties: Properties
	
	let needsColorConversion: Bool
	
	private(set) var colorMap: ColorMap?
	
#if canImport(CoreGraphics)
	// MARK: - Private Properties
	private static let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
#endif

#if canImport(IOSurface)
	private static let surfaceLockOptionsReadOnly: IOSurfaceLockOptions = [ .readOnly ]
	private static let surfaceLockOptionsReadWrite: IOSurfaceLockOptions = [ ]
#endif
	
	private let width: Int
	private let height: Int

#if canImport(CoreImage)
	private let ciContext: CIContext
	private let ciImageOptions: [CIImageOption: Any]?
#endif

	private var framebufferHasBeenUpdatedAtLeastOnce = false
	
	init(logger: VNCLogger,
		 size: VNCSize,
		 screens: [VNCScreen],
		 pixelFormat: VNCProtocol.PixelFormat) throws {
		let width = Int(size.width)
		let height = Int(size.height)
		
		self.size = size

#if canImport(CoreGraphics)
		self.cgSize = size.cgSize
#endif
		
		self.fullRegion = .init(location: .zero, size: size)

#if canImport(CoreGraphics)
		self.cgFullRegion = .init(origin: .zero, size: size.cgSize)
#endif
		
		self.width = width
		self.height = height
		
		self.screens = screens.isEmpty
			? [ .init(id: 1, frame: .init(location: .zero, size: size)) ]
			: screens
		
		self.logger = logger
		self.sourcePixelFormat = pixelFormat
		
		let sourceProperties = Properties(pixelFormat: pixelFormat,
										  width: width)
		
		let destinationProperties = Properties.internalProperties(width: width)
		
		self.sourceProperties = sourceProperties
		self.destinationProperties = destinationProperties
		
		self.needsColorConversion = sourceProperties.bytesPerPixel != destinationProperties.bytesPerPixel ||
									sourceProperties.bitsPerPixel != destinationProperties.bitsPerPixel
		
#if canImport(CoreImage)
		self.ciContext = .init(options: [
			.allowLowPower: true,
			.outputColorSpace: Self.rgbColorSpace,
			.outputPremultiplied: false
		])
		
		self.ciImageOptions = [
			.colorSpace: Self.rgbColorSpace
		]
#endif
		
		let bufferLength = width * height * destinationProperties.bytesPerPixel
        
        self.surfaceByteCount = bufferLength
		
#if canImport(IOSurface)
		let cvPixelFormat = kCVPixelFormatType_32BGRA
		
		guard let surface = IOSurface(properties: [
			.width: width,
			.height: height,
			.pixelFormat: cvPixelFormat,
			.bytesPerElement: destinationProperties.bytesPerPixel,
			.bytesPerRow: destinationProperties.bytesPerRow,
			.allocSize: bufferLength
		]) else {
			throw VNCError.protocol(.framebufferFailedToCreateIOSurface)
		}
		
		self.surface = surface
#else
		let buffer = UnsafeMutableRawPointer.allocate(byteCount: bufferLength,
                                                      alignment: MemoryLayout<UInt8>.alignment)

		buffer.initializeMemory(as: UInt8.self, 
								repeating: 0,
								count: bufferLength)

		self.buffer = buffer
#endif
	}

	deinit {
#if !canImport(IOSurface)
		self.buffer.deallocate()
#endif
	}
}

// MARK: - Public APIs
public extension VNCFramebuffer {
#if canImport(CoreImage)
#if canImport(ObjectiveC)
	@objc
#endif
	var ciImage: CIImage? {
		guard framebufferHasBeenUpdatedAtLeastOnce else {
			return nil
		}
		
		lockSurfaceReadOnly()
		defer { unlockSurfaceReadOnly() }
		
		let image = CIImage(ioSurface: surface,
							options: ciImageOptions)
		
		return image
	}
#endif

#if canImport(CoreImage)
#if canImport(ObjectiveC)
	@objc
#endif
	var cgImage: CGImage? {
		guard let ciImage = ciImage else {
			return nil
		}
		
		guard let finalImage = ciContext.createCGImage(ciImage,
                                                       from: ciImage.extent,
                                                       format: .BGRA8,
                                                       colorSpace: Self.rgbColorSpace,
                                                       deferred: true) else {
			return nil
		}
		
//		logger.logDebug("CGImage.alphaInfo: \(finalImage.alphaInfo.rawValue)")
		
		return finalImage
	}
#endif
	
#if os(macOS)
    @objc
    var nsImage: NSImage? {
        guard let ciImage = ciImage else {
            return nil
        }
        
        let rep = NSCIImageRep(ciImage: ciImage)
        
        let finalImage = NSImage(size: rep.size)
        finalImage.addRepresentation(rep)
        
        return finalImage
    }
#endif
}

// MARK: - Internal API
extension VNCFramebuffer {
	func update(region: VNCRegion,
				data: inout Data) {
		logger.logDebug("Framebuffer Update Region \(region)")
		
		guard isValidRegion(region) else {
			logger.logError("Invalid region: \(region)")
			
			return
		}
		
		lockSurfaceReadWrite()
		updatePixelBufferWithData(&data, forRegion: region)
		unlockSurfaceReadWrite()
	}
	
	func copy(region sourceRegion: VNCRegion,
			  to destinationRegion: VNCRegion) {
		logger.logDebug("Framebuffer Copy Region \(sourceRegion) to \(destinationRegion)")
		
		guard isValidRegion(sourceRegion) else {
			logger.logError("Invalid region: \(sourceRegion)")
			
			return
		}
		
		guard isValidRegion(destinationRegion) else {
			logger.logError("Invalid region: \(destinationRegion)")
			
			return
		}
		
		lockSurfaceReadWrite()
		copyPixelBufferRegion(sourceRegion, to: destinationRegion)
		unlockSurfaceReadWrite()
	}
	
	func fill(region: VNCRegion,
			  withPixel pixelData: inout Data) {
		logger.logDebug("Framebuffer Fill Region \(region)")
		
		guard isValidRegion(region) else {
			logger.logError("Invalid region: \(region)")
			
			return
		}
		
		lockSurfaceReadWrite()
		fillPixelBufferWithPixel(&pixelData, forRegion: region)
		unlockSurfaceReadWrite()
	}
	
	func updateColorMap(_ entries: VNCProtocol.SetColourMapEntries) {
		let colorMap = ColorMap(entries: entries)
		
		self.colorMap = colorMap
	}
	
	func decodeCursor(image: inout Data,
					  mask: inout Data,
					  size: VNCSize,
					  hotspot: VNCPoint) -> VNCCursor {
		let destinationBitsPerPixel = destinationProperties.bitsPerPixel
		let destinationBytesPerPixel = destinationProperties.bytesPerPixel
		
		let bitsPerComponent = Int(8)
		
		let cursorWidth = Int(size.width)
		let cursorHeight = Int(size.height)
		
		let destinationLength = cursorWidth * cursorHeight * destinationBytesPerPixel
		let destinationMaxAlpha = UInt8(destinationProperties.alphaMax)
		
		// Decode to RGBA
		var destinationData = Data(repeating: 0, count: destinationLength)

		var fullyTransparent = true
		
		image.withUnsafeBytes { sourcePixelDataPtr in
			for row in 0..<cursorHeight {
				let sourceRowOffset = sourceOffsetOf(row: row, width: cursorWidth)
				let destinationRowOffset = destinationOffsetOf(row: row, width: cursorWidth)
				
				for column in 0..<cursorWidth {
					let sourceColumnOffset = sourceOffsetOf(column: column)
					let destinationColumnOffset = destinationOffsetOf(column: column)
					
					let sourceOffset = sourceRowOffset + sourceColumnOffset
					let destinationOffset = destinationRowOffset + destinationColumnOffset
					
					let destinationPixel = destinationPixelWith(sourcePixelData: sourcePixelDataPtr,
																sourcePixelDataOffset: sourceOffset)
					
                    let maskIdx = row * Int((Double(cursorWidth) / 8.0).rounded(.up)) + Int((Double(column) / 8.0).rounded(.down))
					
					let destinationAlpha: UInt8 = (mask[maskIdx] << (column % 8)) & 0x80 != 0
						? destinationMaxAlpha
						: 0

					destinationData[destinationOffset + 0] = destinationPixel.red
					destinationData[destinationOffset + 1] = destinationPixel.green
					destinationData[destinationOffset + 2] = destinationPixel.blue
					destinationData[destinationOffset + 3] = destinationAlpha
					
					if fullyTransparent && destinationAlpha > 0 {
						fullyTransparent = false
					}
				}
			}
		}
		
		guard !fullyTransparent else {
			return .empty
		}
		
		return .init(imageData: destinationData,
					 size: size,
					 hotspot: hotspot,
					 bitsPerComponent: bitsPerComponent,
					 bitsPerPixel: destinationBitsPerPixel,
					 bytesPerPixel: destinationBytesPerPixel)
	}
	
	func didUpdate() {
		notifyDelegateFramebufferDidUpdate()
	}
	
	func didUpdate(region: VNCRegion) {
		notifyDelegateFramebufferDidUpdate(region: region)
	}
	
	func updateDesktopName(_ newDesktopName: String) {
		notifyDelegateDesktopNameDidUpdate(newDesktopName)
	}
	
	func updateCursor(_ cursor: VNCCursor) {
		notifyDelegateCursorDidUpdate(cursor)
	}
	
	func resize(to newSize: VNCSize) {
		let newScreens: [VNCScreen] = [
			.init(id: 0,
				  frame: .init(location: .zero, size: newSize))
		]
		
		resize(to: newSize,
			   screens: newScreens)
	}
	
	func resize(to newSize: VNCSize,
				screens newScreens: [VNCProtocol.Screen]) {
		let newVNCScreens = newScreens.map({ VNCScreen(screen: $0) })
		
		resize(to: newSize,
			   screens: newVNCScreens)
	}
	
	func resize(to newSize: VNCSize,
				screens newScreens: [VNCScreen]) {
		let sizeDidChange = newSize != size
		let screensDidChange = newScreens != screens
		
		guard sizeDidChange || screensDidChange else {
			// If the framebuffer size and screens are the same as before, there's nothing to do
			return
		}
		
		logger.logInfo("Desktop Size changed to \(newSize), number of screens: \(newScreens.count)")
		
		notifyDelegateSizeDidChange(newSize,
									screens: newScreens)
	}
}

// MARK: - Update Framebuffer
private extension VNCFramebuffer {
	func updatePixelBufferWithData(_ data: inout Data,
								   forRegion region: VNCRegion) {
		guard width > 0,
			  height > 0,
			  region.size.width > 0,
			  region.size.height > 0 else {
			// Nothing to do for empty rect
			return
		}
		
		let frameBufferWidth = width
		
		let regionWidth = Int(region.size.width)
		let regionHeight = Int(region.size.height)
		
		let regionX = Int(region.location.x)
		let regionY = Int(region.location.y)
        
		let sourceBytesPerPixel = sourceProperties.bytesPerPixel
		let destinationBytesPerPixel = destinationProperties.bytesPerPixel
		
		let needsColorConversion = self.needsColorConversion
		let logger = self.logger
        
		let fixedAlpha = UInt8(destinationProperties.alphaMax)
		let alphaOffset = destinationBytesPerPixel - 1
		
		let sourceColumnLength = regionWidth * sourceBytesPerPixel
		let destinationColumnLength = regionWidth * destinationBytesPerPixel
		
        let targetBase = surfaceAddress
		
		data.withUnsafeBytes { sourcePixelDataPtr in
			for row in 0..<regionHeight {
				let sourceRowOffset = sourceOffsetOf(row: row, width: regionWidth)
				let destinationRowOffset = destinationOffsetOf(row: row + regionY, width: frameBufferWidth)
				
				if !needsColorConversion { // Fast Path
					let sourceColumnOffsetStart = sourceOffsetOf(column: 0)
					let destinationColumnOffsetStart = destinationOffsetOf(column: 0 + regionX)
					
					let sourceOffset = sourceRowOffset + sourceColumnOffsetStart
					let destinationOffset = destinationRowOffset + destinationColumnOffsetStart
					
					guard let source = sourcePixelDataPtr.baseAddress?.advanced(by: sourceOffset) else {
						logger.logError("Failed to get baseAddress of data to update framebuffer with")
						
						return
					}
					
					let target = targetBase.advanced(by: destinationOffset)
					
					target.copyMemory(from: source,
									  byteCount: sourceColumnLength)
					
					let targetArr = target.assumingMemoryBound(to: UInt8.self)
                    
                    var idx = alphaOffset
                    
                    while idx < destinationColumnLength {
                        targetArr[idx] = fixedAlpha
                        
                        idx += destinationBytesPerPixel
                    }
				} else { // Slow Path
					for column in 0..<regionWidth {
						let sourceColumnOffset = sourceOffsetOf(column: column)
						let destinationColumnOffset = destinationOffsetOf(column: column + regionX)
						
						let sourceOffset = sourceRowOffset + sourceColumnOffset
						let destinationOffset = destinationRowOffset + destinationColumnOffset
						
						let destinationPixel = destinationPixelWith(sourcePixelData: sourcePixelDataPtr,
																	sourcePixelDataOffset: sourceOffset)
						
						let target = targetBase.advanced(by: destinationOffset).assumingMemoryBound(to: UInt8.self)

						target[0] = destinationPixel.blue
						target[1] = destinationPixel.green
						target[2] = destinationPixel.red
						target[3] = fixedAlpha
					}
				}
			}
		}
		
		if !framebufferHasBeenUpdatedAtLeastOnce {
			framebufferHasBeenUpdatedAtLeastOnce = true
		}
	}
	
	func fillPixelBufferWithPixel(_ pixelData: inout Data,
								  forRegion region: VNCRegion) {
		guard width > 0,
			  height > 0,
			  region.size.width > 0,
			  region.size.height > 0 else {
			// Nothing to do for empty rect
			return
		}
		
		let sourceBytesPerPixel = sourceProperties.bytesPerPixel
		let destinationBytesPerPixel = destinationProperties.bytesPerPixel
		
#if DEBUG
        guard pixelData.count == sourceBytesPerPixel else {
            return
        }
#endif
        
        let fixedAlpha = UInt8(destinationProperties.alphaMax)
		
		let frameBufferWidth = width
		
		let regionWidth = Int(region.size.width)
		let regionHeight = Int(region.size.height)
		
		let regionX = Int(region.location.x)
		let regionY = Int(region.location.y)
		
		let destinationColumnLength = regionWidth * destinationBytesPerPixel
		
		let destinationPixelData: Data
		
		if !needsColorConversion { // Fast Path
			destinationPixelData = .init([
				pixelData[0],
				pixelData[1],
				pixelData[2],
				fixedAlpha
			])
		} else { // Slow Path
			destinationPixelData = pixelData.withUnsafeBytes { sourcePixelDataPtr in
				let destinationPixel = destinationPixelWith(sourcePixelData: sourcePixelDataPtr,
															sourcePixelDataOffset: 0)
				
				return .init([
					destinationPixel.blue,
					destinationPixel.green,
					destinationPixel.red,
					fixedAlpha
				])
			}
		}
		
		let targetBase = surfaceAddress
		
		destinationPixelData.withUnsafeBytes { destinationPixelDataBytesPtr in
			guard let destinationPixelDataBytes = destinationPixelDataBytesPtr.baseAddress else { return }
			
			for row in 0..<regionHeight {
				let destinationRowOffset = destinationOffsetOf(row: row + regionY, width: frameBufferWidth)
				let destinationColumnOffsetStart = destinationOffsetOf(column: 0 + regionX)
				
				let destinationOffset = destinationRowOffset + destinationColumnOffsetStart
				
                var idx = destinationOffset
                
                while idx < destinationOffset + destinationColumnLength {
                    let target = targetBase.advanced(by: idx)
                    
                    target.copyMemory(from: destinationPixelDataBytes,
                                      byteCount: destinationBytesPerPixel)
                    
                    idx += destinationBytesPerPixel
                }
			}
		}
		
		if !framebufferHasBeenUpdatedAtLeastOnce {
			framebufferHasBeenUpdatedAtLeastOnce = true
		}
	}
    
    func copyPixelBufferRegion(_ sourceRegion: VNCRegion,
                              to destinationRegion: VNCRegion) {
		guard width > 0,
			  height > 0,
			  sourceRegion.size.width > 0,
			  sourceRegion.size.height > 0 else {
			// Nothing to do for empty rect
			return
		}
		
		var data = bufferData(ofRegion: sourceRegion)
		
		updatePixelBufferWithData(&data,
								  forRegion: destinationRegion)
    }
	
	func bufferData(ofRegion region: VNCRegion) -> Data {
		let frameBufferWidth = width
		
		let regionWidth = Int(region.size.width)
		let regionHeight = Int(region.size.height)
		
		let regionX = Int(region.location.x)
		let regionY = Int(region.location.y)
		
		let buffer = surfaceAddress.assumingMemoryBound(to: UInt8.self)
		
		let bytesPerPixel = destinationProperties.bytesPerPixel
		
		let dataLength = regionWidth * regionHeight * bytesPerPixel
		var data = Data(count: dataLength)
		
		let columnLength = regionWidth * bytesPerPixel
		
		let logger = self.logger
		
		data.withUnsafeMutableBytes {
			guard let targetBase = $0.baseAddress else {
				logger.logError("Failed to get baseAddress of target data to store framebuffer data in")
				
				return
			}
			
			var idx = 0
			
			for row in regionY..<regionY + regionHeight {
				let rowOffset = destinationOffsetOf(row: row, width: frameBufferWidth)
				
				let columnOffsetStart = destinationOffsetOf(column: regionX)
				let offset = rowOffset + columnOffsetStart
				
				let source = buffer.advanced(by: offset)
				let target = targetBase.advanced(by: idx)
				
				target.copyMemory(from: source,
								  byteCount: columnLength)
				
				idx += columnLength
			}
		}
		
		return data
	}
}

// MARK: Color/Pixel conversions
private extension VNCFramebuffer {
	func destinationPixelWith(sourcePixelData: UnsafeRawBufferPointer,
							  sourcePixelDataOffset: Int) -> LocalPixel {
        PixelUtils.destinationPixelWith(sourcePixelData: sourcePixelData,
                                        sourcePixelDataOffset: sourcePixelDataOffset,
                                        sourceProperties: sourceProperties,
                                        destinationProperties: destinationProperties,
                                        colorMap: colorMap)
    }
}

// MARK: - Source Offsets
private extension VNCFramebuffer {
	func sourceOffsetOf(row: Int,
						width: Int) -> Int {
		PixelUtils.offsetOf(row: row,
							width: width,
							bytesPerPixel: sourceProperties.bytesPerPixel)
	}
	
	func sourceOffsetOf(column: Int) -> Int {
		PixelUtils.offsetOf(column: column,
							bytesPerPixel: sourceProperties.bytesPerPixel)
	}
	
	func sourceOffsetOf(point: VNCPoint) -> Int {
		PixelUtils.offsetOf(point: point,
							bytesPerRow: sourceProperties.bytesPerRow,
							bitsPerPixel: sourceProperties.bitsPerPixel)
	}
}

// MARK: - Destination Offsets
private extension VNCFramebuffer {
    func destinationOffsetOf(row: Int,
							 width: Int) -> Int {
		PixelUtils.offsetOf(row: row,
							width: width,
							bytesPerPixel: destinationProperties.bytesPerPixel)
    }
    
    func destinationOffsetOf(column: Int) -> Int {
		PixelUtils.offsetOf(column: column,
							bytesPerPixel: destinationProperties.bytesPerPixel)
    }
    
    func destinationOffsetOf(point: VNCPoint) -> Int {
		PixelUtils.offsetOf(point: point,
							bytesPerRow: destinationProperties.bytesPerRow,
							bitsPerPixel: destinationProperties.bitsPerPixel)
    }
}

// MARK: - Surface Access
extension VNCFramebuffer {
    var surfaceAddress: UnsafeMutableRawPointer {
#if canImport(IOSurface)
        surface.baseAddress
#else
        buffer
#endif
    }
}

extension VNCFramebuffer {
    func copyPixelDataToRGBA32(pixelDataSize: inout Int) -> UnsafeMutableRawPointer {
        lockSurfaceReadOnly()
        defer { unlockSurfaceReadOnly() }
        
        pixelDataSize = surfaceByteCount
        
        let rgbaDataCopy = Self.copyBGRAtoRGBA(surfaceAddress,
                                               byteCount: pixelDataSize)
        
        return rgbaDataCopy
    }
    
    func destroyRGBA32PixelData(_ buffer: UnsafeMutableRawPointer) {
        buffer.deallocate()
    }
    
    private static func copyBGRAtoRGBA(_ srcBuffer: UnsafeRawPointer,
                                       byteCount: Int) -> UnsafeMutableRawPointer {
        let dstBuffer = UnsafeMutableRawPointer.allocate(byteCount: byteCount,
                                                         alignment: MemoryLayout<UInt8>.alignment)
        
        let src = srcBuffer.assumingMemoryBound(to: UInt8.self)
        let dst = dstBuffer.assumingMemoryBound(to: UInt8.self)
        
        let pixelCount = byteCount / 4
        var i = 0
        
        while i < pixelCount {
            let b = src[i * 4]
            let g = src[i * 4 + 1]
            let r = src[i * 4 + 2]
            let a = src[i * 4 + 3]
            
            dst[i * 4] = r
            dst[i * 4 + 1] = g
            dst[i * 4 + 2] = b
            dst[i * 4 + 3] = a
            
            i += 1
        }
        
        return dstBuffer
    }
}

private extension VNCFramebuffer {
	func lockSurfaceReadOnly() {
#if canImport(IOSurface)
		surface.lock(options: Self.surfaceLockOptionsReadOnly, seed: nil)
#else
		bufferLock.lock()
#endif
	}
	
	func unlockSurfaceReadOnly() {
#if canImport(IOSurface)
		surface.unlock(options: Self.surfaceLockOptionsReadOnly, seed: nil)
#else
		bufferLock.unlock()
#endif
	}
	
	func lockSurfaceReadWrite() {
#if canImport(IOSurface)
		surface.lock(options: Self.surfaceLockOptionsReadWrite, seed: nil)
#else
		bufferLock.lock()
#endif
	}
	
	func unlockSurfaceReadWrite() {
#if canImport(IOSurface)
		surface.unlock(options: Self.surfaceLockOptionsReadWrite, seed: nil)
#else
		bufferLock.unlock()
#endif
	}
}

// MARK: - Validation
private extension VNCFramebuffer {
	func isValidRegion(_ region: VNCRegion) -> Bool {
		let regionX = Int(region.x)
		let regionY = Int(region.y)
		let regionWidth = Int(region.width)
		let regionHeight = Int(region.height)
		
		guard regionX >= 0,
			  regionY >= 0,
			  regionWidth >= 1,
			  regionHeight >= 1,
			  regionX + regionWidth <= width,
			  regionY + regionHeight <= height else {
			return false
		}
		
		return true
	}
}

// MARK: - Delegate Notifications
private extension VNCFramebuffer {
	func notifyDelegateFramebufferDidUpdate() {
		delegate?.framebuffer(self,
							  didUpdateRegion: fullRegion)
	}
	
	func notifyDelegateFramebufferDidUpdate(region: VNCRegion) {
		delegate?.framebuffer(self,
							  didUpdateRegion: region)
	}
	
	func notifyDelegateDesktopNameDidUpdate(_ newDesktopName: String) {
		delegate?.framebuffer(self,
							  didUpdateDesktopName: newDesktopName)
	}
	
	func notifyDelegateCursorDidUpdate(_ cursor: VNCCursor) {
		delegate?.framebuffer(self,
							  didUpdateCursor: cursor)
	}
	
	func notifyDelegateSizeDidChange(_ newSize: VNCSize,
									 screens newScreens: [VNCScreen]) {
		delegate?.framebuffer(self,
							  sizeDidChange: newSize,
							  screens: newScreens)
	}
}

/*
// MARK: - Debug API
extension VNCFramebuffer {
	// Write the raw data buffers to disk for verification purposes
	// The file name is of the format /tmp/framebuffer-{width}x{height}x{bytesPerPixel}.{timestamp}.raw
	// The file can be converted to a png using Imagemagick
	// > convert -size {width}x{height} -depth 8 BGRA:{filename} {output}.png
	func writeSurface() throws {
		lockSurfaceReadOnly()
		
		let url = URL(filePath: "/tmp/framebuffer-\(width)x\(height)x\(destinationProperties.bytesPerPixel).\(Int(Date().timeIntervalSince1970)).raw")
		let data = Data(bytes: buffer, count: width * height * destinationProperties.bytesPerPixel)
		try data.write(to: url)

		unlockSurfaceReadOnly()
	}
}
*/
