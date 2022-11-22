[![Build RoyalVNCDemo](https://github.com/royalapplications/royalvnc/actions/workflows/build-royalvncdemo.yml/badge.svg)](https://github.com/royalapplications/royalvnc/actions/workflows/build-royalvncdemo.yml) [![Build RoyalVNCObjCDemo](https://github.com/royalapplications/royalvnc/actions/workflows/build-royalvncobjcdemo.yml/badge.svg)](https://github.com/royalapplications/royalvnc/actions/workflows/build-royalvncobjcdemo.yml) [![Build RoyalVNCiOSDemo](https://github.com/royalapplications/royalvnc/actions/workflows/build-royalvnciosdemo.yml/badge.svg)](https://github.com/royalapplications/royalvnc/actions/workflows/build-royalvnciosdemo.yml)

<img src="https://github.com/royalapplications/royalvnc/blob/main/Design/AppIconMac%20Rendered/AppIconMacOS_128.png?raw=true" align="right" width="64" height="64" />

# RoyalVNC

## Description
RoyalVNC is a modern, high performance implementation of the [VNC/RFB protocol](https://github.com/rfbproto/rfbproto/blob/master/rfbproto.rst) written in Swift.
The SDK (RoyalVNCKit) is compatible with Swift and Objective-C on macOS, iOS and iPadOS.
It has no external dependencies but includes some free (public domain) third party code from the libtommath and D3DES libraries (see [Credits](#Credits)).

## Supported Features

### Security Types (Authentication Methods)
- No Authentication
- VNC Password
- Apple Remote Desktop
- UltraVNC MS-Logon II

### Encodings
- Zlib
- ZRLE (**TODO**: Currently only supports 24-bit color depth)
- Hextile
- CoRRE
- RRE
- CopyRect

### Pseudo Encodings
- LastRect
- CompressionLevel
- DesktopName
- Cursor
- DesktopSize
- ExtendedDesktopSize
- ContinuousUpdates (**TODO**: untested, I don't know a server that supports it)

### Misc. Features
- Support for 8-bit, 16-bit and 24/32-bit color depths with high-performance framebuffer implementations.
- Clipboard redirection support for text in both ways (remote to local and local to remote).
- Connection state management and rendering is decoupled from each other, so it's possible to build "headless" clients (ie. no rendering of the remote desktop). 
- The SDK includes a ready-to-use implementation of a framebuffer view for macOS (subclass of `NSView`), which also handles mouse and keyboard input, local cursor (`NSCursor`), scaling and rendering. The iOS/iPadOS equivalent (`UIView`) is a work-in-progress.
- First-class error handling. The `VNCError` type divides all possible errors into three broad categories: Protocol, Authentication and Connection errors. There are helper functions to retrieve human-readable descriptions for all errors and a convenience functions that allows the SDK consumer to distinguish between errors that should be displayed to the user and ones that shouldn't.
- The repository contains Demo/Sample clients for macOS (one written in Swift, one in Objective-C) and iOS/iPadOS.

## Usage
See [Usage](USAGE.md).

## License
[MIT License](LICENSE)

## Credits
- [libtommath](https://github.com/libtom/libtommath) ([The LibTom license](https://github.com/libtom/libtommath/blob/develop/LICENSE))
- D3DES (Public Domain, Copyright Richard Outerbridge)
