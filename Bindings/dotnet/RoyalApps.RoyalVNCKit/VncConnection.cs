using System;
using System.Collections.Concurrent;
using System.Diagnostics;
using static RoyalApps.RoyalVNCKit.RoyalVNCKit;

namespace RoyalApps.RoyalVNCKit;

public sealed unsafe class VncConnection: IDisposable
{
    static readonly ConcurrentDictionary<nuint, VncFramebufferAllocator> FramebufferAllocators = new();

    bool _isDisposed;
    void* _instance;
    void* _framebufferAllocator;

    public VncConnection(VncSettings settings)
    {
        ArgumentNullException.ThrowIfNull(settings);
        _instance = CreateInstance(settings, null);
        Context!.Connection = this;
    }

    public VncConnection(VncSettings settings, VncFramebufferAllocator allocator)
    {
        ArgumentNullException.ThrowIfNull(settings);
        ArgumentNullException.ThrowIfNull(allocator);
        _framebufferAllocator = rvnc_framebuffer_allocator_create(AllocateFramebuffer, DeallocateFramebuffer);
        bool added = FramebufferAllocators.TryAdd((nuint)_framebufferAllocator, allocator);
        Debug.Assert(added);
        _instance = CreateInstance(settings, _framebufferAllocator);
        Context!.Connection = this;
        return;

        static void* AllocateFramebuffer(void* allocator, nuint size)
        {
            if (!FramebufferAllocators.TryGetValue((nuint)allocator, out var dnAllocator))
            {
                Debug.Fail($"Allocator instance for 0x{(nuint)allocator:x} not found");
                return null;
            }

            var span = dnAllocator.Allocate(size);
            Debug.Assert((nuint)span.Length == size);
            fixed (byte* b = span)
                return b;
        }

        static void DeallocateFramebuffer(void* allocator, void* buffer)
        {
            if (!FramebufferAllocators.TryGetValue((nuint)allocator, out var dnAllocator))
            {
                Debug.Fail($"Allocator instance for 0x{(nuint)allocator:x} not found");
                return;
            }

            var span = new ReadOnlySpan<byte>(buffer, 1);
            dnAllocator.Deallocate(span);
        }
    }

    static void* CreateInstance(VncSettings settings, void* framebufferAllocator)
    {
        Debug.Assert(settings is not null);
        var context = new VncContext();
        var logger = new VncLogger(context);
        context.Logger = logger;
        return rvnc_connection_create(settings.Instance, logger.Instance, framebufferAllocator, context.Instance);
    }

    VncContext? Context
    {
        get
        {
            ObjectDisposedException.ThrowIf(_isDisposed || _instance is null, this);

            var contextInstance = rvnc_connection_context_get(_instance);

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

            void* nativeState = rvnc_connection_state_get_copy(_instance);
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

            rvnc_connection_delegate_set(_instance, val);
        }
    }

    public void Connect()
    {
        ObjectDisposedException.ThrowIf(_isDisposed || _instance is null, this);

        rvnc_connection_connect(_instance);
    }

    public void Disconnect()
    {
        ObjectDisposedException.ThrowIf(_isDisposed || _instance is null, this);

        rvnc_connection_disconnect(_instance);
    }

    public void SendKeyDown(KeySymbol key)
    {
        ObjectDisposedException.ThrowIf(_isDisposed || _instance is null, this);

        rvnc_connection_key_down(_instance, key);
    }

    public void SendKeyUp(KeySymbol key)
    {
        ObjectDisposedException.ThrowIf(_isDisposed || _instance is null, this);

        rvnc_connection_key_up(_instance, key);
    }

    public void SendMouseButtonDown(ushort x, ushort y, MouseButton button)
    {
        ObjectDisposedException.ThrowIf(_isDisposed || _instance is null, this);

        if (!Enum.IsDefined(button)) {
            throw new ArgumentOutOfRangeException(nameof(button));
        }

        rvnc_connection_mouse_down(_instance, button, x, y);
    }

    public void SendMouseButtonUp(ushort x, ushort y, MouseButton button)
    {
        ObjectDisposedException.ThrowIf(_isDisposed || _instance is null, this);

        if (!Enum.IsDefined(button)) {
            throw new ArgumentOutOfRangeException(nameof(button));
        }

        rvnc_connection_mouse_up(_instance, button, x, y);
    }

    public void SendMouseMove(ushort x, ushort y)
    {
        ObjectDisposedException.ThrowIf(_isDisposed || _instance is null, this);

        rvnc_connection_mouse_move(_instance, x, y);
    }

    public void SendMouseScroll(ushort x, ushort y, double scrollWheelDeltaX, double scrollWheelDeltaY)
    {
        ObjectDisposedException.ThrowIf(_isDisposed || _instance is null, this);

        // TODO
        MouseWheel direction = MouseWheel.Down;
        uint steps = 1;

        rvnc_connection_mouse_wheel(_instance, direction, x, y, steps);
    }

    public void Dispose()
    {
        if (_isDisposed)
            return;

        var context = Context;

        context?.Dispose();

        _isDisposed = true;

        if (_framebufferAllocator is not null)
        {
            bool removed = FramebufferAllocators.TryRemove((nuint)_framebufferAllocator, out _);
            rvnc_framebuffer_allocator_destroy(_framebufferAllocator);
            _framebufferAllocator = null;
            Debug.Assert(removed);
        }

        if (_instance is null)
            return;

        rvnc_connection_destroy(_instance);
        _instance = null;
    }
}
