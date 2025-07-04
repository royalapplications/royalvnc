using System;

namespace RoyalApps.RoyalVNCKit;

public abstract class VncFramebufferAllocator
{
    internal ReadOnlySpan<byte> Allocate(nuint size)
        => AllocatePixelData(size);

    internal void Deallocate(ReadOnlySpan<byte> allocation)
        => DeallocatePixelData(allocation);

    protected abstract ReadOnlySpan<byte> AllocatePixelData(nuint size);

    protected abstract void DeallocatePixelData(ReadOnlySpan<byte> allocation);
}
