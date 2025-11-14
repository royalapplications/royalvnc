package com.royalapps.royalvnc

import android.graphics.Bitmap
import androidx.core.graphics.createBitmap
import com.sun.jna.*
import java.nio.ByteBuffer

data class VncCursor(
    internal val ptr: Pointer /* rvnc_cursor_t */
): AutoCloseable {
    private var _isClosed = false
    private var _pixelData: Pointer? = null

    val empty: Boolean
        get() = RoyalVNCKit.rvnc_cursor_is_empty_get(ptr)

    val width: Short
        get() = RoyalVNCKit.rvnc_cursor_size_width_get(ptr)

    val height: Short
        get() = RoyalVNCKit.rvnc_cursor_size_height_get(ptr)

    val hotspotX: Short
        get() = RoyalVNCKit.rvnc_cursor_hotspot_x_get(ptr)

    val hotspotY: Short
        get() = RoyalVNCKit.rvnc_cursor_hotspot_y_get(ptr)

    val bitsPerComponent: Long
        get() = RoyalVNCKit.rvnc_cursor_bits_per_component_get(ptr)

    val bitsPerPixel: Long
        get() = RoyalVNCKit.rvnc_cursor_bits_per_pixel_get(ptr)

    val bytesPerPixel: Long
        get() = RoyalVNCKit.rvnc_cursor_bytes_per_pixel_get(ptr)

    val bytesPerRow: Long
        get() = RoyalVNCKit.rvnc_cursor_bytes_per_row_get(ptr)

    val pixelData: Pointer?
        get() {
            val size = pixelDataSize

            if (size <= 0) {
                return null
            }

            if (_pixelData == null) {
                _pixelData = RoyalVNCKit.rvnc_cursor_pixel_data_get_copy(ptr)
            }

            return _pixelData
        }

    val pixelDataSize: Long
        get() = RoyalVNCKit.rvnc_cursor_pixel_data_size_get(ptr)

    fun getBitmap(): Bitmap {
        val buffer = ByteBuffer.allocateDirect(pixelDataSize.toInt())

        val bitmap = createBitmap(
            width.toInt(),
            height.toInt(),
            Bitmap.Config.ARGB_8888
        )

        RoyalVNCKit.rvnc_cursor_copy_pixel_data_to_rgba32_buffer(
            ptr,
            buffer
        )

        bitmap.copyPixelsFromBuffer(buffer)

        return bitmap
    }

    override fun close() {
        if (_isClosed) {
            return
        }

        _isClosed = true

        _pixelData?.let {
            RoyalVNCKit.rvnc_cursor_pixel_data_destroy(it)
        }

        _pixelData = null
    }
}
