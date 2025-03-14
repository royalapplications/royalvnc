package com.royalapps.royalvnc

import com.sun.jna.*

data class VncAuthenticationRequest(
    internal val ptr: Pointer
) {
    val authenticationType: VncAuthenticationType
        get() {
            val value = RoyalVNCKit.rvnc_authentication_request_authentication_type_get(ptr)
            val valueKt = VncAuthenticationType(value)

            return valueKt
        }

    val requiresUsername: Boolean
        get() = authenticationType.requiresUsername

    val requiresPassword: Boolean
        get() = authenticationType.requiresPassword

    fun cancel() {
        RoyalVNCKit.rvnc_authentication_request_cancel(ptr)
    }

    fun completeWithUsernameAndPassword(
        username: String,
        password: String
    ) {
        RoyalVNCKit.rvnc_authentication_request_complete_with_username_password(
            ptr,
            username,
            password
        )
    }

    fun completeWithPassword(
        password: String
    ) {
        RoyalVNCKit.rvnc_authentication_request_complete_with_password(
            ptr,
            password
        )
    }
}
