#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

public protocol VNCFramebufferAllocator {
    func allocate(size: Int) throws -> UnsafeMutableRawPointer
    func deallocate(buffer: UnsafeMutableRawPointer)
    
    func lockReadOnly()
    func unlockReadOnly()

    func lockReadWrite()
    func unlockReadWrite()
}
