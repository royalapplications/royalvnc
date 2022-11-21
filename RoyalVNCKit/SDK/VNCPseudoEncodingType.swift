import Foundation

public enum VNCPseudoEncodingType: VNCEncodingType {
	case lastRect = -224
	case cursor = -239
	case desktopName = -307
	case continuousUpdates = -313
	case desktopSize = -223
	case extendedDesktopSize = -308
	
	// Level 1 means lowest compression level, Level 10 means highest compression level
	
	/// Lowest compression level
	case compressionLevel1 = -256
	case compressionLevel2 = -255
	case compressionLevel3 = -254
	case compressionLevel4 = -253
	case compressionLevel5 = -252
	case compressionLevel6 = -251
	case compressionLevel7 = -250
	case compressionLevel8 = -249
	case compressionLevel9 = -248
	/// Highest compression level
	case compressionLevel10 = -247
	
	case extendedClipboard = 0xc0a1e5ce
}

extension VNCPseudoEncodingType: CustomStringConvertible {
	public var description: String {
		switch self {
			case .lastRect:
				return "Last Rectangle"
			case .cursor:
				return "Cursor"
			case .desktopName:
				return "Desktop Name"
			case .continuousUpdates:
				return "Continuous Updates"
			case .desktopSize:
				return "Desktop Size"
			case .extendedDesktopSize:
				return "Extended Desktop Size"
			case .compressionLevel1:
				return "Compression Level 1"
			case .compressionLevel2:
				return "Compression Level 2"
			case .compressionLevel3:
				return "Compression Level 3"
			case .compressionLevel4:
				return "Compression Level 4"
			case .compressionLevel5:
				return "Compression Level 5"
			case .compressionLevel6:
				return "Compression Level 6"
			case .compressionLevel7:
				return "Compression Level 7"
			case .compressionLevel8:
				return "Compression Level 8"
			case .compressionLevel9:
				return "Compression Level 9"
			case .compressionLevel10:
				return "Compression Level 10"
			case .extendedClipboard:
				return "Extended Clipboard"
		}
	}
}
