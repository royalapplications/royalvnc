using System;
using System.Diagnostics;
using System.Runtime.InteropServices;

namespace RoyalApps.RoyalVNCKit;

[StructLayout(LayoutKind.Auto)]
public readonly unsafe ref struct VncFramebuffer
{
    readonly void* _instance;

    internal VncFramebuffer(void* instance)
    {
        ArgumentNullException.ThrowIfNull(instance);
        _instance = instance;
    }

    public ushort Width => RoyalVNCKit.rvnc_framebuffer_size_width_get(_instance);
    public ushort Height => RoyalVNCKit.rvnc_framebuffer_size_height_get(_instance);

    public ReadOnlySpan<byte> PixelData
    {
        get
        {
            var length = checked((int)RoyalVNCKit.rvnc_framebuffer_pixel_data_size_get(_instance));
            if (length is 0)
                return ReadOnlySpan<byte>.Empty;

            var pixelData = RoyalVNCKit.rvnc_framebuffer_pixel_data_get(_instance);
            
            Debug.Assert(pixelData is not null);
            return new(pixelData, length);
        }
    }
}
