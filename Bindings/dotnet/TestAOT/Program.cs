using System;
using RoyalApps.RoyalVNCKit;

if (args.Length is not 1)
{
    Console.Error.WriteLine("""
        Usage: TestAOT <argument>

        Argument:
          --version         Print RoyalVNCKit version and build information.
        """);
    return 1;
}

switch (args[0])
{
    case "--version":
        var version = typeof(VncConnection).Assembly.GetName().Version;
        Console.WriteLine($"RoyalVNCKit v{version}");
        return 0;

    default:
        Console.Error.WriteLine($"Unknown argument found: {args[0]}");
        return 1;
}
