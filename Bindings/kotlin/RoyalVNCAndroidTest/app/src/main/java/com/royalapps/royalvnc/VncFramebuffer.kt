package com.royalapps.royalvnc

import com.sun.jna.*

data class VncFramebuffer(
    internal val ptr: Pointer /* rvnc_framebuffer_t */
) {
    val width: Short
        get() = RoyalVNCKit.rvnc_framebuffer_size_width_get(ptr)

    val height: Short
        get() = RoyalVNCKit.rvnc_framebuffer_size_height_get(ptr)

    val pixelData: Pointer
        get() = RoyalVNCKit.rvnc_framebuffer_pixel_data_get(ptr)

    val pixelDataSize: Long
        get() = RoyalVNCKit.rvnc_framebuffer_pixel_data_size_get(ptr)
}