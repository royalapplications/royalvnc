package com.royalapps.royalvnc

import com.sun.jna.*
import java.lang.ref.WeakReference

data class VncConnection(
    internal val ptr: Pointer,
): AutoCloseable {
    private var _delegate: WeakReference<VncConnectionDelegate>? = null
    private var _nativeDelegate: Pointer? = null

    private var _connectionStateDidChangeHandler: ConnectionStateDidChangeHandler? = null
    private var _authenticateHandler: AuthenticateHandler? = null
    private var _didCreateFramebufferHandler: DidCreateFramebufferHandler? = null
    private var _didResizeFramebufferHandler: DidResizeFramebufferHandler? = null
    private var _didUpdateFramebufferHandler: DidUpdateFramebufferHandler? = null
    private var _didUpdateCursorHandler: DidUpdateCursorHandler? = null

    companion object {
        operator fun invoke(
            settings: VncSettings,
            logger: VncLogger?
        ): VncConnection {
            val ptr = RoyalVNCKit.rvnc_connection_create(
                settings.ptr,
                logger?.ptr,
                null
            )

            return VncConnection(ptr)
        }
    }

    fun setDelegate(
        delegate: WeakReference<VncConnectionDelegate>?
    ) {
        _nativeDelegate?.let {
            RoyalVNCKit.rvnc_connection_delegate_destroy(it)
        }

        _nativeDelegate = null

        _connectionStateDidChangeHandler = null
        _authenticateHandler = null
        _didCreateFramebufferHandler = null
        _didResizeFramebufferHandler = null
        _didUpdateFramebufferHandler = null
        _didUpdateCursorHandler = null

        delegate?.let {
            val weakThis = WeakReference(this)

            val connectionStateDidChangeHandler = ConnectionStateDidChangeHandler(weakThis, delegate)
            _connectionStateDidChangeHandler = connectionStateDidChangeHandler

            val authenticateHandler = AuthenticateHandler(weakThis, delegate)
            _authenticateHandler = authenticateHandler

            val didCreateFramebufferHandler = DidCreateFramebufferHandler(weakThis, delegate)
            _didCreateFramebufferHandler = didCreateFramebufferHandler

            val didResizeFramebufferHandler = DidResizeFramebufferHandler(weakThis, delegate)
            _didResizeFramebufferHandler = didResizeFramebufferHandler

            val didUpdateFramebufferHandler = DidUpdateFramebufferHandler(weakThis, delegate)
            _didUpdateFramebufferHandler = didUpdateFramebufferHandler

            val didUpdateCursorHandler = DidUpdateCursorHandler(weakThis, delegate)
            _didUpdateCursorHandler = didUpdateCursorHandler

            _nativeDelegate = RoyalVNCKit.rvnc_connection_delegate_create(
                connectionStateDidChangeHandler,
                authenticateHandler,
                didCreateFramebufferHandler,
                didResizeFramebufferHandler,
                didUpdateFramebufferHandler,
                didUpdateCursorHandler
            )

            _delegate = delegate
        }

        RoyalVNCKit.rvnc_connection_delegate_set(
            ptr,
            _nativeDelegate
        )
    }

    fun connect() {
        RoyalVNCKit.rvnc_connection_connect(ptr)
    }

    fun disconnect() {
        RoyalVNCKit.rvnc_connection_disconnect(ptr)
    }

    fun updateColorDepth(
        colorDepth: VncColorDepth
    ) {
        RoyalVNCKit.rvnc_connection_update_color_depth(
            ptr,
            colorDepth.rawValue
        )
    }

//    val context: Pointer?
//        get() = RoyalVNCKit.rvnc_connection_context_get(ptr)

    val state: VncConnectionState
        get() {
            val valuePtr = RoyalVNCKit.rvnc_connection_state_get_copy(ptr)
            val value = VncConnectionState(valuePtr, true)

            return value
        }

    val settings: VncSettings
        get() {
            val valuePtr = RoyalVNCKit.rvnc_connection_settings_get_copy(ptr)
            val value = VncSettings(ptr)

            return value
        }

    fun mouseMove(
        x: Short,
        y: Short
    ) {
        RoyalVNCKit.rvnc_connection_mouse_move(
            ptr,
            x,
            y
        )
    }

    fun mouseDown(
        button: VncMouseButton,
        x: Short,
        y: Short
    ) {
        RoyalVNCKit.rvnc_connection_mouse_down(
            ptr,
            button.rawValue,
            x,
            y
        )
    }

    fun mouseUp(
        button: VncMouseButton,
        x: Short,
        y: Short
    ) {
        RoyalVNCKit.rvnc_connection_mouse_up(
            ptr,
            button.rawValue,
            x,
            y
        )
    }

    fun mouseWheel(
        wheel: VncMouseWheel,
        x: Short,
        y: Short,
        steps: Int
    ) {
        RoyalVNCKit.rvnc_connection_mouse_wheel(
            ptr,
            wheel.rawValue,
            x,
            y,
            steps
        )
    }

    fun keyDown(
        key: Int /* X11KeySymbol */
    ) {
        RoyalVNCKit.rvnc_connection_key_down(
            ptr,
            key
        )
    }

    fun keyUp(
        key: Int /* X11KeySymbol */
    ) {
        RoyalVNCKit.rvnc_connection_key_up(
            ptr,
            key
        )
    }

    override fun close() {
        setDelegate(null)

        RoyalVNCKit.rvnc_connection_destroy(ptr)
    }

    // Connection Delegate Implementations
    data class ConnectionStateDidChangeHandler(
        val connection: WeakReference<VncConnection>,
        val delegate: WeakReference<VncConnectionDelegate>
    ): RoyalVNCKit.rvnc_connection_delegate_connection_state_did_change {
        override fun connectionStateDidChange(
            connection: Pointer,
            context: Pointer?,
            connectionState: Pointer
        ) {
            this.connection.let { it.get()?.let { thisConnection ->
                this.delegate.let { it.get()?.let { del ->
                    val connectionStateKt = VncConnectionState(
                        connectionState,
                        false
                    )

                    del.connectionStateDidChange(
                        thisConnection,
                        connectionStateKt
                    )
                }}
            }}
        }
    }

    data class AuthenticateHandler(
        val connection: WeakReference<VncConnection>,
        val delegate: WeakReference<VncConnectionDelegate>
    ): RoyalVNCKit.rvnc_connection_delegate_authenticate {
        override fun authenticate(
            connection: Pointer,
            context: Pointer?,
            authenticationRequest: Pointer
        ) {
            this.connection.let { it.get()?.let { thisConnection ->
                this.delegate.let { it.get()?.let { del ->
                    val authenticationRequestKt = VncAuthenticationRequest(
                        authenticationRequest
                    )

                    del.authenticate(
                        thisConnection,
                        authenticationRequestKt
                    )
                }}
            }}
        }
    }

    data class DidCreateFramebufferHandler(
        val connection: WeakReference<VncConnection>,
        val delegate: WeakReference<VncConnectionDelegate>
    ): RoyalVNCKit.rvnc_connection_delegate_did_create_framebuffer {
        override fun didCreateFramebuffer(
            connection: Pointer,
            context: Pointer?,
            framebuffer: Pointer
        ) {
            this.connection.let { it.get()?.let { thisConnection ->
                this.delegate.let { it.get()?.let { del ->
                    val framebufferKt = VncFramebuffer(
                        framebuffer
                    )

                    del.didCreateFramebuffer(
                        thisConnection,
                        framebufferKt
                    )
                }}
            }}
        }
    }

    data class DidResizeFramebufferHandler(
        val connection: WeakReference<VncConnection>,
        val delegate: WeakReference<VncConnectionDelegate>
    ): RoyalVNCKit.rvnc_connection_delegate_did_resize_framebuffer {
        override fun didResizeFramebuffer(
            connection: Pointer,
            context: Pointer?,
            framebuffer: Pointer
        ) {
            this.connection.let { it.get()?.let { thisConnection ->
                this.delegate.let { it.get()?.let { del ->
                    val framebufferKt = VncFramebuffer(
                        framebuffer
                    )

                    del.didResizeFramebuffer(
                        thisConnection,
                        framebufferKt
                    )
                }}
            }}
        }
    }

    data class DidUpdateFramebufferHandler(
        val connection: WeakReference<VncConnection>,
        val delegate: WeakReference<VncConnectionDelegate>
    ): RoyalVNCKit.rvnc_connection_delegate_did_update_framebuffer {
        override fun didUpdateFramebuffer(
            connection: Pointer,
            context: Pointer?,
            framebuffer: Pointer,
            x: Short,
            y: Short,
            width: Short,
            height: Short
        ) {
            this.connection.let { it.get()?.let { thisConnection ->
                this.delegate.let { it.get()?.let { del ->
                    val framebufferKt = VncFramebuffer(
                        framebuffer
                    )

                    del.didUpdateFramebuffer(
                        thisConnection,
                        framebufferKt,
                        x,
                        y,
                        width,
                        height
                    )
                }}
            }}
        }
    }

    data class DidUpdateCursorHandler(
        val connection: WeakReference<VncConnection>,
        val delegate: WeakReference<VncConnectionDelegate>
    ): RoyalVNCKit.rvnc_connection_delegate_did_update_cursor {
        override fun didUpdateCursor(
            connection: Pointer,
            context: Pointer?,
            cursor: Pointer
        ) {
            this.connection.let { it.get()?.let { thisConnection ->
                this.delegate.let { it.get()?.let { del ->
                    VncCursor(
                        cursor
                    ).use { cursorKt ->
                        del.didUpdateCursor(
                            thisConnection,
                            cursorKt
                        )
                    }
                }}
            }}
        }
    }
}
