package com.royalapps.royalvnc

import com.sun.jna.*

data class VncFrameEncodings(
    internal val ptr: Pointer /* rvnc_frame_encodings_t */
): AutoCloseable {
    companion object {
        operator fun invoke(): VncFrameEncodings {
            val ptr = RoyalVNCKit.rvnc_frame_encodings_create()

            val frameEncodings = VncFrameEncodings(ptr)

            return frameEncodings
        }

        operator fun invoke(frameEncodingTypes: Array<VncFrameEncodingType>): VncFrameEncodings {
            val ptr = RoyalVNCKit.rvnc_frame_encodings_create()

            val frameEncodings = VncFrameEncodings(ptr)

            for (frameEncodingType in frameEncodingTypes) {
                frameEncodings.appendFrameEncodingType(frameEncodingType)
            }

            return frameEncodings
        }
    }

    private fun appendFrameEncodingType(frameEncodingType: VncFrameEncodingType) {
        when (frameEncodingType) {
            VncFrameEncodingType.RRE
                 -> RoyalVNCKit.rvnc_frame_encodings_append_rre(ptr)

            VncFrameEncodingType.CORRE
                -> RoyalVNCKit.rvnc_frame_encodings_append_corre(ptr)

            VncFrameEncodingType.HEXTILE
                -> RoyalVNCKit.rvnc_frame_encodings_append_hextile(ptr)

            VncFrameEncodingType.ZLIB
                -> RoyalVNCKit.rvnc_frame_encodings_append_zlib(ptr)

            VncFrameEncodingType.TIGHT
                -> RoyalVNCKit.rvnc_frame_encodings_append_tight(ptr)

            VncFrameEncodingType.ZRLE
                -> RoyalVNCKit.rvnc_frame_encodings_append_zrle(ptr)
        }
    }

    override fun close() {
        RoyalVNCKit.rvnc_frame_encodings_destroy(ptr)
    }
}
