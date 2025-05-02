using System;
using static RoyalApps.RoyalVNCKit.RoyalVNCKit;

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

    internal VncSettings(void* instance)
    {
        ArgumentNullException.ThrowIfNull(instance);
        Instance = instance;
    }

    public VncSettings(IVncSettings settings)
    {
        ArgumentNullException.ThrowIfNull(settings);
        Instance = rvnc_settings_create(
            settings.IsDebugLoggingEnabled.ToNativeBool(),
            settings.Hostname,
            settings.Port,
            settings.IsShared.ToNativeBool(),
            settings.IsScalingEnabled.ToNativeBool(),
            settings.UseDisplayLink.ToNativeBool(),
            settings.InputMode,
            settings.IsClipboardRedirectionEnabled.ToNativeBool(),
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

        rvnc_settings_destroy(Instance);
        Instance = null;
    }
}
