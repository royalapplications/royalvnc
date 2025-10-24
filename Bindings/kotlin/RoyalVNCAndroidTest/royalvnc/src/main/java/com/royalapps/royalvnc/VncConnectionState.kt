package com.royalapps.royalvnc

import com.sun.jna.*

data class VncConnectionState(
    internal val ptr: Pointer /* rvnc_connection_state_t */,
    internal val owned: Boolean
): AutoCloseable {
    val status: VncConnectionStatus
        get() {
            val statusRawValue = RoyalVNCKit.rvnc_connection_state_status_get(ptr)
            val statusKt = VncConnectionStatus(statusRawValue)

            return statusKt
        }

    val errorDescription: String?
        get() = RoyalVNCKit.rvnc_connection_state_error_description_get_copy(ptr)

    val shouldDisplayToUser: Boolean
        get() = RoyalVNCKit.rvnc_connection_state_error_should_display_to_user_get(ptr)

    val isAuthenticationError: Boolean
        get() = RoyalVNCKit.rvnc_connection_state_error_is_authentication_error_get(ptr)

    override fun close() {
        if (owned) {
            RoyalVNCKit.rvnc_connection_state_destroy(ptr)
        }
    }
}
