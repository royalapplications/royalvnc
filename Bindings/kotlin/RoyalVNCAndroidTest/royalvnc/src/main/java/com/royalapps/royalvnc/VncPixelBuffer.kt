package com.royalapps.royalvnc

import android.graphics.Bitmap
import androidx.core.graphics.createBitmap
import java.nio.ByteBuffer

class VncPixelBuffer(framebuffer: VncFramebuffer) {
    private val buffer = ByteBuffer.allocateDirect(framebuffer.pixelDataSize.toInt())
    private val width = framebuffer.width.toInt()
    private val height = framebuffer.height.toInt()

    private var bitmap = createBitmap(
        width,
        height,
        Bitmap.Config.ARGB_8888
    )

    fun getBitmap(framebuffer: VncFramebuffer): Bitmap {
        buffer.rewind()

        framebuffer.copyPixelDataToRGBA32Buffer(buffer)
        bitmap.copyPixelsFromBuffer(buffer)

        return bitmap
    }
}

class VncCursorPixelBuffer(cursor: VncCursor) {
    private val buffer = ByteBuffer.allocateDirect(cursor.pixelDataSize.toInt())
    private val width = cursor.width.toInt()
    private val height = cursor.height.toInt()

    private var bitmap = createBitmap(
        width,
        height,
        Bitmap.Config.ARGB_8888
    )

    fun getBitmap(cursor: VncCursor): Bitmap {
        buffer.rewind()

        cursor.copyPixelDataToRGBA32Buffer(buffer)
        bitmap.copyPixelsFromBuffer(buffer)

        return bitmap
    }
}
