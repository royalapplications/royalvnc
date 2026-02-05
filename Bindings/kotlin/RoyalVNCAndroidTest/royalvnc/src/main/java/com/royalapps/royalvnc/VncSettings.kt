package com.royalapps.royalvnc

import com.sun.jna.*

data class VncSettings(
    internal val ptr: Pointer /* rvnc_settings_t */
): AutoCloseable {
    companion object {
        operator fun invoke(
            isDebugLoggingEnabled: Boolean,
            hostname: String,
            port: Short,
            isShared: Boolean,
            isScalingEnabled: Boolean,
            useDisplayLink: Boolean,
            inputMode: VncInputMode,
            isClipboardRedirectionEnabled: Boolean,
            colorDepth: VncColorDepth,
            frameEncodings: Array<VncFrameEncodingType>?
        ): VncSettings {
            val frameEncodingsC: VncFrameEncodings? = if (frameEncodings != null) {
                VncFrameEncodings(frameEncodings)
            } else {
                null
            }

            val ptr = RoyalVNCKit.rvnc_settings_create(
                isDebugLoggingEnabled,
                hostname,
                port,
                isShared,
                isScalingEnabled,
                useDisplayLink,
                inputMode.rawValue,
                isClipboardRedirectionEnabled,
                colorDepth.rawValue,
                frameEncodingsC?.ptr
            )

            val settings = VncSettings(ptr)

            frameEncodingsC?.close()

            return settings
        }
    }

    override fun close() {
        RoyalVNCKit.rvnc_settings_destroy(ptr)
    }
}
