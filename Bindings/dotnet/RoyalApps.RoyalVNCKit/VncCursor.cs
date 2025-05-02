using System;
using System.Diagnostics;
using static RoyalApps.RoyalVNCKit.RoyalVNCKit;

namespace RoyalApps.RoyalVNCKit;

public sealed unsafe class VncCursor : IDisposable
{
    bool _isDisposed;
    void* _instance;
    void* _pixelData;

    internal VncCursor(void* instance)
    {
        ArgumentNullException.ThrowIfNull(instance);
        _instance = instance;
    }

    public bool IsEmpty => rvnc_cursor_is_empty_get(_instance).FromNativeBool();
    public ushort Width => rvnc_cursor_size_width_get(_instance);
    public ushort Height => rvnc_cursor_size_height_get(_instance);
    public ushort HotspotX => rvnc_cursor_hotspot_x_get(_instance);
    public ushort HotspotY => rvnc_cursor_hotspot_y_get(_instance);
    public long BitsPerComponent => rvnc_cursor_bits_per_component_get(_instance);
    public long BitsPerPixel => rvnc_cursor_bits_per_pixel_get(_instance);
    public long BytesPerPixel => rvnc_cursor_bytes_per_pixel_get(_instance);
    public long BytesPerRow => rvnc_cursor_bytes_per_row_get(_instance);

    public ReadOnlySpan<byte> PixelData
    {
        get
        {
            var length = checked((int)rvnc_cursor_pixel_data_size_get(_instance));
            if (length is 0)
                return ReadOnlySpan<byte>.Empty;

            if (_pixelData is null)
                _pixelData = rvnc_cursor_pixel_data_get_copy(_instance);

            Debug.Assert(_pixelData is not null);
            return new(_pixelData, length);
        }
    }

    public void Dispose()
    {
        if (_isDisposed)
            return;

        _isDisposed = true;

        if (_pixelData is not null)
        {
            rvnc_cursor_pixel_data_destroy(_pixelData);
            _pixelData = null;
        }

        _instance = null;
    }
}
