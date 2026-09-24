#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

#if os(macOS)
import AppKit
#elseif os(iOS)
	import UIKit
#endif
#if canImport(CoreGraphics)
import CoreGraphics
#endif

final class VNCClipboard {
#if os(macOS)
	let pasteboard: NSPasteboard
#elseif os(iOS)
	let pasteboard: UIPasteboard
#endif

	init() {
#if os(macOS) || os(iOS)
		self.pasteboard = .general
#endif
	}

#if os(macOS)
    init(pasteboard: NSPasteboard) {
        self.pasteboard = pasteboard
    }
#endif
}

extension VNCClipboard {
	var text: String? {
		get {
#if os(macOS)
            let pBoardType = pasteboard.availableType(from: [.string])
            
            guard let pBoardType,
                  pBoardType == .string else {
                return nil
            }
            
			let text = pasteboard.string(forType: pBoardType)
#elseif os(iOS)
            guard pasteboard.hasStrings else {
                return nil
            }
            
			let text = pasteboard.string
#else
			let text: String? = nil
#endif

			return text
		}
		set {
#if os(macOS)
			pasteboard.clearContents()

			pasteboard.setString(newValue ?? "", forType: .string)
#elseif os(iOS)
			pasteboard.string = newValue
#endif
		}
	}
}

extension VNCClipboard {
	var changeCount: Int {
#if os(macOS) || os(iOS)
		pasteboard.changeCount
#else
		0
#endif
	}
}

#if os(macOS) || os(iOS)
extension VNCClipboard {
    var imageData: Data? {
        get {
#if os(macOS)
            let bitmapType = NSPasteboard.PasteboardType("com.microsoft.bmp")
            if let bitmap = pasteboard.data(forType: bitmapType), bitmap.count > 14,
               bitmap.prefix(2) == Data([0x42, 0x4d]) {
                let dib = Data(bitmap.dropFirst(14))
                if ExtendedClipboard.isValidDIBV5(dib) { return dib }
            }
            let imageData = pasteboard.data(forType: .png) ?? pasteboard.data(forType: .tiff)
            guard let imageData, let image = NSImage(data: imageData),
                  let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
            return DIBV5Bitmap.encode(cgImage)
#elseif os(iOS)
            guard let cgImage = pasteboard.image?.cgImage else { return nil }
            return DIBV5Bitmap.encode(cgImage)
#else
            return nil
#endif
        }
        set {
            guard let newValue, let cgImage = DIBV5Bitmap.decode(newValue) else { return }
#if os(macOS)
            let image = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
            guard let tiff = image.tiffRepresentation else { return }
            pasteboard.clearContents()
            pasteboard.setData(tiff, forType: .tiff)
            if let bitmap = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) {
                pasteboard.setData(bitmap, forType: .png)
            }
#elseif os(iOS)
            pasteboard.image = UIImage(cgImage: cgImage)
#endif
        }
    }
}

/// Converts the standard clipboard DIB V5 subset to and from 32-bit BGRA pixels.
enum DIBV5Bitmap {
    static func encode(_ image: CGImage) -> Data? {
        let width = image.width
        let height = image.height
        guard width > 0, height > 0, width <= Int(Int32.max), height <= Int(Int32.max) else { return nil }
        let pixelBytes = UInt64(width) * UInt64(height) * 4
        guard pixelBytes <= UInt64(ExtendedClipboard.maximumImageBytes) else { return nil }
        let bytesPerRow = width * 4
        var pixels = Data(count: Int(pixelBytes))
        let bitmapInfo = CGBitmapInfo.byteOrder32Little.union(CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue))
        let rendered = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(data: buffer.baseAddress, width: width, height: height,
                                          bitsPerComponent: 8, bytesPerRow: bytesPerRow,
                                          space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: bitmapInfo.rawValue) else {
                return false
            }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard rendered else { return nil }
        pixels.withUnsafeMutableBytes { buffer in
            let bytes = buffer.bindMemory(to: UInt8.self)
            for offset in stride(from: 0, to: bytes.count, by: 4) {
                let alpha = UInt32(bytes[offset + 3])
                if alpha == 0 {
                    bytes[offset] = 0; bytes[offset + 1] = 0; bytes[offset + 2] = 0
                } else if alpha < 255 {
                    for channel in offset..<offset + 3 {
                        bytes[channel] = UInt8(min(255, UInt32(bytes[channel]) * 255 / alpha))
                    }
                }
            }
        }

        var data = Data(repeating: 0, count: 124)
        write32(124, to: &data, at: 0)
        write32(UInt32(width), to: &data, at: 4)
        write32(UInt32(bitPattern: -Int32(height)), to: &data, at: 8)
        write16(1, to: &data, at: 12)
        write16(32, to: &data, at: 14)
        write32(3, to: &data, at: 16) // BI_BITFIELDS
        write32(UInt32(pixelBytes), to: &data, at: 20)
        write32(0x00ff0000, to: &data, at: 40)
        write32(0x0000ff00, to: &data, at: 44)
        write32(0x000000ff, to: &data, at: 48)
        write32(0xff000000, to: &data, at: 52)
        write32(0x73524742, to: &data, at: 56) // LCS_sRGB
        write32(4, to: &data, at: 108) // LCS_GM_IMAGES
        data.append(pixels)
        return ExtendedClipboard.isValidDIBV5(data) ? data : nil
    }

    static func decode(_ data: Data) -> CGImage? {
        guard ExtendedClipboard.isValidDIBV5(data) else { return nil }
        let width = Int(read32(data, at: 4))
        let signedHeight = Int32(bitPattern: read32(data, at: 8))
        let height = Int(abs(signedHeight))
        let pixelData = data.subdata(in: 124..<data.count)
        guard let provider = CGDataProvider(data: pixelData as CFData) else { return nil }
        let info = CGBitmapInfo.byteOrder32Little.union(CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue))
        guard let image = CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32,
                                  bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: info, provider: provider, decode: nil,
                                  shouldInterpolate: false, intent: .defaultIntent) else { return nil }
        if signedHeight > 0 {
            // A positive DIB height stores rows bottom-up; normalize to CoreGraphics' top-down image.
            guard let context = CGContext(data: nil, width: width, height: height,
                                          bitsPerComponent: 8, bytesPerRow: 0,
                                          space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: info.rawValue) else { return nil }
            context.translateBy(x: 0, y: CGFloat(height))
            context.scaleBy(x: 1, y: -1)
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return context.makeImage()
        }
        return image
    }

    private static func write16(_ value: UInt16, to data: inout Data, at offset: Int) {
        var little = value.littleEndian
        withUnsafeBytes(of: &little) { data.replaceSubrange(offset..<(offset + 2), with: $0) }
    }

    private static func write32(_ value: UInt32, to data: inout Data, at offset: Int) {
        var little = value.littleEndian
        withUnsafeBytes(of: &little) { data.replaceSubrange(offset..<(offset + 4), with: $0) }
    }

    private static func read32(_ data: Data, at offset: Int) -> UInt32 {
        UInt32(data[offset]) | UInt32(data[offset + 1]) << 8 |
        UInt32(data[offset + 2]) << 16 | UInt32(data[offset + 3]) << 24
    }
}

/// Converts between platform images and the DIB V5 payload used by RFB extended clipboard.
public enum VNCClipboardImageCodec {
    /// Encodes an image as a bounded, uncompressed 32-bit DIB V5 payload.
    public static func encode(_ image: CGImage) -> Data? {
        DIBV5Bitmap.encode(image)
    }

    /// Decodes the supported DIB V5 subset. Invalid or oversized payloads return `nil`.
    public static func decode(_ data: Data) -> CGImage? {
        DIBV5Bitmap.decode(data)
    }
}
#else
extension VNCClipboard {
    var imageData: Data? {
        get { nil }
        set {}
    }
}
#endif
