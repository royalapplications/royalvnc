#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

#if canImport(CoreGraphics) && canImport(ImageIO)
import CoreGraphics
import ImageIO
#endif

#if canImport(JPEG)
@_implementationOnly import JPEG
#endif

#if canImport(PNG)
@_implementationOnly import PNG
#endif

extension VNCProtocol {
	final class TightEncoding: VNCFrameEncoding {
		let encodingType = VNCFrameEncodingType.tight.rawValue

		private var zStreams: [ZlibStream]

		init() {
			self.zStreams = [
				ZlibStream(),
				ZlibStream(),
				ZlibStream(),
				ZlibStream()
			]
		}

		static func supportsPixelFormat(_ pixelFormat: VNCProtocol.PixelFormat) -> Bool {
			pixelFormat.trueColor &&
			pixelFormat.bitsPerPixel == 32 &&
			pixelFormat.depth == 24 &&
			pixelFormat.redMax == 255 &&
			pixelFormat.greenMax == 255 &&
			pixelFormat.blueMax == 255
		}
	}
}

extension VNCProtocol.TightEncoding {
    func decodeRectangle(_ rectangle: VNCProtocol.Rectangle,
                         framebuffer: VNCFramebuffer,
                         connection: NetworkConnectionReading,
                         logger: VNCLogger) async throws {
		let width = Int(rectangle.width)
		let height = Int(rectangle.height)

		guard width > 0,
			  height > 0 else {
			logger.logDebug("Nothing to Tight decode, skipping")
			return
		}

		let pixelFormat = framebuffer.sourcePixelFormat

		guard pixelFormat.trueColor else {
			throw VNCError.protocol(.notImplemented(feature: "Tight encoding for non-true-color pixel formats"))
		}

		let bytesPerPixel = framebuffer.sourceProperties.bytesPerPixel
		let tPixelSize = Self.tightPixelSize(pixelFormat: pixelFormat)

		let control = try await connection.readUInt8()

		resetZStreamsIfNeeded(control: control)

		let subencoding = control & 0xF0

		if subencoding == TightSubencoding.fill.rawValue {
			var pixelData = try await connection.read(length: tPixelSize)

			if tPixelSize != bytesPerPixel {
                pixelData = try Self.convertTPixelData(
                    pixelData,
                    pixelFormat: pixelFormat,
                    bytesPerPixel: bytesPerPixel,
                    tPixelSize: tPixelSize
                )
			}

			framebuffer.fill(region: rectangle.region,
							 withPixel: &pixelData)

			framebuffer.didUpdate(region: rectangle.region)
            
			return
		}

		if subencoding == TightSubencoding.jpeg.rawValue {
			guard Self.supportsPixelFormat(pixelFormat) else {
				throw VNCError.protocol(.notImplemented(feature: "Tight JPEG decoding for current pixel format"))
			}

			let jpegLength = try await readCompactLength(connection: connection)
            
            let jpegData = try await readBuffered(connection: connection,
                                                  length: jpegLength)

            var decoded = try Self.decodeImageData(
                jpegData,
                imageType: .jpeg,
                width: width,
                height: height,
                pixelFormat: pixelFormat,
                bytesPerPixel: bytesPerPixel
            )

            framebuffer.update(region: rectangle.region,
                               data: &decoded)

			framebuffer.didUpdate(region: rectangle.region)
            
			return
		}

		if subencoding == TightSubencoding.png.rawValue {
			guard Self.supportsPixelFormat(pixelFormat) else {
				throw VNCError.protocol(.notImplemented(feature: "Tight PNG decoding for current pixel format"))
			}

			let pngLength = try await readCompactLength(connection: connection)
            
            let pngData = try await readBuffered(connection: connection,
                                                 length: pngLength)

            var decoded = try Self.decodeImageData(
                pngData,
                imageType: .png,
                width: width,
                height: height,
                pixelFormat: pixelFormat,
                bytesPerPixel: bytesPerPixel
            )

			framebuffer.update(region: rectangle.region,
                               data: &decoded)

			framebuffer.didUpdate(region: rectangle.region)
            
			return
		}

		let streamId = Int((control >> 4) & 0x03)
		let explicitFilter = (control & 0x40) != 0
        
		let filterID = explicitFilter
			? try await connection.readUInt8()
			: TightFilter.copy.rawValue

		switch filterID {
			case TightFilter.copy.rawValue:
				let expectedSize = width * height * tPixelSize
                
                var rawData = try await readTightData(
                    connection: connection,
                    expectedSize: expectedSize,
                    streamId: streamId,
                    logger: logger
                )

				if tPixelSize != bytesPerPixel {
                    rawData = try Self.convertTPixelData(
                        rawData,
                        pixelFormat: pixelFormat,
                        bytesPerPixel: bytesPerPixel,
                        tPixelSize: tPixelSize
                    )
				}

                framebuffer.update(region: rectangle.region,
                                   data: &rawData)

			case TightFilter.palette.rawValue:
				let paletteSize = Int(try await connection.readUInt8()) + 1
				let paletteBytes = paletteSize * tPixelSize

				let rawPaletteData = try await connection.read(length: paletteBytes)
                
                let paletteData = try Self.convertPaletteData(
                    rawPaletteData,
                    pixelFormat: pixelFormat,
                    bytesPerPixel: bytesPerPixel,
                    tPixelSize: tPixelSize
                )

				let indexDataSize: Int
                
				if paletteSize == 2 {
					let bytesPerRow = (width + 7) / 8
					indexDataSize = bytesPerRow * height
				} else {
					indexDataSize = width * height
				}

                let indices = try await readTightData(
                    connection: connection,
                    expectedSize: indexDataSize,
                    streamId: streamId,
                    logger: logger
                )

                var decoded = try Self.expandPalette(
                    indices: indices,
                    palette: paletteData,
                    paletteSize: paletteSize,
                    width: width,
                    height: height,
                    bytesPerPixel: bytesPerPixel
                )

                framebuffer.update(region: rectangle.region,
                                   data: &decoded)

			case TightFilter.gradient.rawValue:
				guard tPixelSize == 3 else {
					throw VNCError.protocol(.notImplemented(feature: "Tight Gradient Filter for current pixel format"))
				}

				let expectedSize = width * height * tPixelSize
                
                let filteredData = try await readTightData(
                    connection: connection,
                    expectedSize: expectedSize,
                    streamId: streamId,
                    logger: logger
                )

                var decoded = try Self.decodeGradient(
                    filteredData,
                    width: width,
                    height: height,
                    pixelFormat: pixelFormat,
                    bytesPerPixel: bytesPerPixel
                )

                framebuffer.update(region: rectangle.region,
                                   data: &decoded)

			default:
				throw VNCError.protocol(.notImplemented(feature: "Tight Filter ID \(filterID)"))
		}

		framebuffer.didUpdate(region: rectangle.region)
	}
}

private extension VNCProtocol.TightEncoding {
    enum TightImageType {
        case jpeg
        case png
    }

	enum TightSubencoding: UInt8 {
		case fill = 0x80
		case jpeg = 0x90
		case png = 0xA0
	}

	enum TightFilter: UInt8 {
		case copy = 0
		case palette = 1
		case gradient = 2
	}

	func resetZStreamsIfNeeded(control: UInt8) {
		for idx in 0..<4 {
			let mask = UInt8(1 << idx)
            
			if (control & mask) != 0 {
				zStreams[idx] = ZlibStream()
			}
		}
	}

	func readCompactLength(connection: NetworkConnectionReading) async throws -> Int {
		var length = 0
		var shift = 0

		for _ in 0..<3 {
			let byte = try await connection.readUInt8()
			length |= Int(byte & 0x7F) << shift

			if (byte & 0x80) == 0 {
				return length
			}

			shift += 7
		}

		throw VNCError.protocol(.invalidData)
	}

	func readBuffered(connection: NetworkConnectionReading,
					  length: Int) async throws -> Data {
		guard length > 0 else {
			return .init()
		}

		let chunkSize = 1024 * 16
        
        let data = try await connection.readBuffered(
            length: length,
            minimumChunkSize: 1,
            maximumChunkSize: chunkSize
        )

		guard data.count == length else {
			throw VNCError.protocol(.invalidData)
		}

		return data
	}

    func readTightData(
        connection: NetworkConnectionReading,
        expectedSize: Int,
        streamId: Int,
        logger: VNCLogger
    ) async throws -> Data {
		guard expectedSize > 0 else {
			return .init()
		}

		if expectedSize < 12 {
            let data = try await readBuffered(
                connection: connection,
                length: expectedSize
            )

			return data
		}

		let compressedLength = try await readCompactLength(connection: connection)

		guard compressedLength > 0 else {
			logger.logDebug("Tight: Compressed length is 0")
            
			throw VNCError.protocol(.invalidData)
		}

        let compressedData = try await readBuffered(
            connection: connection,
            length: compressedLength
        )

		do {
            return try zStreams[streamId].decompressedData(
                compressedData: compressedData,
                uncompressedSize: .init(expectedSize)
            )
		} catch {
			throw VNCError.protocol(.frameDecode(encodingType: encodingType, underlyingError: error))
		}
	}

	static func tightPixelSize(pixelFormat: VNCProtocol.PixelFormat) -> Int {
        if pixelFormat.trueColor,
           pixelFormat.bitsPerPixel == 32,
           pixelFormat.depth == 24,
           pixelFormat.redMax == 255,
           pixelFormat.greenMax == 255,
           pixelFormat.blueMax == 255 {
            return 3
        }

		return Int(pixelFormat.bitsPerPixel / 8)
	}

    static func convertPaletteData(
        _ paletteData: Data,
        pixelFormat: VNCProtocol.PixelFormat,
        bytesPerPixel: Int,
        tPixelSize: Int
    ) throws -> Data {
		guard tPixelSize != bytesPerPixel else {
			return paletteData
		}

        return try convertTPixelData(
            paletteData,
            pixelFormat: pixelFormat,
            bytesPerPixel: bytesPerPixel,
            tPixelSize: tPixelSize
        )
	}

    static func convertTPixelData(
        _ data: Data,
        pixelFormat: VNCProtocol.PixelFormat,
        bytesPerPixel: Int,
        tPixelSize: Int
    ) throws -> Data {
		guard tPixelSize == 3 else {
			throw VNCError.protocol(.notImplemented(feature: "Tight TPIXEL size \(tPixelSize) conversion"))
		}

		guard data.count % tPixelSize == 0 else {
			throw VNCError.protocol(.invalidData)
		}

		let pixelCount = data.count / tPixelSize
		let bitsPerPixel = Int(pixelFormat.bitsPerPixel)

		var converted = Data(count: pixelCount * bytesPerPixel)

		converted.withUnsafeMutableBytes { convertedPtr in
			var inputIndex = 0

			for pixelIndex in 0..<pixelCount {
				let red = data[inputIndex]
				let green = data[inputIndex + 1]
				let blue = data[inputIndex + 2]

                let pixelValue = packPixelValue(
                    red: red,
                    green: green,
                    blue: blue,
                    pixelFormat: pixelFormat
                )

				let offset = pixelIndex * bytesPerPixel

                storePixelValue(
                    pixelValue,
                    bitsPerPixel: bitsPerPixel,
                    targetPtr: convertedPtr.baseAddress,
                    offset: offset
                )

				inputIndex += tPixelSize
			}
		}

		return converted
	}

    static func expandPalette(
        indices: Data,
        palette: Data,
        paletteSize: Int,
        width: Int,
        height: Int,
        bytesPerPixel: Int
    ) throws -> Data {
		let pixelCount = width * height
		var output = Data(count: pixelCount * bytesPerPixel)
		var invalidIndex = false

		output.withUnsafeMutableBytes { outputPtr in
			guard let outputBase = outputPtr.baseAddress else {
				return
			}

			if paletteSize == 2 {
				let bytesPerRow = (width + 7) / 8

				for row in 0..<height {
					let rowStart = row * bytesPerRow

					for column in 0..<width {
						let byte = indices[rowStart + (column >> 3)]
						let bit = 7 - (column & 7)
						let paletteIndex = Int((byte >> bit) & 0x01)

						let sourceOffset = paletteIndex * bytesPerPixel
						let destinationOffset = (row * width + column) * bytesPerPixel

						let target = outputBase.advanced(by: destinationOffset)
                            .assumingMemoryBound(to: UInt8.self)
                        
                        palette.copyBytes(to: target,
                                          from: sourceOffset..<sourceOffset + bytesPerPixel)
					}
				}
			} else {
				for idx in 0..<pixelCount {
					let paletteIndex = Int(indices[idx])
                    
					guard paletteIndex < paletteSize else {
						invalidIndex = true
						return
					}
                    
					let sourceOffset = paletteIndex * bytesPerPixel
					let destinationOffset = idx * bytesPerPixel

					let target = outputBase.advanced(by: destinationOffset)
                        .assumingMemoryBound(to: UInt8.self)
                    
                    palette.copyBytes(to: target,
                                      from: sourceOffset..<sourceOffset + bytesPerPixel)
				}
			}
		}

		if invalidIndex {
			throw VNCError.protocol(.invalidData)
		}

		return output
	}

    static func decodeGradient(
        _ data: Data,
        width: Int,
        height: Int,
        pixelFormat: VNCProtocol.PixelFormat,
        bytesPerPixel: Int
    ) throws -> Data {
		guard data.count == width * height * 3 else {
			throw VNCError.protocol(.invalidData)
		}

		let pixelCount = width * height
		var output = Data(count: pixelCount * bytesPerPixel)

		var previousR = [Int](repeating: 0, count: width)
		var previousG = [Int](repeating: 0, count: width)
		var previousB = [Int](repeating: 0, count: width)

		var currentR = [Int](repeating: 0, count: width)
		var currentG = [Int](repeating: 0, count: width)
		var currentB = [Int](repeating: 0, count: width)

		let bitsPerPixel = Int(pixelFormat.bitsPerPixel)
		let maxValue = 255

		output.withUnsafeMutableBytes { outputPtr in
			guard let outputBase = outputPtr.baseAddress else {
				return
			}

			var dataIndex = 0

			for row in 0..<height {
				var leftR = 0
				var leftG = 0
				var leftB = 0

				for column in 0..<width {
					let diffR = Int(data[dataIndex])
					let diffG = Int(data[dataIndex + 1])
					let diffB = Int(data[dataIndex + 2])

					dataIndex += 3

					let upR = previousR[column]
					let upG = previousG[column]
					let upB = previousB[column]

					let upLeftR = column > 0 ? previousR[column - 1] : 0
					let upLeftG = column > 0 ? previousG[column - 1] : 0
					let upLeftB = column > 0 ? previousB[column - 1] : 0

					let predR = max(0, min(maxValue, leftR + upR - upLeftR))
					let predG = max(0, min(maxValue, leftG + upG - upLeftG))
					let predB = max(0, min(maxValue, leftB + upB - upLeftB))

					let valueR = (diffR + predR) & 0xFF
					let valueG = (diffG + predG) & 0xFF
					let valueB = (diffB + predB) & 0xFF

					currentR[column] = valueR
					currentG[column] = valueG
					currentB[column] = valueB

					leftR = valueR
					leftG = valueG
					leftB = valueB

					let offset = (row * width + column) * bytesPerPixel
                    
                    let pixelValue = packPixelValue(
                        red: UInt8(valueR),
                        green: UInt8(valueG),
                        blue: UInt8(valueB),
                        pixelFormat: pixelFormat
                    )

                    storePixelValue(
                        pixelValue,
                        bitsPerPixel: bitsPerPixel,
                        targetPtr: outputBase,
                        offset: offset
                    )
				}

				swap(&previousR, &currentR)
				swap(&previousG, &currentG)
				swap(&previousB, &currentB)

				for idx in 0..<width {
					currentR[idx] = 0
					currentG[idx] = 0
					currentB[idx] = 0
				}
			}
		}

		return output
	}

    static func packPixelValue(
        red: UInt8,
        green: UInt8,
        blue: UInt8,
        pixelFormat: VNCProtocol.PixelFormat
    ) -> Int {
		let redScaled = scaleComponent(red, maxValue: Int(pixelFormat.redMax))
		let greenScaled = scaleComponent(green, maxValue: Int(pixelFormat.greenMax))
		let blueScaled = scaleComponent(blue, maxValue: Int(pixelFormat.blueMax))

		let redShift = Int(pixelFormat.redShift)
		let greenShift = Int(pixelFormat.greenShift)
		let blueShift = Int(pixelFormat.blueShift)

		let pixelValue = (redScaled << redShift) |
                         (greenScaled << greenShift) |
                         (blueScaled << blueShift)

		return pixelValue
	}

	static func scaleComponent(_ value: UInt8,
							   maxValue: Int) -> Int {
		guard maxValue != 255 else {
			return Int(value)
		}

		return (Int(value) * maxValue + 127) / 255
	}

    static func storePixelValue(
        _ value: Int,
        bitsPerPixel: Int,
        targetPtr: UnsafeMutableRawPointer?,
        offset: Int
    ) {
		guard let targetPtr else {
			return
		}

		switch bitsPerPixel {
			case 32:
                targetPtr.storeBytes(of: UInt32(value),
                                     toByteOffset: offset,
                                     as: UInt32.self)
			case 16:
                targetPtr.storeBytes(of: UInt16(value),
                                     toByteOffset: offset,
                                     as: UInt16.self)
            case 8:
                targetPtr.storeBytes(of: UInt8(value),
                                     toByteOffset: offset,
                                     as: UInt8.self)
            default:
				break
		}
	}
}

private extension VNCProtocol.TightEncoding {
    static func decodeImageData(
        _ data: Data,
        imageType: TightImageType,
        width: Int,
        height: Int,
        pixelFormat: VNCProtocol.PixelFormat,
        bytesPerPixel: Int
    ) throws -> Data {
#if canImport(ImageIO) && canImport(CoreGraphics)
        let cfData = data as CFData

        guard let imageSource = CGImageSourceCreateWithData(cfData, nil),
              let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw VNCError.protocol(.invalidData)
        }

        guard image.width == width,
              image.height == height else {
            throw VNCError.protocol(.invalidData)
        }

        let bytesPerRow = width * 4
        var rgbaData = Data(count: bytesPerRow * height)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.union(.init(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue))

        let drawResult = rgbaData.withUnsafeMutableBytes { ptr -> Bool in
            guard let baseAddress = ptr.baseAddress else {
                return false
            }

            guard let context = CGContext(
                data: baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: bitmapInfo.rawValue
            ) else {
                return false
            }

            context.draw(image,
                         in: CGRect(x: 0, y: 0, width: width, height: height))

            return true
        }

        guard drawResult else {
            throw VNCError.protocol(.invalidData)
        }

        let pixelCount = width * height
        let bitsPerPixel = Int(pixelFormat.bitsPerPixel)
        var output = Data(count: pixelCount * bytesPerPixel)

        output.withUnsafeMutableBytes { outputPtr in
            guard let outputBase = outputPtr.baseAddress else {
                return
            }

            var inputIndex = 0

            for idx in 0..<pixelCount {
                let red = rgbaData[inputIndex]
                let green = rgbaData[inputIndex + 1]
                let blue = rgbaData[inputIndex + 2]

                let pixelValue = packPixelValue(
                    red: red,
                    green: green,
                    blue: blue,
                    pixelFormat: pixelFormat
                )

                let offset = idx * bytesPerPixel

                storePixelValue(
                    pixelValue,
                    bitsPerPixel: bitsPerPixel,
                    targetPtr: outputBase,
                    offset: offset
                )

                inputIndex += 4
            }
        }

        return output
#else
        switch imageType {
        case .jpeg:
#if canImport(JPEG)
            var stream = TightImageDataStream(data)
            let image: JPEG.Data.Rectangular<JPEG.Common> = try .decompress(stream: &stream)

            guard image.size.x == width,
                  image.size.y == height else {
                throw VNCError.protocol(.invalidData)
            }

            let pixels = image.unpack(as: JPEG.RGB.self)
            let pixelCount = width * height

            guard pixels.count == pixelCount else {
                throw VNCError.protocol(.invalidData)
            }

            return packRGBData(
                pixels,
                bytesPerPixel: bytesPerPixel,
                pixelFormat: pixelFormat
            )
#else
            throw VNCError.protocol(.notImplemented(feature: "Tight JPEG decoding requires swift-jpeg on non-Apple platforms"))
#endif

        case .png:
#if canImport(PNG)
            var stream = TightImageDataStream(data)
            let image: PNG.Image = try .decompress(stream: &stream)

            guard image.size.x == width,
                  image.size.y == height else {
                throw VNCError.protocol(.invalidData)
            }

            let pixels = image.unpack(as: PNG.RGBA<UInt8>.self)
            let pixelCount = width * height

            guard pixels.count == pixelCount else {
                throw VNCError.protocol(.invalidData)
            }

            return packRGBAData(
                pixels,
                bytesPerPixel: bytesPerPixel,
                pixelFormat: pixelFormat
            )
#else
            throw VNCError.protocol(.notImplemented(feature: "Tight PNG decoding requires swift-png on non-Apple platforms"))
#endif
        }
#endif
    }
}

private extension VNCProtocol.TightEncoding {
    struct TightImageDataStream {
        private var bytes: [UInt8]
        private var index: Int = 0

        init(_ data: Data) {
            self.bytes = Array(data)
        }

        mutating func read(count: Int) -> [UInt8]? {
            guard count >= 0,
                  index + count <= bytes.count else {
                return nil
            }

            let slice = bytes[index..<index + count]
            index += count
            return Array(slice)
        }
    }
}

#if !(canImport(ImageIO) && canImport(CoreGraphics))
#if canImport(JPEG)
extension VNCProtocol.TightEncoding.TightImageDataStream: JPEG.Bytestream.Source {}
#endif

#if canImport(PNG)
extension VNCProtocol.TightEncoding.TightImageDataStream: PNG.BytestreamSource {}
#endif

private extension VNCProtocol.TightEncoding {
#if canImport(JPEG)
    static func packRGBData(
        _ pixels: [JPEG.RGB],
        bytesPerPixel: Int,
        pixelFormat: VNCProtocol.PixelFormat
    ) -> Data {
        let pixelCount = pixels.count
        let bitsPerPixel = Int(pixelFormat.bitsPerPixel)
        var output = Data(count: pixelCount * bytesPerPixel)

        output.withUnsafeMutableBytes { outputPtr in
            guard let outputBase = outputPtr.baseAddress else {
                return
            }

            for idx in 0..<pixelCount {
                let pixel = pixels[idx]

                let pixelValue = packPixelValue(
                    red: pixel.r,
                    green: pixel.g,
                    blue: pixel.b,
                    pixelFormat: pixelFormat
                )

                storePixelValue(
                    pixelValue,
                    bitsPerPixel: bitsPerPixel,
                    targetPtr: outputBase,
                    offset: idx * bytesPerPixel
                )
            }
        }

        return output
    }
#endif

#if canImport(PNG)
    static func packRGBAData(
        _ pixels: [PNG.RGBA<UInt8>],
        bytesPerPixel: Int,
        pixelFormat: VNCProtocol.PixelFormat
    ) -> Data {
        let pixelCount = pixels.count
        let bitsPerPixel = Int(pixelFormat.bitsPerPixel)
        var output = Data(count: pixelCount * bytesPerPixel)

        output.withUnsafeMutableBytes { outputPtr in
            guard let outputBase = outputPtr.baseAddress else {
                return
            }

            for idx in 0..<pixelCount {
                let pixel = pixels[idx]

                let pixelValue = packPixelValue(
                    red: pixel.r,
                    green: pixel.g,
                    blue: pixel.b,
                    pixelFormat: pixelFormat
                )

                storePixelValue(
                    pixelValue,
                    bitsPerPixel: bitsPerPixel,
                    targetPtr: outputBase,
                    offset: idx * bytesPerPixel
                )
            }
        }

        return output
    }
#endif
}
#endif
