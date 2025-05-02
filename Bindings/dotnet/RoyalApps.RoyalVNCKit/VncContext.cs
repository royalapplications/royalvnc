using System;
using System.Runtime.InteropServices;

namespace RoyalApps.RoyalVNCKit;

sealed unsafe class VncContext: IDisposable
{
    bool _isDisposed;
    internal void* Instance { get; private set; }

    internal VncConnection? Connection { get; set; }
    internal VncConnectionDelegate? ConnectionDelegate { get; set; }
    internal VncLogger? Logger { get; set; }

    internal VncContext()
    {
        var handle = GCHandle.Alloc(this, GCHandleType.Normal);
        var address = GCHandle.ToIntPtr(handle);

        Instance = (void*)address;
    }

    internal static VncContext? FromPointer(void* pointer)
    {
        if (pointer is null)
            return null;

        var handle = GCHandle.FromIntPtr((nint)pointer);

        if (!handle.IsAllocated)
            return null;

        var context = handle.Target as VncContext;

        return context;
    }

    public void Dispose()
    {
        if (_isDisposed)
            return;

        _isDisposed = true;

        if (Instance is null)
            return;

        if (Connection is { } connection)
        {
            connection.Dispose();
            Connection = null;
        }

        if (ConnectionDelegate is { } connectionDelegate)
        {
            connectionDelegate.Dispose();
            ConnectionDelegate = null;
        }

        if (Logger is { } logger)
        {
            logger.Dispose();
            Logger = null;
        }

        var handle = GCHandle.FromIntPtr((nint)Instance);

        if (handle.IsAllocated)
            handle.Free();

        Instance = null;
    }
}
