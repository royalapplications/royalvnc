#if os(macOS)
import Foundation
import Carbon

/// Virtual keycodes (from Carbon)
public struct CGKeyCodes {
    // swiftlint:disable:next unneeded_synthesized_initializer
	@available(*, unavailable)
	init() { }
	
	// MARK: - ANSI Keys (these are for the US keyboard layout)
	public static let ansiA = CGKeyCode(kVK_ANSI_A)
	public static let ansiS = CGKeyCode(kVK_ANSI_S)
	public static let ansiD = CGKeyCode(kVK_ANSI_D)
	public static let ansiF = CGKeyCode(kVK_ANSI_F)
	public static let ansiH = CGKeyCode(kVK_ANSI_H)
	public static let ansiG = CGKeyCode(kVK_ANSI_G)
	public static let ansiZ = CGKeyCode(kVK_ANSI_Z)
	public static let ansiX = CGKeyCode(kVK_ANSI_X)
	public static let ansiC = CGKeyCode(kVK_ANSI_C)
	public static let ansiV = CGKeyCode(kVK_ANSI_V)
	public static let ansiB = CGKeyCode(kVK_ANSI_B)
	public static let ansiQ = CGKeyCode(kVK_ANSI_Q)
	public static let ansiW = CGKeyCode(kVK_ANSI_W)
	public static let ansiE = CGKeyCode(kVK_ANSI_E)
	public static let ansiR = CGKeyCode(kVK_ANSI_R)
	public static let ansiY = CGKeyCode(kVK_ANSI_Y)
	public static let ansiT = CGKeyCode(kVK_ANSI_T)
	public static let ansi1 = CGKeyCode(kVK_ANSI_1)
	public static let ansi2 = CGKeyCode(kVK_ANSI_2)
	public static let ansi3 = CGKeyCode(kVK_ANSI_3)
	public static let ansi4 = CGKeyCode(kVK_ANSI_4)
	public static let ansi6 = CGKeyCode(kVK_ANSI_6)
	public static let ansi5 = CGKeyCode(kVK_ANSI_5)
	public static let ansiEqual = CGKeyCode(kVK_ANSI_Equal)
	public static let ansi9 = CGKeyCode(kVK_ANSI_9)
	public static let ansi7 = CGKeyCode(kVK_ANSI_7)
	public static let ansiMinus = CGKeyCode(kVK_ANSI_Minus)
	public static let ansi8 = CGKeyCode(kVK_ANSI_8)
	public static let ansi0 = CGKeyCode(kVK_ANSI_0)
	public static let ansiRightBracket = CGKeyCode(kVK_ANSI_RightBracket)
	public static let ansiO = CGKeyCode(kVK_ANSI_O)
	public static let ansiU = CGKeyCode(kVK_ANSI_U)
	public static let ansiLeftBracket = CGKeyCode(kVK_ANSI_LeftBracket)
	public static let ansiI = CGKeyCode(kVK_ANSI_I)
	public static let ansiP = CGKeyCode(kVK_ANSI_P)
	public static let ansiL = CGKeyCode(kVK_ANSI_L)
	public static let ansiJ = CGKeyCode(kVK_ANSI_J)
	public static let ansiQuote = CGKeyCode(kVK_ANSI_Quote)
	public static let ansiK = CGKeyCode(kVK_ANSI_K)
	public static let ansiSemicolon = CGKeyCode(kVK_ANSI_Semicolon)
	public static let ansiBackslash = CGKeyCode(kVK_ANSI_Backslash)
	public static let ansiComma = CGKeyCode(kVK_ANSI_Comma)
	public static let ansiSlash = CGKeyCode(kVK_ANSI_Slash)
	public static let ansiN = CGKeyCode(kVK_ANSI_N)
	public static let ansiM = CGKeyCode(kVK_ANSI_M)
	public static let ansiPeriod = CGKeyCode(kVK_ANSI_Period)
	public static let ansiGrave = CGKeyCode(kVK_ANSI_Grave)
	public static let ansiKeypadDecimal = CGKeyCode(kVK_ANSI_KeypadDecimal)
	public static let ansiKeypadMultiply = CGKeyCode(kVK_ANSI_KeypadMultiply)
	public static let ansiKeypadPlus = CGKeyCode(kVK_ANSI_KeypadPlus)
	public static let ansiKeypadClear = CGKeyCode(kVK_ANSI_KeypadClear)
	public static let ansiKeypadDivide = CGKeyCode(kVK_ANSI_KeypadDivide)
	public static let ansiKeypadEnter = CGKeyCode(kVK_ANSI_KeypadEnter)
	public static let ansiKeypadMinus = CGKeyCode(kVK_ANSI_KeypadMinus)
	public static let ansiKeypadEquals = CGKeyCode(kVK_ANSI_KeypadEquals)
	public static let ansiKeypad0 = CGKeyCode(kVK_ANSI_Keypad0)
	public static let ansiKeypad1 = CGKeyCode(kVK_ANSI_Keypad1)
	public static let ansiKeypad2 = CGKeyCode(kVK_ANSI_Keypad2)
	public static let ansiKeypad3 = CGKeyCode(kVK_ANSI_Keypad3)
	public static let ansiKeypad4 = CGKeyCode(kVK_ANSI_Keypad4)
	public static let ansiKeypad5 = CGKeyCode(kVK_ANSI_Keypad5)
	public static let ansiKeypad6 = CGKeyCode(kVK_ANSI_Keypad6)
	public static let ansiKeypad7 = CGKeyCode(kVK_ANSI_Keypad7)
	public static let ansiKeypad8 = CGKeyCode(kVK_ANSI_Keypad8)
	public static let ansiKeypad9 = CGKeyCode(kVK_ANSI_Keypad9)
	
	// MARK: - Keycodes for keys that are independent of keyboard layout
	public static let `return` = CGKeyCode(kVK_Return)
	public static let tab = CGKeyCode(kVK_Tab)
	public static let space = CGKeyCode(kVK_Space)
	public static let delete = CGKeyCode(kVK_Delete)
	public static let escape = CGKeyCode(kVK_Escape)
	public static let command = CGKeyCode(kVK_Command)
	public static let shift = CGKeyCode(kVK_Shift)
	public static let capsLock = CGKeyCode(kVK_CapsLock)
	public static let option = CGKeyCode(kVK_Option)
	public static let control = CGKeyCode(kVK_Control)
	public static let rightCommand = CGKeyCode(kVK_RightCommand)
	public static let rightShift = CGKeyCode(kVK_RightShift)
	public static let rightOption = CGKeyCode(kVK_RightOption)
	public static let rightControl = CGKeyCode(kVK_RightControl)
	public static let function = CGKeyCode(kVK_Function)
	public static let f17 = CGKeyCode(kVK_F17)
	public static let volumeUp = CGKeyCode(kVK_VolumeUp)
	public static let volumeDown = CGKeyCode(kVK_VolumeDown)
	public static let mute = CGKeyCode(kVK_Mute)
	public static let f18 = CGKeyCode(kVK_F18)
	public static let f19 = CGKeyCode(kVK_F19)
	public static let f20 = CGKeyCode(kVK_F20)
	public static let f5 = CGKeyCode(kVK_F5)
	public static let f6 = CGKeyCode(kVK_F6)
	public static let f7 = CGKeyCode(kVK_F7)
	public static let f3 = CGKeyCode(kVK_F3)
	public static let f8 = CGKeyCode(kVK_F8)
	public static let f9 = CGKeyCode(kVK_F9)
	public static let f11 = CGKeyCode(kVK_F11)
	public static let f13 = CGKeyCode(kVK_F13)
	public static let f16 = CGKeyCode(kVK_F16)
	public static let f14 = CGKeyCode(kVK_F14)
	public static let f10 = CGKeyCode(kVK_F10)
	public static let f12 = CGKeyCode(kVK_F12)
	public static let f15 = CGKeyCode(kVK_F15)
	public static let help = CGKeyCode(kVK_Help) // On Windows: Insert
	public static let home = CGKeyCode(kVK_Home)
	public static let pageUp = CGKeyCode(kVK_PageUp)
	public static let forwardDelete = CGKeyCode(kVK_ForwardDelete)
	public static let f4 = CGKeyCode(kVK_F4)
	public static let end = CGKeyCode(kVK_End)
	public static let f2 = CGKeyCode(kVK_F2)
	public static let pageDown = CGKeyCode(kVK_PageDown)
	public static let f1 = CGKeyCode(kVK_F1)
	public static let leftArrow = CGKeyCode(kVK_LeftArrow)
	public static let rightArrow = CGKeyCode(kVK_RightArrow)
	public static let downArrow = CGKeyCode(kVK_DownArrow)
	public static let upArrow = CGKeyCode(kVK_UpArrow)
	
	// MARK: - ISO keyboards only
	public static let isoSection = CGKeyCode(kVK_ISO_Section)
	
	// MARK: - JIS keyboards only
	public static let jisYen = CGKeyCode(kVK_JIS_Yen)
	public static let jisUnderscore = CGKeyCode(kVK_JIS_Underscore)
	public static let jisKeypadComma = CGKeyCode(kVK_JIS_KeypadComma)
	public static let jisEisu = CGKeyCode(kVK_JIS_Eisu)
	public static let jisKana = CGKeyCode(kVK_JIS_Kana)
}
#endif
