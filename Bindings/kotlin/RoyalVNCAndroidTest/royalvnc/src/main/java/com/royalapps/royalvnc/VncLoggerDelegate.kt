package com.royalapps.royalvnc

interface VncLoggerDelegate {
    fun log(
        logger: VncLogger,
        logLevel: VncLogLevel,
        message: String
    )
}