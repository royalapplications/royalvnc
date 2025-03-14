package com.example.royalvncandroidtest

import android.graphics.*
import java.nio.*
import androidx.core.graphics.createBitmap

class PixelUtils {
    companion object {
        // TODO: This is certainly very slow
        fun bgraBufferToBitmap(
            bgraData: ByteBuffer,
            width: Int,
            height: Int
        ): Bitmap {
            val pixelCount = width * height
            val pixels = IntArray(pixelCount)

            for (i in 0 until pixelCount) {
                val bgraIndex = i * 4
                val b = bgraData[bgraIndex].toInt() and 0xFF
                val g = bgraData[bgraIndex + 1].toInt() and 0xFF
                val r = bgraData[bgraIndex + 2].toInt() and 0xFF
                val a = bgraData[bgraIndex + 3].toInt() and 0xFF
                pixels[i] = (a shl 24) or (r shl 16) or (g shl 8) or b
            }

            val bitmap = createBitmap(
                width,
                height
            )

            bitmap.setPixels(
                pixels,
                0,
                width,
                0,
                0,
                width,
                height
            )

            return bitmap
        }
    }
}