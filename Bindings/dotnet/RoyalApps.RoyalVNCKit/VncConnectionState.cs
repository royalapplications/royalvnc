using System;
using System.Runtime.InteropServices;
using static RoyalApps.RoyalVNCKit.RoyalVNCKit;

namespace RoyalApps.RoyalVNCKit;

[StructLayout(LayoutKind.Auto)]
public readonly unsafe ref struct VncConnectionState
{
    readonly void* _instance;

    internal VncConnectionState(void* instance)
    {
        ArgumentNullException.ThrowIfNull(instance);
        _instance = instance;
    }

    public ConnectionStatus Status => rvnc_connection_state_status_get(_instance);
    public string? ErrorDescription => rvnc_connection_state_error_description_get_copy(_instance);
    public bool DisplayErrorToUser => rvnc_connection_state_error_should_display_to_user_get(_instance).FromNativeBool();
    public bool IsAuthenticationError => rvnc_connection_state_error_is_authentication_error_get(_instance).FromNativeBool();

    internal void Dispose() => rvnc_connection_state_destroy(_instance);
}
