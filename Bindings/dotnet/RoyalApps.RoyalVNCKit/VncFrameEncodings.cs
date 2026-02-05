using System;
using static RoyalApps.RoyalVNCKit.RoyalVNCKit;

namespace RoyalApps.RoyalVNCKit;

internal sealed unsafe class VncFrameEncodings: IDisposable
{
    bool _isDisposed;

    internal void* Instance { get; private set; }

    internal VncFrameEncodings(void* instance)
    {
        ArgumentNullException.ThrowIfNull(instance);
        Instance = instance;
    }

    internal VncFrameEncodings(VncFrameEncodingType[] frameEncodingTypes)
    {
        Instance = rvnc_frame_encodings_create();

        foreach (var frameEncodingType in frameEncodingTypes) {
            AppendFrameEncodingType(frameEncodingType);
        }
    }

    private void AppendFrameEncodingType(VncFrameEncodingType frameEncodingType)
    {
        ArgumentNullException.ThrowIfNull(Instance);
        switch (frameEncodingType) {
            case VncFrameEncodingType.Rre:
                rvnc_frame_encodings_append_rre(Instance);
                break;
            case VncFrameEncodingType.CoRre:
                rvnc_frame_encodings_append_corre(Instance);
                break;
            case VncFrameEncodingType.Hextile:
                rvnc_frame_encodings_append_hextile(Instance);
                break;
            case VncFrameEncodingType.Zlib:
                rvnc_frame_encodings_append_zlib(Instance);
                break;
            case VncFrameEncodingType.Tight:
                rvnc_frame_encodings_append_tight(Instance);
                break;
            case VncFrameEncodingType.Zrle:
                rvnc_frame_encodings_append_zrle(Instance);
                break;
            default:
                throw new ArgumentOutOfRangeException(nameof(frameEncodingType), frameEncodingType, $"Unknown {nameof(VncFrameEncodingType)}");
        }
    }

    public void Dispose()
    {
        if (_isDisposed)
            return;

        _isDisposed = true;

        if (Instance is null)
            return;

        rvnc_frame_encodings_destroy(Instance);
        Instance = null;
    }
}
