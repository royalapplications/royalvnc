[![CI](https://github.com/royalapplications/royalvnc/actions/workflows/ci.yml/badge.svg)](https://github.com/royalapplications/royalvnc/actions/workflows/ci.yml)

![RoyalVNC](Design/Banner_Rendered/Banner.png)

RoyalVNC is a modern, high performance implementation of the [VNC/RFB protocol](https://github.com/rfbproto/rfbproto/blob/master/rfbproto.rst) written in Swift.
The SDK (RoyalVNCKit) is compatible with Swift, Objective-C, C and C# on macOS, iOS, iPadOS, Linux and Windows.
It depends on [CryptoSwift](https://github.com/krzyzanowskim/CryptoSwift), [zlib](https://github.com/madler/zlib) and D3DES (see [Credits](#Credits)).

## Supported Features

### Security Types (Authentication Methods)
- No Authentication
- VNC Password
- Apple Remote Desktop
- UltraVNC MS-Logon II

### Encodings
- Tight
- Zlib
- ZRLE
- Hextile
- CoRRE
- RRE
- CopyRect

### Pseudo Encodings
- LastRect
- CompressionLevel
- JpegCompressionLevel
- DesktopName
- Cursor
- DesktopSize
- ExtendedDesktopSize
- ContinuousUpdates

### Misc. Features
- Support for 8-bit, 16-bit and 24/32-bit color depths with high-performance framebuffer implementations.
- Clipboard redirection support for text in both ways (remote to local and local to remote).
- Connection state management and rendering is decoupled from each other, so it's possible to build "headless" clients (ie. no rendering of the remote desktop).
- The SDK includes a ready-to-use implementation of a framebuffer view for macOS (subclass of `NSView`), which also handles mouse and keyboard input, local cursor (`NSCursor`), scaling and rendering. The iOS/iPadOS equivalent (`UIView`) is a work-in-progress.
- First-class error handling. The `VNCError` type divides all possible errors into three broad categories: Protocol, Authentication and Connection errors. There are helper functions to retrieve human-readable descriptions for all errors and a convenience functions that allows the SDK consumer to distinguish between errors that should be displayed to the user and ones that shouldn't.
- Headless CLI demos (one using Swift and another one using the C API) are included in the repository.
- The repository also contains C# bindings so the library can be used with .NET.
- The repository also contains Kotlin bindings which make the library usable in Android projects. To set up the Android development environment (only supported on macOS currently):
  - Install Java 11 or later, ensuring the `java` executable is added to the `PATH`
  - Install Android Studio and ensure the `ANDROID_HOME` environment variable is exposed to your shell (see https://developer.android.com/tools/variables)
  - Run `./android_dependencies.sh` to install the Android tooling and SDKs for Android
  - Run `./android_build.sh` which builds the RoyalVNCKit native library and lays out its depedencies
  - Open `Bindings/kotlin/RoyalVNCAndroidTest` in Android Studio to build and run the demo app
- [This repository](https://github.com/royalapplications/royalvnc-demo) contains Demo/Sample clients for macOS (one written in Swift, one in Objective-C) and iOS/iPadOS.

## Usage
See [Usage](USAGE.md).

## License
[MIT License](LICENSE)

## Credits
- [CryptoSwift](https://github.com/krzyzanowskim/CryptoSwift) ([The CryptoSwift license](https://github.com/krzyzanowskim/CryptoSwift/blob/main/LICENSE))
- [zlib](https://github.com/madler/zlib) ([zlib license](https://github.com/madler/zlib/blob/develop/LICENSE))
- [Swift JPEG](https://github.com/tayloraswift/swift-jpeg) ([Apache License 2.0](https://github.com/tayloraswift/swift-jpeg/blob/master/LICENSE))
- [Swift PNG](https://github.com/tayloraswift/swift-png) ([Apache License 2.0](https://github.com/tayloraswift/swift-png/blob/master/LICENSE))
- D3DES (Public Domain, Copyright Richard Outerbridge)
