#if canImport(Glibc)
#if canImport(FoundationEssentials)
import FoundationEssentials
#else
import Foundation
#endif

import Glibc

class Spinlock {
    private var spinlock = pthread_spinlock_t()

    init() {
        pthread_spin_init(&spinlock, .init(PTHREAD_PROCESS_PRIVATE))
    }

    deinit {
        pthread_spin_destroy(&spinlock)
    }

    func lock() {
        pthread_spin_lock(&spinlock)
    }

    func unlock() {
        pthread_spin_unlock(&spinlock)
    }
}
#endif

#if canImport(ucrt)
#if canImport(FoundationEssentials)
import FoundationEssentials
#endif

import ucrt
import WinSDK

class Spinlock {
    private var spinlock = CRITICAL_SECTION()

    init() {
        // ref. https://learn.microsoft.com/en-us/windows/win32/Sync/using-critical-section-objects
        let spinCount: DWORD = 0x00000400
        guard InitializeCriticalSectionAndSpinCount(&spinlock, spinCount) else {
            fatalError("Could not initialize critical section (Spinlock)")
        }
    }

    deinit {
        DeleteCriticalSection(&spinlock)
    }

    func lock() {
        EnterCriticalSection(&spinlock)
    }

    func unlock() {
        LeaveCriticalSection(&spinlock)
    }
}
#endif
