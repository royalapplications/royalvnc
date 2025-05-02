using System;
using System.Diagnostics;
using System.Diagnostics.CodeAnalysis;
using static RoyalApps.RoyalVNCKit.RoyalVNCKit;

namespace RoyalApps.RoyalVNCKit;

public delegate void VncConnectionStateChangedHandler(
    VncConnection connection,
    VncConnectionState state
);

public delegate bool VncAuthenticationRequestedHandler(
    VncConnection connection,
    AuthenticationRequest request
);

public delegate void VncCursorUpdatedHandler(
    VncConnection connection,
    VncCursor cursor
);

public delegate void VncFramebufferCreatedHandler(
    VncConnection connection,
    VncFramebuffer framebuffer
);

public delegate void VncFramebufferResizedHandler(
    VncConnection connection,
    VncFramebuffer framebuffer
);

public delegate void VncFramebufferUpdatedHandler(
    VncConnection connection,
    VncFramebuffer framebuffer,
    VncFramebufferRegion region
);

public sealed unsafe class VncConnectionDelegate: IDisposable
{
    bool _isDisposed;
    internal void* Instance { get; private set; }

    public VncConnectionStateChangedHandler? ConnectionStateChanged { get; set; }
    public VncAuthenticationRequestedHandler? AuthenticationRequested { get; set; }
    public VncCursorUpdatedHandler? CursorUpdated { get; set; }
    public VncFramebufferCreatedHandler? FramebufferCreated { get; set; }
    public VncFramebufferResizedHandler? FramebufferResized { get; set; }
    public VncFramebufferUpdatedHandler? FramebufferUpdated { get; set; }

    VncConnectionDelegate(void* instance)
    {
        ArgumentNullException.ThrowIfNull(instance);
        Instance = instance;
    }

    public VncConnectionDelegate() : this(
        rvnc_connection_delegate_create(
            connectionStateDidChange: ConnectionStateDidChangeHandler,
            authenticate: AuthenticateHandler,
            didCreateFramebuffer: DidCreateFramebufferHandler,
            didResizeFramebuffer: DidResizeFramebufferHandler,
            didUpdateFramebuffer: DidUpdateFramebufferHandler,
            didUpdateCursor: DidUpdateCursorHandler
        )
    )
    { }

    public void Dispose()
    {
        if (_isDisposed)
            return;

        _isDisposed = true;

        if (Instance is null)
            return;

        rvnc_connection_delegate_destroy(Instance);
        Instance = null;
    }

    static bool TryGetConnectionAndDelegate(
        void* context,
        [NotNullWhen(true)] out VncConnection? connection,
        [NotNullWhen(true)] out VncConnectionDelegate? connectionDelegate
    )
    {
        var vncContext = VncContext.FromPointer(context);

        if (vncContext is null)
        {
            connection = null;
            connectionDelegate = null;

            return false;
        }

        connection = vncContext.Connection;
        connectionDelegate = vncContext.ConnectionDelegate;

        return connection is not null && connectionDelegate is not null;
    }

    static readonly ConnectionStateDidChangeDelegate ConnectionStateDidChangeHandler = ConnectionStateDidChange;
    static void ConnectionStateDidChange(
        void* connection,
        void* context,
        void* connectionState
    )
    {
        if (!TryGetConnectionAndDelegate(context, out var vncConnection, out var vncConnectionDelegate)
            || vncConnectionDelegate is not { ConnectionStateChanged: {} handler })
            return;

        var state = new VncConnectionState(connectionState);
        handler.Invoke(vncConnection, state);
    }

    static readonly AuthenticateDelegate AuthenticateHandler = Authenticate;
    static void Authenticate(
        void* connection,
        void* context,
        void* authenticationRequest
    )
    {
        if (!TryGetConnectionAndDelegate(context, out var vncConnection, out var vncConnectionDelegate)
            || vncConnectionDelegate is not { AuthenticationRequested: { } handler })
        {
            rvnc_authentication_request_cancel(authenticationRequest);
            return;
        }

        var authType = rvnc_authentication_request_authentication_type_get(authenticationRequest);
        bool requiresUsername = rvnc_authentication_type_requires_username(authType).FromNativeBool();
        bool requiresPassword = rvnc_authentication_type_requires_password(authType).FromNativeBool();

        var request = new AuthenticationRequest(authType, requiresUsername, requiresPassword);

        if (!handler.Invoke(vncConnection, request) || (request.Username is null && request.Password is null))
        {
            rvnc_authentication_request_cancel(authenticationRequest);
            return;
        }

        Debug.Assert(request.RequiresPassword);

        if (request.RequiresUsername)
            rvnc_authentication_request_complete_with_username_password(authenticationRequest, request.Username ?? "", request.Password ?? "");
        else
            rvnc_authentication_request_complete_with_password(authenticationRequest, request.Password ?? "");
    }

    static readonly DidUpdateCursorDelegate DidUpdateCursorHandler = DidUpdateCursor;
    static void DidUpdateCursor(
        void* connection,
        void* context,
        void* cursor
    )
    {
        if (!TryGetConnectionAndDelegate(context, out var vncConnection, out var vncConnectionDelegate)
            || vncConnectionDelegate is not { CursorUpdated: { } handler })
            return;

        var vncCursor = new VncCursor(cursor);
        handler.Invoke(vncConnection, vncCursor);
    }

    static readonly DidCreateFramebufferDelegate DidCreateFramebufferHandler = DidCreateFramebuffer;
    static void DidCreateFramebuffer(
        void* connection,
        void* context,
        void* framebuffer
    )
    {
        if (!TryGetConnectionAndDelegate(context, out var vncConnection, out var vncConnectionDelegate)
            || vncConnectionDelegate is not { FramebufferCreated: { } handler })
            return;

        var vncFramebuffer = new VncFramebuffer(framebuffer);
        handler.Invoke(vncConnection, vncFramebuffer);
    }

    static readonly DidResizeFramebufferDelegate DidResizeFramebufferHandler = DidResizeFramebuffer;
    static void DidResizeFramebuffer(
        void* connection,
        void* context,
        void* framebuffer
    )
    {
        if (!TryGetConnectionAndDelegate(context, out var vncConnection, out var vncConnectionDelegate)
            || vncConnectionDelegate is not { FramebufferResized: { } handler })
            return;

        var vncFramebuffer = new VncFramebuffer(framebuffer);
        handler.Invoke(vncConnection, vncFramebuffer);
    }

    static readonly DidUpdateFramebufferDelegate DidUpdateFramebufferHandler = DidUpdateFramebuffer;
    static void DidUpdateFramebuffer(
        void* connection,
        void* context,
        void* framebuffer,
        ushort x,
        ushort y,
        ushort width,
        ushort height
    )
    {
        if (!TryGetConnectionAndDelegate(context, out var vncConnection, out var vncConnectionDelegate)
            || vncConnectionDelegate is not { FramebufferUpdated: { } handler })
            return;

        var vncFramebuffer = new VncFramebuffer(framebuffer);
        var vncRegion = new VncFramebufferRegion(x, y, width, height);
        handler.Invoke(vncConnection, vncFramebuffer, vncRegion);
    }
}
