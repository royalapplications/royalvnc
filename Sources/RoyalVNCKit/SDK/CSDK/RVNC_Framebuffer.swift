#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

@_implementationOnly import RoyalVNCKitC

extension VNCFramebuffer {
    func retainedPointer() -> rvnc_framebuffer_t {
        .retainedPointerFrom(self)
    }
    
    func unretainedPointer() -> rvnc_framebuffer_t {
        .unretainedPointerFrom(self)
    }
    
    static func autoreleasePointer(_ pointer: rvnc_framebuffer_t) {
        pointer.autorelease(VNCFramebuffer.self)
    }
    
    static func fromPointer(_ pointer: rvnc_framebuffer_t) -> Self {
        pointer.unretainedInstance()
    }
}

@_cdecl("rvnc_framebuffer_size_width_get")
@_spi(RoyalVNCKitC)
@available(*, unavailable)
public func rvnc_framebuffer_size_width_get(_ framebuffer: rvnc_connection_state_t) -> UInt16 {
    VNCFramebuffer.fromPointer(framebuffer)
        .size.width
}

@_cdecl("rvnc_framebuffer_size_height_get")
@_spi(RoyalVNCKitC)
@available(*, unavailable)
public func rvnc_framebuffer_size_height_get(_ framebuffer: rvnc_connection_state_t) -> UInt16 {
    VNCFramebuffer.fromPointer(framebuffer)
        .size.height
}

@_cdecl("rvnc_framebuffer_pixel_data_get")
@_spi(RoyalVNCKitC)
@available(*, unavailable)
public func rvnc_framebuffer_pixel_data_get(_ framebuffer: rvnc_connection_state_t) -> UnsafeMutableRawPointer {
    VNCFramebuffer.fromPointer(framebuffer)
        .surfaceAddress
}
