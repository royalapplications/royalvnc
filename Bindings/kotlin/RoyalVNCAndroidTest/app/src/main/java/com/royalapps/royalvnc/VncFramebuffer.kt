package com.royalapps.royalvnc

import android.graphics.Bitmap
import androidx.core.graphics.createBitmap
import com.sun.jna.*
import com.sun.jna.ptr.*

data class VncFramebuffer(
    internal val ptr: Pointer /* rvnc_framebuffer_t */
) {
    val width: Short
        get() = RoyalVNCKit.rvnc_framebuffer_size_width_get(ptr)

    val height: Short
        get() = RoyalVNCKit.rvnc_framebuffer_size_height_get(ptr)

//    val pixelData: Pointer
//        get() = RoyalVNCKit.rvnc_framebuffer_pixel_data_get(ptr)
//
//    val pixelDataSize: Long
//        get() = RoyalVNCKit.rvnc_framebuffer_pixel_data_size_get(ptr)

    val bitmap: Bitmap
        get() {
            val sizeRef = LongByReference()

            val argbData = RoyalVNCKit.rvnc_framebuffer_pixel_data_rgba32_get_copy(
                ptr,
                sizeRef
            )

            val size = sizeRef.value
            val argbBuffer = argbData.getByteBuffer(0, size)
            val width = this.width.toInt()
            val height = this.height.toInt()

            val bmp = createBitmap(
                width,
                height,
                Bitmap.Config.ARGB_8888
            )

            bmp.copyPixelsFromBuffer(argbBuffer)

            RoyalVNCKit.rvnc_framebuffer_pixel_data_rgba32_destroy(ptr, argbData)

            return bmp
        }
}