using System.Diagnostics;
using System.Runtime.InteropServices;

namespace RoyalApps.RoyalVNCKit;

[StructLayout(LayoutKind.Auto)]
public readonly struct VncFramebufferRegion
{
    public ushort X { get; }
    public ushort Y { get; }
    public ushort Width { get; }
    public ushort Height { get; }

    internal VncFramebufferRegion(ushort x, ushort y, ushort width, ushort height)
    {
        Debug.Assert(width > 0);
        Debug.Assert(height > 0);
        X = x;
        Y = y;
        Width = width;
        Height = height;
    }
}
