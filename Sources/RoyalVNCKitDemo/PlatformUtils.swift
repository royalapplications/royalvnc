#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(WinSDK)
import WinSDK
#elseif canImport(Android)
import Android
#endif

func platformSleep(forTimeInterval timeInterval: TimeInterval) {
#if canImport(WinSDK)
    let timeIntervalMS = UInt32(timeInterval * 1000.0)

    Sleep(timeIntervalMS)
#elseif canImport(Glibc) || canImport(Android)
    let timeIntervalMicroseconds = UInt32(timeInterval * 1000000.0)

    usleep(timeIntervalMicroseconds)
#else
    Thread.sleep(forTimeInterval: timeInterval)
#endif
}

func readPassword(prompt: String) -> String? {
#if canImport(Darwin)
    var buffer = [CChar](repeating: 0,
                         count: 4096)

    guard let passwordC = readpassphrase(prompt,
                                         &buffer,
                                         buffer.count,
                                         0) else {
        return nil
    }

    let password = String(cString: passwordC)

    return password
#elseif canImport(Glibc)
    guard let passwordC = getpass(prompt) else {
        return nil
    }

    let password = String(cString: passwordC)

    return password
#elseif canImport(Android)
    // TODO

    return nil
#else
    let len = 4096

    /* Resources that will be cleaned up */
    var orig: DWORD = 0
    var wbuf: UnsafeMutableRawPointer?
    var wbuf_len: SIZE_T = 0
    var hi = INVALID_HANDLE_VALUE
    var ho = INVALID_HANDLE_VALUE

    defer {
        if let wbuf {
            RtlSecureZeroMemory(wbuf, .init(wbuf_len))
            HeapFree(GetProcessHeap(), 0, wbuf)
        }

        /* Exploit that operations on INVALID_HANDLE_VALUE are no-ops */
        WriteConsoleA(ho, "\n", 1, nil, nil)
        SetConsoleMode(hi, orig)
        CloseHandle(ho)
        CloseHandle(hi)
    }

    /* Set up input console handle */
    let access = DWORD(GENERIC_READ) | DWORD(GENERIC_WRITE)
    hi = CreateFileA("CONIN$", access, 0, nil, .init(OPEN_EXISTING), 0, nil)

    guard GetConsoleMode(hi, &orig) else {
        return nil
    }

    var mode = orig
    mode |= .init(ENABLE_PROCESSED_INPUT)
    mode |= .init(ENABLE_LINE_INPUT)
    mode &= ~(.init(ENABLE_ECHO_INPUT))

    guard SetConsoleMode(hi, mode) else {
        return nil
    }

    /* Set up output console handle */
    ho = CreateFileA("CONOUT$", .init(GENERIC_WRITE), 0, nil, .init(OPEN_EXISTING), 0, nil)

    guard WriteConsoleA(ho, prompt, .init(strlen(prompt)), nil, nil) else {
        return nil
    }

    /* Allocate a wide character buffer the size of the output */
    wbuf_len = (SIZE_T(len) - 1 + 2) * SIZE_T(MemoryLayout<WCHAR>.stride)
    wbuf = HeapAlloc(GetProcessHeap(), 0, wbuf_len)

    guard let wbuf else {
        return nil
    }

    /* Read and convert to UTF-8 */
    var nread: DWORD = 0

    guard ReadConsoleW(hi, wbuf, DWORD(len) - 1 + 2, &nread, nil) else {
        return nil
    }

    guard nread >= 2 else {
        return nil
    }

    // TODO: Do this to the passwordBuf string
    let wbufAsWchar = UnsafeMutablePointer<WCHAR>(OpaquePointer(wbuf))

    if wbufAsWchar[Int(nread)-2] != UInt16("\r".utf16.first!) ||
       wbufAsWchar[Int(nread)-1] != UInt16("\n".utf16.first!) {
        return nil
    }

    wbufAsWchar[Int(nread)-2] = 0 // truncate "\r\n"

    guard let buf = malloc(MemoryLayout<CChar>.stride * len) else {
        return nil
    }

    defer {
        free(buf)
    }

    WideCharToMultiByte(.init(CP_UTF8), 0, .init(OpaquePointer(wbuf)), -1, buf, .init(len), nil, nil);

    let bufAsCCharPtr = UnsafeMutablePointer<CChar>(OpaquePointer(buf))
    let passwordBuf = String(cString: bufAsCCharPtr)

    return passwordBuf
#endif
}
