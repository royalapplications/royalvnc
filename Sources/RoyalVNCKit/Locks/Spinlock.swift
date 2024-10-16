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