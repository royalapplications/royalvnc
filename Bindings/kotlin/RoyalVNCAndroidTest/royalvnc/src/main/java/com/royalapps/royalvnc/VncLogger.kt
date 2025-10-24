package com.royalapps.royalvnc

import com.sun.jna.*
import java.lang.ref.*

data class VncLogger(
    internal val delegate: WeakReference<VncLoggerDelegate>
):
    AutoCloseable,
    RoyalVNCKit.rvnc_logger_delegate_log
{
    internal val ptr = RoyalVNCKit.rvnc_logger_create(
        this,
        null
    )

    override fun close() {
        RoyalVNCKit.rvnc_logger_destroy(ptr)
    }

    // rvnc_logger_delegate_log Implementation
    override fun log(
        logger: Pointer,
        context: Pointer?,
        logLevel: Int,
        message: String
    ) {
        val logLevelKt = VncLogLevel(logLevel)

        delegate.get()?.log(
            this,
            logLevelKt,
            message
        )
    }
}
