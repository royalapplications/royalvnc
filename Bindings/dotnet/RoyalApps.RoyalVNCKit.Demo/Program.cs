using System;
using System.Text;
using System.Threading;
using static System.Console;

namespace RoyalApps.RoyalVNCKit.Demo;

static class Program
{
    static int Main(string[] args)
    {
        string hostname = args.Length > 0
            ? args[0]
            : PromptAndReadInput("Enter hostname: ");

        if (string.IsNullOrWhiteSpace(hostname))
        {
            Error.WriteLine("No hostname given -- exiting");
            return 1;
        }

        var settings = new DemoSettings
        {
            Hostname = hostname,
            Port = 5900,
            IsDebugLoggingEnabled = true,
            IsShared = true,
            IsScalingEnabled = false,
            UseDisplayLink = false,
            InputMode = InputMode.None,
            IsClipboardRedirectionEnabled = false,
            ColorDepth = ColorDepth.Bits24,
        };

        using var vncSettings = new VncSettings(settings);
        using var connection = new VncConnection(vncSettings);
        
        using var connectionDelegate = new VncConnectionDelegate();
        connectionDelegate.AuthenticationRequested = OnAuthenticationRequested;
        connectionDelegate.ConnectionStateChanged = OnConnectionStateChanged;
        connectionDelegate.FramebufferCreated = OnFramebufferCreated;
        connectionDelegate.FramebufferResized = OnFramebufferResized;
        connectionDelegate.FramebufferRegionUpdated = OnFramebufferRegionUpdated;
        
        connection.Delegate = connectionDelegate;
        connection.Connect();

        while (true)
        {
            var status = connection.Status;
            if (status is ConnectionStatus.Disconnected)
                break;
            
            Thread.Sleep(millisecondsTimeout: 500);
        }

        return 0;
    }

    static bool OnAuthenticationRequested(VncConnection connection, AuthenticationRequest request)
    {
        string type = request.AuthenticationType switch
        {
            AuthenticationType.Vnc => "VNC",
            AuthenticationType.AppleRemoteDesktop => "Apple Remote Desktop",
            AuthenticationType.UltraVncMSLogonII => "UltraVNC MS Logon II",
            _ => $"Unknown({request.AuthenticationType:D})"
        };
        
        WriteLine($"authenticationRequested: {type}");

        if (request.RequiresUsername)
            request.Username = PromptAndReadInput("Enter username: ");

        if (request.RequiresPassword)
            request.Password = PromptAndReadPassword("Enter password: ");

        return true;
    }
    
    static void OnConnectionStateChanged(VncConnection connection, VncConnectionState state) =>
        WriteLine(state.DisplayErrorToUser
            ? $"connectionStateChanged: {state.Status} ({(state.IsAuthenticationError ? "authentication" : "")} error: {state.ErrorDescription})"
            : $"connectionStateChanged: {state.Status}");

    static void OnFramebufferCreated(VncConnection connection, VncFramebuffer framebuffer) =>
        WriteLine($"framebufferCreated: {framebuffer.Width:N0}x{framebuffer.Height:N0} ({framebuffer.PixelData.Length:N0} bytes)");

    static void OnFramebufferResized(VncConnection connection, VncFramebuffer framebuffer) =>
        WriteLine($"framebufferResized: {framebuffer.Width:N0}x{framebuffer.Height:N0} ({framebuffer.PixelData.Length:N0} bytes)");

    static void OnFramebufferRegionUpdated(VncConnection connection, VncFramebuffer _, VncFramebufferRegion region) =>
        WriteLine($"framebufferRegionUpdated: {region.Width:N0}x{region.Height:N0} at {region.X:N0}, {region.Y:N0}");

    static string PromptAndReadInput(string prompt)
    {
        Write(prompt);
        return ReadLine()!;
    }
    
    static string PromptAndReadPassword(string prompt)
    {
        Write(prompt);
        var sb = new StringBuilder();
        while (true)
        {
            var info = ReadKey(true);
            if (info.Key is ConsoleKey.Enter)
            {
                WriteLine();
                break;
            }
            
            if (info.Key is ConsoleKey.Backspace)
            {
                if (sb.Length > 0)
                {
                    Write("\b\0\b");
                    sb.Length--;
                }
                continue;
            }
            
            Write("*");
            sb.Append(info.KeyChar);
        }
        return sb.ToString();
    }
    
    readonly struct DemoSettings : IVncSettings
    {
        public string Hostname { get; init; }
        public ushort Port { get; init; }
        public InputMode InputMode { get; init; }
        public ColorDepth ColorDepth { get; init; }
        public bool IsClipboardRedirectionEnabled { get; init; }
        public bool IsDebugLoggingEnabled { get; init; }
        public bool IsScalingEnabled { get; init; }
        public bool IsShared { get; init; }
        public bool UseDisplayLink { get; init; }
    }
}