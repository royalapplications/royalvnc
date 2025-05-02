using System;
using static RoyalApps.RoyalVNCKit.RoyalVNCKit;

namespace RoyalApps.RoyalVNCKit;

public delegate void VncLogEntryHandler(
    VncLogger logger,
    LogLevel logLevel,
    string message
);

public sealed unsafe class VncLogger : IDisposable
{
    bool _isDisposed;
    internal void* Instance { get; private set; }

    public VncLogEntryHandler? AddLogEntry { get; set; }

    internal VncLogger(VncContext context)
    {
        ArgumentNullException.ThrowIfNull(context);
        Instance = rvnc_logger_create(LogEntryHandler, context.Instance);
    }

    public void Dispose()
    {
        if (_isDisposed)
            return;

        _isDisposed = true;

        if (Instance is null)
            return;

        rvnc_logger_destroy(Instance);
        Instance = null;
    }

    static readonly LogDelegate LogEntryHandler = LogEntry;

    static void LogEntry(
        void* logger,
        void* context,
        LogLevel logLevel,
        string message
    )
    {
        var vncContext = VncContext.FromPointer(context);

        if (vncContext?.Logger is not { } vncLogger)
            return;

        vncLogger.AddLogEntry?.Invoke(vncLogger, logLevel, message);
    }
}
