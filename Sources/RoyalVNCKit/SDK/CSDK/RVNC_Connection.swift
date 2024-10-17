#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

@_implementationOnly import RoyalVNCKitC

extension VNCConnection {
    func retainedPointer() -> rvnc_connection_t {
        .retainedPointerFrom(self)
    }
    
    func unretainedPointer() -> rvnc_connection_t {
        .unretainedPointerFrom(self)
    }
    
    static func autoreleasePointer(_ pointer: rvnc_connection_t) {
        pointer.autorelease(VNCConnection.self)
    }
    
    static func fromPointer(_ pointer: rvnc_connection_t) -> Self {
        pointer.unretainedInstance()
    }
}

@_cdecl("rvnc_connection_create")
@_spi(RoyalVNCKitC)
@available(*, unavailable)
public func rvnc_connection_create(_ settings: rvnc_settings_t) -> rvnc_connection_t {
    let connection = VNCConnection(settings: .fromPointer(settings))
    
    return connection.retainedPointer()
}

@_cdecl("rvnc_connection_destroy")
@_spi(RoyalVNCKitC)
@available(*, unavailable)
public func rvnc_connection_destroy(_ connection: rvnc_connection_t) {
    VNCConnection.autoreleasePointer(connection)
}

@_cdecl("rvnc_connection_connect")
@_spi(RoyalVNCKitC)
@available(*, unavailable)
public func rvnc_connection_connect(_ connection: rvnc_connection_t) {
    VNCConnection.fromPointer(connection)
        .connect()
}

@_cdecl("rvnc_connection_disconnect")
@_spi(RoyalVNCKitC)
@available(*, unavailable)
public func rvnc_connection_disconnect(_ connection: rvnc_connection_t) {
    VNCConnection.fromPointer(connection)
        .disconnect()
}

@_cdecl("rvnc_connection_update_color_depth")
@_spi(RoyalVNCKitC)
@available(*, unavailable)
public func rvnc_connection_update_color_depth(_ connection: rvnc_connection_t,
                                               _ colorDepth: RVNC_COLORDEPTH) {
    let colorDepthSwift: VNCConnection.Settings.ColorDepth
    
    switch colorDepth {
        case RVNC_COLORDEPTH_8BIT:
            colorDepthSwift = .depth8Bit
        case RVNC_COLORDEPTH_16BIT:
            colorDepthSwift = .depth16Bit
        case RVNC_COLORDEPTH_24BIT:
            colorDepthSwift = .depth24Bit
        default:
            fatalError("Invalid color depth: \(colorDepth)")
    }
    
    VNCConnection.fromPointer(connection)
        .updateColorDepth(colorDepthSwift)
}

@_cdecl("rvnc_connection_state_get_copy")
@_spi(RoyalVNCKitC)
@available(*, unavailable)
public func rvnc_connection_state_get_copy(_ connection: rvnc_connection_t) -> rvnc_connection_state_t {
    let connectionSwift = VNCConnection.fromPointer(connection)
    let connectionState = connectionSwift.connectionState
    let connectionStateC = connectionState.retainedPointer()
    
    return connectionStateC
}

@_cdecl("rvnc_connection_framebuffer_get")
@_spi(RoyalVNCKitC)
@available(*, unavailable)
public func rvnc_connection_framebuffer_get(_ connection: rvnc_connection_t) -> rvnc_framebuffer_t? {
    let connectionSwift = VNCConnection.fromPointer(connection)
    
    guard let framebuffer = connectionSwift.framebuffer else {
        return nil
    }
    
    let framebufferC = framebuffer.unretainedPointer()
    
    return framebufferC
}

@_cdecl("rvnc_connection_mouse_move")
@_spi(RoyalVNCKitC)
@available(*, unavailable)
public func rvnc_connection_mouse_move(_ connection: rvnc_connection_t, _ x: Double, _ y: Double) {
    VNCConnection.fromPointer(connection)
        .mouseMove(x: x, y: y)
}

@_cdecl("rvnc_connection_mouse_down")
@_spi(RoyalVNCKitC)
@available(*, unavailable)
public func rvnc_connection_mouse_down(_ connection: rvnc_connection_t, _ x: Double, _ y: Double) {
    VNCConnection.fromPointer(connection)
        .mouseDown(x: x, y: y)
}

@_cdecl("rvnc_connection_right_mouse_down")
@_spi(RoyalVNCKitC)
@available(*, unavailable)
public func rvnc_connection_right_mouse_down(_ connection: rvnc_connection_t, _ x: Double, _ y: Double) {
    VNCConnection.fromPointer(connection)
        .rightMouseDown(x: x, y: y)
}

@_cdecl("rvnc_connection_middle_mouse_down")
@_spi(RoyalVNCKitC)
@available(*, unavailable)
public func rvnc_connection_middle_mouse_down(_ connection: rvnc_connection_t, _ x: Double, _ y: Double) {
    VNCConnection.fromPointer(connection)
        .middleMouseDown(x: x, y: y)
}

@_cdecl("rvnc_connection_mouse_up")
@_spi(RoyalVNCKitC)
@available(*, unavailable)
public func rvnc_connection_mouse_up(_ connection: rvnc_connection_t, _ x: Double, _ y: Double) {
    VNCConnection.fromPointer(connection)
        .mouseUp(x: x, y: y)
}

@_cdecl("rvnc_connection_mouse_wheel_up")
@_spi(RoyalVNCKitC)
@available(*, unavailable)
public func rvnc_connection_mouse_wheel_up(_ connection: rvnc_connection_t, _ x: Double, _ y: Double) {
    VNCConnection.fromPointer(connection)
        .mouseWheelUp(x: x, y: y)
}

@_cdecl("rvnc_connection_mouse_wheel_down")
@_spi(RoyalVNCKitC)
@available(*, unavailable)
public func rvnc_connection_mouse_wheel_down(_ connection: rvnc_connection_t, _ x: Double, _ y: Double) {
    VNCConnection.fromPointer(connection)
        .mouseWheelDown(x: x, y: y)
}

@_cdecl("rvnc_connection_mouse_wheel_left")
@_spi(RoyalVNCKitC)
@available(*, unavailable)
public func rvnc_connection_mouse_wheel_left(_ connection: rvnc_connection_t, _ x: Double, _ y: Double) {
    VNCConnection.fromPointer(connection)
        .mouseWheelLeft(x: x, y: y)
}

@_cdecl("rvnc_connection_mouse_wheel_right")
@_spi(RoyalVNCKitC)
@available(*, unavailable)
public func rvnc_connection_mouse_wheel_right(_ connection: rvnc_connection_t, _ x: Double, _ y: Double) {
    VNCConnection.fromPointer(connection)
        .mouseWheelRight(x: x, y: y)
}

@_cdecl("rvnc_connection_key_down")
@_spi(RoyalVNCKitC)
@available(*, unavailable)
public func rvnc_connection_key_down(_ connection: rvnc_connection_t, _ key: UInt32) {
    VNCConnection.fromPointer(connection)
        .keyDown(.init(key))
}

@_cdecl("rvnc_connection_key_up")
@_spi(RoyalVNCKitC)
@available(*, unavailable)
public func rvnc_connection_key_up(_ connection: rvnc_connection_t, _ key: UInt32) {
    VNCConnection.fromPointer(connection)
        .keyUp(.init(key))
}
