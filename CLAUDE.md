# Tidy

macOS menu bar app that auto-cleans clipboard text. Same architecture as [snip](../snip).

## Build

```bash
make build    # swift build -c release
make test     # swift test
make app      # test + package .app + DMG
make install  # app + copy to /Applications
```

## Architecture

- `TextCleaner` — enum with static methods; 5-stage pipeline: strip trailing ws, collapse spaces, unwrap paragraphs, trim indent, collapse blanks
- `ClipboardMonitor` — polls NSPasteboard every 0.5s, debounces, calls TextCleaner, skips >1MB
- `SettingsStore` — per-transform toggles persisted in UserDefaults
- `ClipboardProvider` — protocol for testability (shared with snip)

## Testing

56 tests. `TextCleanerTests` covers each transform individually + full pipeline integration. `ClipboardMonitorTests` covers enable/disable, debounce, nil clipboard, large clipboard, no-op on clean text.

## Constraints

- No third-party dependencies
- No network requests
- No sandbox (needs clipboard access)
- macOS 14+ (SMAppService for launch-at-login)
