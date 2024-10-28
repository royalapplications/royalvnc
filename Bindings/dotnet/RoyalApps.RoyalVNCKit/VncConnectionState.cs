using System;
using System.Runtime.InteropServices;

namespace RoyalApps.RoyalVNCKit;

[StructLayout(LayoutKind.Auto)]
readonly unsafe ref struct VncConnectionState
{
    readonly void* _instance;

    internal VncConnectionState(void* instance)
    {
        ArgumentNullException.ThrowIfNull(instance);
        _instance = instance;
    }

    internal ConnectionStatus Status => RoyalVNCKit.rvnc_connection_state_status_get(_instance);
    internal string? ErrorDescription => RoyalVNCKit.rvnc_connection_state_error_description_get_copy(_instance);
    internal bool DisplayErrorToUser => RoyalVNCKit.rvnc_connection_state_error_should_display_to_user_get(_instance).FromNativeBool();
    internal bool IsAuthenticationError => RoyalVNCKit.rvnc_connection_state_error_is_authentication_error_get(_instance).FromNativeBool();

    internal void Dispose() => RoyalVNCKit.rvnc_connection_state_destroy(_instance);
}
