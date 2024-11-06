using System;
using System.Diagnostics;

namespace RoyalApps.RoyalVNCKit;

public sealed class AuthenticationRequest
{
    public AuthenticationType AuthenticationType { get; }
    public bool RequiresUsername { get; }
    public bool RequiresPassword { get; }
    public string? Username { get; set; }
    public string? Password { get; set; }

    internal AuthenticationRequest(
        AuthenticationType authenticationType,
        bool requiresUsername,
        bool requiresPassword
    )
    {
        Debug.Assert(Enum.IsDefined(authenticationType));
        AuthenticationType = authenticationType;
        RequiresUsername = requiresUsername;
        RequiresPassword = requiresPassword;
    }
}
