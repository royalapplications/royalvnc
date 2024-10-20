using System;

namespace RoyalApps.RoyalVNCKit;

public interface IVncSettings
{
    public string Hostname { get; }
    public ushort Port { get; }
    public InputMode InputMode { get; }
    public ColorDepth ColorDepth { get; }
    public bool IsClipboardRedirectionEnabled { get; }
    public bool IsDebugLoggingEnabled { get; } 
    public bool IsScalingEnabled { get; }
    public bool IsShared { get; }
    public bool UseDisplayLink { get; }
}

public sealed unsafe class VncSettings: IDisposable
{
    bool _isDisposed;
    
    internal void* Instance { get; private set; }

    VncSettings(void* instance)
    {
        ArgumentNullException.ThrowIfNull(instance);
        Instance = instance;
    }

    public VncSettings(IVncSettings settings)
    {
        ArgumentNullException.ThrowIfNull(settings);
        Instance = RoyalVNCKit.rvnc_settings_create(
            (byte)(settings.IsDebugLoggingEnabled ? 1 : 0),
            settings.Hostname,
            settings.Port,
            (byte)(settings.IsShared ? 1 : 0),
            (byte)(settings.IsScalingEnabled ? 1 : 0),
            (byte)(settings.UseDisplayLink ? 1 : 0),
            settings.InputMode,
            (byte)(settings.IsClipboardRedirectionEnabled ? 1 : 0),
            settings.ColorDepth
        );
    }

    public void Dispose()
    {
        if (_isDisposed)
            return;

        _isDisposed = true;

        if (Instance is null)
            return;

        RoyalVNCKit.rvnc_settings_destroy(Instance);
        Instance = null;
    }
}