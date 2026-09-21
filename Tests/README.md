# Clipboard tests

Run `swift test` for message parsing, Unicode/zlib round trips, fragmented input,
size limits, Latin-1 fallback, and the existing clipboard setting. On macOS, the
control-message test uses a named test pasteboard to verify that Caps/Notify do
not erase text and a disabled connection cannot send or replace text. The
pasteboard substitution is confined to serial XCTest cases; it adds no SDK API.

`ClipboardInteropTests` is opt-in on macOS. It requires an isolated TigerVNC
server forwarded to `127.0.0.1:5906` and an external fixture driver:

1. Set `ROYAL_VNC_INTEROP_READY` to a temporary marker-file path and run
   `swift test --filter ClipboardInteropTests`.
2. When that file appears, put `remote åäö 日本語 🙂\nsecond line` on the isolated
   server's clipboard (replace `\n` with a newline).
3. Independently read the server clipboard and require exact equality with
   `local åäö 日本語 🙂\nsecond line` before the test ends.

The test checks incoming text on a private macOS pasteboard, then changes that
pasteboard to exercise the real monitor and the peer's Request/Provide exchange.
The external reader must verify the outgoing text; a passing Swift test alone
is not proof of the outgoing direction. The fixture should stop its server and
forwarding after the run. Neither side should use an existing user session.
