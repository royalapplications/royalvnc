using System.Runtime.CompilerServices;

namespace RoyalApps.RoyalVNCKit;

static class NativeExtensions
{
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    internal static byte ToNativeBool(this bool b) => b ? (byte)1 : (byte)0;
    
    [MethodImpl(MethodImplOptions.AggressiveInlining)]
    internal static bool FromNativeBool(this byte b) => b is not 0;
}
