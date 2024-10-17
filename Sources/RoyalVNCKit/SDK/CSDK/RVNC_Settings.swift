#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

@_implementationOnly import RoyalVNCKitC

extension VNCConnection.Settings {
    func retainedPointer() -> rvnc_settings_t {
        .retainedPointerFrom(self)
    }
    
    func unretainedPointer() -> rvnc_settings_t {
        .unretainedPointerFrom(self)
    }
    
    static func autoreleasePointer(_ pointer: rvnc_settings_t) {
        pointer.autorelease(VNCConnection.Settings.self)
    }
    
    static func fromPointer(_ pointer: rvnc_settings_t) -> Self {
        pointer.unretainedInstance()
    }
}

@_cdecl("rvnc_settings_create")
@_spi(RoyalVNCKitC)
@available(*, unavailable)
public func rvnc_settings_create(_ isDebugLoggingEnabled: Bool,
                                 _ hostname: UnsafePointer<CChar>,
                                 _ port: UInt16,
                                 _ isShared: Bool,
                                 _ isScalingEnabled: Bool,
                                 _ useDisplayLink: Bool,
                                 _ inputMode: RVNC_INPUTMODE,
                                 _ isClipboardRedirectionEnabled: Bool,
                                 _ colorDepth: RVNC_COLORDEPTH) -> rvnc_settings_t {
    let hostnameStr = String(cString: hostname)
    
    let inputModeSwift: VNCConnection.Settings.InputMode
    
    switch inputMode {
        case RVNC_INPUTMODE_NONE:
            inputModeSwift = .none
        case RVNC_INPUTMODE_FORWARDKEYBOARDSHORTCUTSIFNOTINUSELOCALLY:
            inputModeSwift = .forwardKeyboardShortcutsIfNotInUseLocally
        case RVNC_INPUTMODE_FORWARDKEYBOARDSHORTCUTSEVENIFINUSELOCALLY:
            inputModeSwift = .forwardKeyboardShortcutsEvenIfInUseLocally
        case RVNC_INPUTMODE_FORWARDALLKEYBOARDSHORTCUTSANDHOTKEYS:
            inputModeSwift = .forwardAllKeyboardShortcutsAndHotKeys
        default:
            fatalError("Invalid input mode: \(inputMode)")
    }
    
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
    
    let settings = VNCConnection.Settings(isDebugLoggingEnabled: isDebugLoggingEnabled,
                                          hostname: hostnameStr,
                                          port: port,
                                          isShared: isShared,
                                          isScalingEnabled: isScalingEnabled,
                                          useDisplayLink: useDisplayLink,
                                          inputMode: inputModeSwift,
                                          isClipboardRedirectionEnabled: isClipboardRedirectionEnabled,
                                          colorDepth: colorDepthSwift,
                                          frameEncodings: .default)
    
    return settings.retainedPointer()
}

@_cdecl("rvnc_settings_destroy")
@_spi(RoyalVNCKitC)
@available(*, unavailable)
public func rvnc_settings_destroy(_ settings: rvnc_settings_t) {
    VNCConnection.Settings.autoreleasePointer(settings)
}
