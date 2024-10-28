using System;

namespace RoyalApps.RoyalVNCKit;

public sealed unsafe class VncConnection: IDisposable
{
    bool _isDisposed;
    void* _instance;

    VncConnection(void* instance)
    {
        ArgumentNullException.ThrowIfNull(instance);
        _instance = instance;
    }

    public VncConnection(VncSettings settings) : this(CreateInstance(settings))
    {
        Context!.Connection = this;
    }

    static void* CreateInstance(VncSettings settings)
    {
        ArgumentNullException.ThrowIfNull(settings);
        var context = new VncContext();
        var logger = new VncLogger(context);
        context.Logger = logger;
        return RoyalVNCKit.rvnc_connection_create(settings.Instance, logger.Instance, context.Instance);
    }

    VncContext? Context
    {
        get
        {
            ObjectDisposedException.ThrowIf(_isDisposed || _instance is null, this);

            var contextInstance = RoyalVNCKit.rvnc_connection_context_get(_instance);

            if (contextInstance is null)
                return null;

            var context = VncContext.FromPointer(contextInstance);

            return context;
        }
    }

    public ConnectionStatus Status
    {
        get
        {
            ObjectDisposedException.ThrowIf(_isDisposed || _instance is null, this);

            void* nativeState = RoyalVNCKit.rvnc_connection_state_get_copy(_instance);
            using var holder = new VncConnectionState(nativeState);
            
            return holder.Status;
        }
    }
    
    public VncConnectionDelegate? Delegate
    {
        set
        {
            ObjectDisposedException.ThrowIf(_isDisposed || _instance is null, this);
    
            var val = value is not null ? value.Instance : null;
    
            var context = Context;
    
            if (context is not null)
                context.ConnectionDelegate = value;
    
            RoyalVNCKit.rvnc_connection_delegate_set(_instance, val);
        }
    }
    
    public void Connect()
    {
        ObjectDisposedException.ThrowIf(_isDisposed || _instance is null, this);
    
        RoyalVNCKit.rvnc_connection_connect(_instance);
    }
    
    public void Disconnect()
    {
        ObjectDisposedException.ThrowIf(_isDisposed || _instance is null, this);
    
        RoyalVNCKit.rvnc_connection_disconnect(_instance);
    }
    
    public void SendKeyDown(KeySymbol key)
    {
        ObjectDisposedException.ThrowIf(_isDisposed || _instance is null, this);

        RoyalVNCKit.rvnc_connection_key_down(_instance, key);
    }
    
    public void SendKeyUp(KeySymbol key)
    {
        ObjectDisposedException.ThrowIf(_isDisposed || _instance is null, this);

        RoyalVNCKit.rvnc_connection_key_up(_instance, key);
    }
    
    public void SendMouseButtonDown(double x, double y, MouseButton button)
    {
        ObjectDisposedException.ThrowIf(_isDisposed || _instance is null, this);
        
        switch (button)
        {
        case MouseButton.Left:
            RoyalVNCKit.rvnc_connection_mouse_down(_instance, x, y);
            return;

        case MouseButton.Right:
            RoyalVNCKit.rvnc_connection_right_mouse_down(_instance, x, y);
            return;
        
        case MouseButton.Middle:
            RoyalVNCKit.rvnc_connection_middle_mouse_down(_instance, x, y);
            return;
        
        default:
            throw new ArgumentOutOfRangeException(nameof(button));
        }
    }
    
    public void SendMouseButtonUp(double x, double y, MouseButton button)
    {
        ObjectDisposedException.ThrowIf(_isDisposed || _instance is null, this);
    
        switch (button)
        {
        case MouseButton.Left:
            RoyalVNCKit.rvnc_connection_mouse_up(_instance, x, y);
            return;

        case MouseButton.Right:
            RoyalVNCKit.rvnc_connection_right_mouse_up(_instance, x, y);
            return;
        
        case MouseButton.Middle:
            RoyalVNCKit.rvnc_connection_middle_mouse_up(_instance, x, y);
            return;
        
        default:
            throw new ArgumentOutOfRangeException(nameof(button));
        }
    }
    
    public void SendMouseMove(double x, double y)
    {
        ObjectDisposedException.ThrowIf(_isDisposed || _instance is null, this);
    
        RoyalVNCKit.rvnc_connection_mouse_move(_instance, x, y);
    }
    
    public void SendMouseScroll(double x, double y, double scrollWheelDeltaX, double scrollWheelDeltaY)
    {
        ObjectDisposedException.ThrowIf(_isDisposed || _instance is null, this);

        //TODO: RoyalVNCKit.rvnc_connection_mouse_wheel_down();
        throw new NotImplementedException("TODO");
    }

    public void Dispose()
    {
        if (_isDisposed)
            return;

        var context = Context;

        context?.Dispose();

        _isDisposed = true;

        if (_instance is null)
            return;

        RoyalVNCKit.rvnc_connection_destroy(_instance);
        _instance = null;
    }
}
