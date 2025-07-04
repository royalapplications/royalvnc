#if canImport(IOSurface) && canImport(CoreVideo)
import Foundation
import IOSurface
import CoreVideo

public class VNCFramebufferIOSurfaceAllocator: VNCFramebufferAllocator {
    public let width: Int
    public let height: Int
    public let bytesPerPixel: Int
    public let bytesPerRow: Int
    
    var surface: IOSurface?
    
    private static let surfaceLockOptionsReadOnly: IOSurfaceLockOptions = [ .readOnly ]
    private static let surfaceLockOptionsReadWrite: IOSurfaceLockOptions = [ ]
    
    public required init(
        width: Int,
        height: Int,
        bytesPerPixel: Int,
        bytesPerRow: Int
    ) {
        self.width = width
        self.height = height
        self.bytesPerPixel = bytesPerPixel
        self.bytesPerRow = bytesPerRow
    }
    
    public func allocate(size: Int) throws -> UnsafeMutableRawPointer {
        // TODO
        let cvPixelFormat = kCVPixelFormatType_32BGRA
        
        guard let surface = IOSurface(properties: [
            .width: width,
            .height: height,
            .pixelFormat: cvPixelFormat,
            .bytesPerElement: bytesPerPixel,
            .bytesPerRow: bytesPerRow,
            .allocSize: size
        ]) else {
            throw VNCError.protocol(.framebufferFailedToCreateIOSurface)
        }
        
        self.surface = surface
        
        return surface.baseAddress
    }
    
    public func deallocate(buffer: UnsafeMutableRawPointer) {
        self.surface = nil
    }
    
    public func lockReadOnly() {
        surface?.lock(options: Self.surfaceLockOptionsReadOnly,
                      seed: nil)
    }
    
    public func unlockReadOnly() {
        surface?.unlock(options: Self.surfaceLockOptionsReadOnly,
                        seed: nil)
    }
    
    public func lockReadWrite() {
        surface?.lock(options: Self.surfaceLockOptionsReadWrite,
                      seed: nil)
    }
    
    public func unlockReadWrite() {
        surface?.unlock(options: Self.surfaceLockOptionsReadWrite,
                        seed: nil)
    }
}
#endif
