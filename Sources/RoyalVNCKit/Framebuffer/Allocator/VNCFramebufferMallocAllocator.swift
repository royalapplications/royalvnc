#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

public class VNCFramebufferMallocAllocator: VNCFramebufferAllocator {
#if canImport(Glibc) || canImport(Android) || canImport(WinSDK)
    private let bufferLock = Spinlock()
#else
    private let bufferLock = NSLock()
#endif
    
    public init() { }
    
    public func allocate(size: Int) throws -> UnsafeMutableRawPointer {
        let buffer = UnsafeMutableRawPointer.allocate(byteCount: size,
                                                      alignment: MemoryLayout<UInt8>.alignment)

        buffer.initializeMemory(as: UInt8.self,
                                repeating: 0,
                                count: size)
        
        return buffer
    }
    
    public func deallocate(buffer: UnsafeMutableRawPointer) {
        buffer.deallocate()
    }
    
    public func lockReadOnly() {
        bufferLock.lock()
    }
    
    public func unlockReadOnly() {
        bufferLock.unlock()
    }
    
    public func lockReadWrite() {
        bufferLock.lock()
    }
    
    public func unlockReadWrite() {
        bufferLock.unlock()
    }
}
