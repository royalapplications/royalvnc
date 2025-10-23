package com.royalapps.royalvnc

import com.sun.jna.*
import com.sun.jna.ptr.*
import java.nio.ByteBuffer
import android.util.Log

// Enums

enum class VncLogLevel(val rawValue: Int) {
    DEBUG(0),
    INFO(1),
    WARNING(2),
    ERROR(3);

    companion object {
        operator fun invoke(value: Int): VncLogLevel {
            val valueKt = VncLogLevel.entries.find { it.rawValue == value }

            valueKt?.let {
                return it
            } ?: throw Exception("Invalid VncLogLevel enum raw value: $value")
        }
    }
}

enum class VncConnectionStatus(val rawValue: Int) {
    DISCONNECTED(0),
    CONNECTING(1),
    CONNECTED(2),
    DISCONNECTING(3);

    companion object {
        operator fun invoke(value: Int): VncConnectionStatus {
            val valueKt = VncConnectionStatus.entries.find { it.rawValue == value }

            valueKt?.let {
                return it
            } ?: throw Exception("Invalid VncConnectionStatus enum raw value: $value")
        }
    }
}

enum class VncInputMode(val rawValue: Int) {
    NONE(0),
    FORWARDKEYBOARDSHORTCUTSIFNOTINUSELOCALLY(1),
    FORWARDKEYBOARDSHORTCUTSEVENIFINUSELOCALLY(2),
    FORWARDALLKEYBOARDSHORTCUTSANDHOTKEYS(3);

    companion object {
        operator fun invoke(value: Int): VncInputMode {
            val valueKt = VncInputMode.entries.find { it.rawValue == value }

            valueKt?.let {
                return it
            } ?: throw Exception("Invalid VncInputMode enum raw value: $value")
        }
    }
}

enum class VncColorDepth(val rawValue: Int) {
    BIT8(8), // 256 Colors
    BIT16(16),
    BIT24(24);

    companion object {
        operator fun invoke(value: Int): VncColorDepth {
            val valueKt = VncColorDepth.entries.find { it.rawValue == value }

            valueKt?.let {
                return it
            } ?: throw Exception("Invalid VncColorDepth enum raw value: $value")
        }
    }
}

enum class VncAuthenticationType(val rawValue: Int) {
    VNC(0),
    APPLEREMOTEDESKTOP(1),
    ULTRAVNCMSLOGONII(2);

    companion object {
        operator fun invoke(value: Int): VncAuthenticationType {
            val valueKt = VncAuthenticationType.entries.find { it.rawValue == value }

            valueKt?.let {
                return it
            } ?: throw Exception("Invalid VncAuthenticationType enum raw value: $value")
        }
    }

    val requiresUsername: Boolean
        get() = RoyalVNCKit.rvnc_authentication_type_requires_username(rawValue)

    val requiresPassword: Boolean
        get() = RoyalVNCKit.rvnc_authentication_type_requires_password(rawValue)
}

enum class VncMouseButton(val rawValue: Int) {
    LEFT(0),
    MIDDLE(1),
    RIGHT(2);

    companion object {
        operator fun invoke(value: Int): VncMouseButton {
            val valueKt = VncMouseButton.entries.find { it.rawValue == value }

            valueKt?.let {
                return it
            } ?: throw Exception("Invalid VncMouseButton enum raw value: $value")
        }
    }
}

enum class VncMouseWheel(val rawValue: Int) {
    LEFT(0),
    RIGHT(1),
    UP(2),
    DOWN(3);

    companion object {
        operator fun invoke(value: Int): VncMouseWheel {
            val valueKt = VncMouseWheel.entries.find { it.rawValue == value }

            valueKt?.let {
                return it
            } ?: throw Exception("Invalid VncMouseWheel enum raw value: $value")
        }
    }
}

object RoyalVNCKit {
    // Library Declaration

    init {
        val nativeLibName = "RoyalVNCKit"

        try {
            Native.register(RoyalVNCKit::class.java, nativeLibName)
        } catch (e: Throwable) {
            Log.e("[${nativeLibName}]", "Error while loading native library", e)
        }

    }


    // Logger
    interface rvnc_logger_delegate_log : Callback {
        fun log(
            logger: Pointer, /* rvnc_logger_t */
            context: Pointer?, /* rvnc_context_t */
            logLevel: Int /* VncLogLevel */,
            message: String
        )
    }

    external fun rvnc_logger_create(
        log: rvnc_logger_delegate_log,
        context: Pointer? /* rvnc_context_t */
    ): Pointer /* rvnc_logger_t */

    external fun rvnc_logger_destroy(
        logger: Pointer /* rvnc_logger_t */
    )

    // Authentication Type
    external fun rvnc_authentication_type_requires_username(
        authenticationType: Int /* VncAuthenticationType */
    ): Boolean

    external fun rvnc_authentication_type_requires_password(
        authenticationType: Int /* VncAuthenticationType */
    ): Boolean


    // Authentication Request

    external fun rvnc_authentication_request_authentication_type_get(
        authenticationRequest: Pointer /* rvnc_authentication_request_t */
    ): Int /* VncAuthenticationType */

    external fun rvnc_authentication_request_cancel(
        authenticationRequest: Pointer /* rvnc_authentication_request_t */
    )

    external fun rvnc_authentication_request_complete_with_username_password(
        authenticationRequest: Pointer /* rvnc_authentication_request_t */,
        username: String,
        password: String
    )

    external fun rvnc_authentication_request_complete_with_password(
        authenticationRequest: Pointer /* rvnc_authentication_request_t */,
        password: String
    )


    // Settings
    external fun rvnc_settings_create(
        isDebugLoggingEnabled: Boolean,
        hostname: String,
        port: Short /* uint16_t */,
        isShared: Boolean,
        isScalingEnabled: Boolean,
        useDisplayLink: Boolean,
        inputMode: Int /* VncInputMode */,
        isClipboardRedirectionEnabled: Boolean,
        colorDepth: Int /* VncColorDepth */
    ): Pointer /* rvnc_settings_t */

    external fun rvnc_settings_destroy(
        settings: Pointer /* rvnc_settings_t */
    )


    // Connection State

    external fun rvnc_connection_state_destroy(
        connectionState: Pointer /* rvnc_connection_state_t */
    )

    external fun rvnc_connection_state_status_get(
        connectionState: Pointer /* rvnc_connection_state_t */
    ): Int /* VncConnectionStatus */

    external fun rvnc_connection_state_error_description_get_copy(
        connectionState: Pointer /* rvnc_connection_state_t */
    ): String?

    external fun rvnc_connection_state_error_should_display_to_user_get(
        connectionState: Pointer /* rvnc_connection_state_t */
    ): Boolean

    external fun rvnc_connection_state_error_is_authentication_error_get(
        connectionState: Pointer /* rvnc_connection_state_t */
    ): Boolean


    // Framebuffer

    external fun rvnc_framebuffer_size_width_get(
        framebuffer: Pointer /* rvnc_framebuffer_t */
    ): Short /* uint16_t */

    external fun rvnc_framebuffer_size_height_get(
        framebuffer: Pointer /* rvnc_framebuffer_t */
    ): Short /* uint16_t */

    /// NOTE: This always returns 32-bit BGRA data.
    external fun rvnc_framebuffer_pixel_data_get(
        framebuffer: Pointer /* rvnc_framebuffer_t */
    ): Pointer /* void* */

    external fun rvnc_framebuffer_pixel_data_size_get(
        framebuffer: Pointer /* rvnc_framebuffer_t */
    ): Long /* uint64_t */

    external fun rvnc_framebuffer_pixel_data_rgba32_get_copy(
        framebuffer: Pointer /* rvnc_framebuffer_t */,
        pixelDataSize: LongByReference? /* uint64_t* _Nullable */
    ): Pointer /* void* */

    external fun rvnc_framebuffer_pixel_data_rgba32_destroy(
        framebuffer: Pointer /* rvnc_framebuffer_t */,
        buffer: Pointer /* void* */
    )

    external fun rvnc_framebuffer_copy_pixel_data_to_rgba32_buffer(
        framebuffer: Pointer /* rvnc_framebuffer_t */,
        destinationPixelBuffer: ByteBuffer /* void* */
    )


    // Cursor

    external fun rvnc_cursor_is_empty_get(
        cursor: Pointer /* rvnc_cursor_t */
    ): Boolean

    external fun rvnc_cursor_size_width_get(
        cursor: Pointer /* rvnc_cursor_t */
    ): Short /* uint16_t */

    external fun rvnc_cursor_size_height_get(
        cursor: Pointer /* rvnc_cursor_t */
    ): Short /* uint16_t */

    external fun rvnc_cursor_hotspot_x_get(
        cursor: Pointer /* rvnc_cursor_t */
    ): Short /* uint16_t */

    external fun rvnc_cursor_hotspot_y_get(
        cursor: Pointer /* rvnc_cursor_t */
    ): Short /* uint16_t */

    external fun rvnc_cursor_bits_per_component_get(
        cursor: Pointer /* rvnc_cursor_t */
    ): Long /* int64_t */

    external fun rvnc_cursor_bits_per_pixel_get(
        cursor: Pointer /* rvnc_cursor_t */
    ): Long /* int64_t */

    external fun rvnc_cursor_bytes_per_pixel_get(
        cursor: Pointer /* rvnc_cursor_t */
    ): Long /* int64_t */

    external fun rvnc_cursor_bytes_per_row_get(
        cursor: Pointer /* rvnc_cursor_t */
    ): Long /* int64_t */

    external fun rvnc_cursor_pixel_data_get_copy(
        cursor: Pointer /* rvnc_cursor_t */
    ): Pointer? /* void* */

    external fun rvnc_cursor_pixel_data_destroy(
        cursor: Pointer /* rvnc_cursor_t */
    )

    external fun rvnc_cursor_pixel_data_size_get(
        cursor: Pointer /* rvnc_cursor_t */
    ): Long /* uint64_t */


    // Connection Delegate

    interface rvnc_connection_delegate_connection_state_did_change : Callback {
        fun connectionStateDidChange(
            connection: Pointer /* rvnc_connection_t */,
            context: Pointer? /* rvnc_context_t */,
            connectionState: Pointer /* rvnc_connection_state_t */
        )
    }

    interface rvnc_connection_delegate_authenticate : Callback {
        fun authenticate(
            connection: Pointer /* rvnc_connection_t */,
            context: Pointer? /* rvnc_context_t */,
            authenticationRequest: Pointer /* rvnc_authentication_request_t */
        )
    }

    interface rvnc_connection_delegate_did_create_framebuffer : Callback {
        fun didCreateFramebuffer(
            connection: Pointer /* rvnc_connection_t */,
            context: Pointer? /* rvnc_context_t */,
            framebuffer: Pointer /* rvnc_framebuffer_t */
        )
    }

    interface rvnc_connection_delegate_did_resize_framebuffer : Callback {
        fun didResizeFramebuffer(
            connection: Pointer /* rvnc_connection_t */,
            context: Pointer? /* rvnc_context_t */,
            framebuffer: Pointer /* rvnc_framebuffer_t */
        )
    }

    interface rvnc_connection_delegate_did_update_framebuffer : Callback {
        fun didUpdateFramebuffer(
            connection: Pointer /* rvnc_connection_t */,
            context: Pointer? /* rvnc_context_t */,
            framebuffer: Pointer /* rvnc_framebuffer_t */,
            x: Short /* uint16_t */,
            y: Short /* uint16_t */,
            width: Short /* uint16_t */,
            height: Short /* uint16_t */
        )
    }

    interface rvnc_connection_delegate_did_update_cursor : Callback {
        fun didUpdateCursor(
            connection: Pointer /* rvnc_connection_t */,
            context: Pointer? /* rvnc_context_t */,
            cursor: Pointer /* rvnc_cursor_t */
        )
    }

    external fun rvnc_connection_delegate_create(
        connectionStateDidChange: rvnc_connection_delegate_connection_state_did_change,
        authenticate: rvnc_connection_delegate_authenticate,
        didCreateFramebuffer: rvnc_connection_delegate_did_create_framebuffer,
        didResizeFramebuffer: rvnc_connection_delegate_did_resize_framebuffer,
        didUpdateFramebuffer: rvnc_connection_delegate_did_update_framebuffer,
        didUpdateCursor: rvnc_connection_delegate_did_update_cursor
    ): Pointer /* rvnc_connection_delegate_t */

    external fun rvnc_connection_delegate_destroy(
        connectionDelegate: Pointer /* rvnc_connection_delegate_t */
    )


    // Connection

    external fun rvnc_connection_create(
        settings: Pointer /* rvnc_settings_t */,
        logger: Pointer? /* rvnc_logger_t */,
        framebufferAllocator: Pointer? /* rvnc_framebuffer_allocator_t */,
        context: Pointer? /* rvnc_context_t */
    ): Pointer /* rvnc_connection_t */

    external fun rvnc_connection_destroy(
        connection: Pointer /* rvnc_connection_t */
    )

    external fun rvnc_connection_connect(
        connection: Pointer /* rvnc_connection_t */
    )

    external fun rvnc_connection_disconnect(
        connection: Pointer /* rvnc_connection_t */
    )

    external fun rvnc_connection_update_color_depth(
        connection: Pointer /* rvnc_connection_t */,
        colorDepth: Int /* VncColorDepth */
    )

    external fun rvnc_connection_delegate_set(
        connection: Pointer /* rvnc_connection_t */,
        connectionDelegate: Pointer? /* rvnc_connection_delegate_t */
    )

    external fun rvnc_connection_context_get(
        connection: Pointer /* rvnc_connection_t */
    ): Pointer? /* rvnc_context_t */

    external fun rvnc_connection_state_get_copy(
        connection: Pointer /* rvnc_connection_t */
    ): Pointer /* rvnc_connection_state_t */

    external fun rvnc_connection_settings_get_copy(
        connection: Pointer /* rvnc_connection_t */
    ): Pointer /* rvnc_settings_t */

    external fun rvnc_connection_mouse_move(
        connection: Pointer /* rvnc_connection_t */,
        x: Short /* uint16_t */,
        y: Short /* uint16_t */
    )

    external fun rvnc_connection_mouse_down(
        connection: Pointer /* rvnc_connection_t */,
        button: Int /* VncMouseButton */,
        x: Short /* uint16_t */,
        y: Short /* uint16_t */
    )

    external fun rvnc_connection_mouse_up(
        connection: Pointer /* rvnc_connection_t */,
        button: Int /* VncMouseButton */,
        x: Short /* uint16_t */,
        y: Short /* uint16_t */
    )

    external fun rvnc_connection_mouse_wheel(
        connection: Pointer /* rvnc_connection_t */,
        wheel: Int /* VncMouseWheel */,
        x: Short /* uint16_t */,
        y: Short /* uint16_t */,
        steps: Int /* uint32_t */
    )

    // NOTE: key is an X11 keysym (eg. `XK_A` for the latin capital letter "A"). See the `X11KeySymbols` struct.
    external fun rvnc_connection_key_down(
        connection: Pointer /* rvnc_connection_t */,
        key: Int /* uint32_t */
    )

    external fun rvnc_connection_key_up(
        connection: Pointer /* rvnc_connection_t */,
        key: Int /* uint32_t */
    )
}