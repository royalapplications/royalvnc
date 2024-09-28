// This is hacky, but I currently don't have a better idea on how to handle this for ObjC

import Foundation

#if canImport(ObjectiveC)
@objc(VNCKeyCode)
#endif
// swiftlint:disable:next type_name
public class _ObjC_VNCKeyCode: NSObject {
	// Must be kept in Sync with VNCKeyCode!
	
#if canImport(ObjectiveC)
    @objc
#endif
    public static let shift = X11KeySymbols.XK_Shift_L
#if canImport(ObjectiveC)
    @objc
#endif
    public static let rightShift = X11KeySymbols.XK_Shift_R
	
#if canImport(ObjectiveC)
    @objc
#endif
    public static let control = X11KeySymbols.XK_Control_L
#if canImport(ObjectiveC)
    @objc
#endif
    public static let rightControl = X11KeySymbols.XK_Control_R
	
#if canImport(ObjectiveC)
    @objc
#endif
    public static let option = X11KeySymbols.XK_Alt_L
#if canImport(ObjectiveC)
    @objc
#endif
    public static let optionForARD = X11KeySymbols.XK_Meta_L
#if canImport(ObjectiveC)
    @objc
#endif
    public static let rightOption = X11KeySymbols.XK_Alt_R
#if canImport(ObjectiveC)
    @objc
#endif
    public static let rightOptionForARD = X11KeySymbols.XK_Meta_R
	
#if canImport(ObjectiveC)
    @objc
#endif
    public static let command = X11KeySymbols.XK_Super_L
#if canImport(ObjectiveC)
    @objc
#endif
    public static let commandForARD = X11KeySymbols.XK_Hyper_L
#if canImport(ObjectiveC)
    @objc
#endif
    public static let rightCommand = X11KeySymbols.XK_Super_R
#if canImport(ObjectiveC)
    @objc
#endif
    public static let rightCommandForARD = X11KeySymbols.XK_Hyper_R
	
#if canImport(ObjectiveC)
    @objc
#endif
    public static let `return` = X11KeySymbols.XK_Return
#if canImport(ObjectiveC)
    @objc
#endif
    public static let forwardDelete = X11KeySymbols.XK_Delete
#if canImport(ObjectiveC)
    @objc
#endif
    public static let space = X11KeySymbols.XK_space
#if canImport(ObjectiveC)
    @objc
#endif
    public static let delete = X11KeySymbols.XK_BackSpace
#if canImport(ObjectiveC)
    @objc
#endif
    public static let tab = X11KeySymbols.XK_Tab
#if canImport(ObjectiveC)
    @objc
#endif
    public static let escape = X11KeySymbols.XK_Escape
#if canImport(ObjectiveC)
    @objc
#endif
    public static let leftArrow = X11KeySymbols.XK_Left
#if canImport(ObjectiveC)
    @objc
#endif
    public static let upArrow = X11KeySymbols.XK_Up
#if canImport(ObjectiveC)
    @objc
#endif
    public static let rightArrow = X11KeySymbols.XK_Right
#if canImport(ObjectiveC)
    @objc
#endif
    public static let downArrow = X11KeySymbols.XK_Down
#if canImport(ObjectiveC)
    @objc
#endif
    public static let pageUp = X11KeySymbols.XK_Page_Up
#if canImport(ObjectiveC)
    @objc
#endif
    public static let pageDown = X11KeySymbols.XK_Page_Down
#if canImport(ObjectiveC)
    @objc
#endif
    public static let end = X11KeySymbols.XK_End
#if canImport(ObjectiveC)
    @objc
#endif
    public static let home = X11KeySymbols.XK_Home
#if canImport(ObjectiveC)
    @objc
#endif
    public static let insert = X11KeySymbols.XK_Insert
	
#if canImport(ObjectiveC)
    @objc
#endif
    public static let ansiKeypadClear = X11KeySymbols.XK_Clear
#if canImport(ObjectiveC)
    @objc
#endif
    public static let ansiKeypadEquals = X11KeySymbols.XK_KP_Equal
#if canImport(ObjectiveC)
    @objc
#endif
    public static let ansiKeypadDivide = X11KeySymbols.XK_KP_Divide
#if canImport(ObjectiveC)
    @objc
#endif
    public static let ansiKeypadMultiply = X11KeySymbols.XK_KP_Multiply
#if canImport(ObjectiveC)
    @objc
#endif
    public static let ansiKeypadMinus = X11KeySymbols.XK_KP_Subtract
#if canImport(ObjectiveC)
    @objc
#endif
    public static let ansiKeypadPlus = X11KeySymbols.XK_KP_Add
#if canImport(ObjectiveC)
    @objc
#endif
    public static let ansiKeypadEnter = X11KeySymbols.XK_KP_Enter
#if canImport(ObjectiveC)
    @objc
#endif
    public static let ansiKeypadDecimal = X11KeySymbols.XK_KP_Separator
	
#if canImport(ObjectiveC)
    @objc
#endif
    public static let f1 = X11KeySymbols.XK_F1
#if canImport(ObjectiveC)
    @objc
#endif
    public static let f2 = X11KeySymbols.XK_F2
#if canImport(ObjectiveC)
    @objc
#endif
    public static let f3 = X11KeySymbols.XK_F3
#if canImport(ObjectiveC)
    @objc
#endif
    public static let f4 = X11KeySymbols.XK_F4
#if canImport(ObjectiveC)
    @objc
#endif
    public static let f5 = X11KeySymbols.XK_F5
#if canImport(ObjectiveC)
    @objc
#endif
    public static let f6 = X11KeySymbols.XK_F6
#if canImport(ObjectiveC)
    @objc
#endif
    public static let f7 = X11KeySymbols.XK_F7
#if canImport(ObjectiveC)
    @objc
#endif
    public static let f8 = X11KeySymbols.XK_F8
#if canImport(ObjectiveC)
    @objc
#endif
    public static let f9 = X11KeySymbols.XK_F9
#if canImport(ObjectiveC)
    @objc
#endif
    public static let f10 = X11KeySymbols.XK_F10
#if canImport(ObjectiveC)
    @objc
#endif
    public static let f11 = X11KeySymbols.XK_F11
#if canImport(ObjectiveC)
    @objc
#endif
    public static let f12 = X11KeySymbols.XK_F12
#if canImport(ObjectiveC)
    @objc
#endif
    public static let f13 = X11KeySymbols.XK_F13
#if canImport(ObjectiveC)
    @objc
#endif
    public static let f14 = X11KeySymbols.XK_F14
#if canImport(ObjectiveC)
    @objc
#endif
    public static let f15 = X11KeySymbols.XK_F15
#if canImport(ObjectiveC)
    @objc
#endif
    public static let f16 = X11KeySymbols.XK_F16
#if canImport(ObjectiveC)
    @objc
#endif
    public static let f17 = X11KeySymbols.XK_F17
#if canImport(ObjectiveC)
    @objc
#endif
    public static let f18 = X11KeySymbols.XK_F18
#if canImport(ObjectiveC)
    @objc
#endif
    public static let f19 = X11KeySymbols.XK_F19
}

public extension _ObjC_VNCKeyCode {
#if canImport(ObjectiveC)
    @objc
#endif
	static func keyCodes(withAsciiCharacter asciiCharacter: UInt8) -> UInt32 {
		return .init(asciiCharacter)
	}
	
#if canImport(ObjectiveC)
    @objc
#endif
	static func keyCodes(withString string: String) -> [UInt32] {
		var objcKeyCodes = [UInt32]()
		
		for character in string {
			let vncKeyCodes = VNCKeyCode.withCharacter(character)
			
			for vncKeyCode in vncKeyCodes {
				objcKeyCodes.append(.init(vncKeyCode.rawValue))
			}
		}
		
		return objcKeyCodes
	}
	
#if canImport(ObjectiveC)
    @objc
#endif
	static func rawValue(ofKeyCode keyCode: UInt32,
						 forAppleRemoteDesktop isARD: Bool) -> UInt32 {
		return VNCKeyCode(keyCode).rawValue(forAppleRemoteDesktop: isARD)
	}
	
#if canImport(ObjectiveC)
    @objc
#endif
	static func hexDescription(ofKeyCode keyCode: UInt32) -> String {
		return VNCKeyCode(keyCode).hexDescription
	}
	
#if canImport(ObjectiveC)
    @objc
#endif
	static func name(ofKeyCode keyCode: UInt32) -> String? {
		return VNCKeyCode(keyCode).name
	}
	
#if canImport(ObjectiveC)
    @objc
#endif
	static func description(ofKeyCode keyCode: UInt32) -> String {
		return VNCKeyCode(keyCode).description
	}
}
