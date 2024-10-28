namespace RoyalApps.RoyalVNCKit;

// keep in sync with Sources/RoyalVNCKitC/include/RoyalVNCKitC.h
public enum InputMode
{
    None = 0,
    ForwardKeyboardShortcutsIfNotInUseLocally = 1,
    ForwardKeyboardShortcutsEvenIfInUseLocally = 2,
    ForwardAllKeyboardShortcutsAndHotkeys = 3,
}
