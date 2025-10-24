package com.royalapps.royalvnc

interface VncConnectionDelegate {
    fun connectionStateDidChange(
        connection: VncConnection,
        connectionState: VncConnectionState
    )

    fun authenticate(
        connection: VncConnection,
        authenticationRequest: VncAuthenticationRequest
    )

    fun didCreateFramebuffer(
        connection: VncConnection,
        framebuffer: VncFramebuffer
    )

    fun didResizeFramebuffer(
        connection: VncConnection,
        framebuffer: VncFramebuffer
    )

    fun didUpdateFramebuffer(
        connection: VncConnection,
        framebuffer: VncFramebuffer,
        x: Short,
        y: Short,
        width: Short,
        height: Short
    )

    fun didUpdateCursor(
        connection: VncConnection,
        cursor: VncCursor
    )
}