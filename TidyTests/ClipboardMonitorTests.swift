import Foundation
import Testing
@testable import Tidy

final class MockClipboardProvider: ClipboardProvider {
    private var _changeCount = 0
    private var _string: String?
    var lastSetString: String?
    var setStringCallCount = 0

    var changeCount: Int { _changeCount }

    func string() -> String? { _string }

    func setString(_ string: String) {
        _string = string
        _changeCount += 1
        lastSetString = string
        setStringCallCount += 1
    }
}

@Suite("ClipboardMonitor")
struct ClipboardMonitorTests {
    @Test("does not clean when disabled")
    func disabledDoesNotClean() {
        let provider = MockClipboardProvider()
        let settings = makeTestSettings()
        let monitor = ClipboardMonitor(provider: provider, cleaner: TextCleaner(), settings: settings)
        monitor.isEnabled = false
        provider.setString("hello   ")
        monitor.checkClipboard()
        #expect(provider.lastSetString == "hello   ")
    }

    @Test("cleans clipboard text when enabled")
    func cleansWhenEnabled() {
        let provider = MockClipboardProvider()
        let settings = makeTestSettings()
        let monitor = ClipboardMonitor(provider: provider, cleaner: TextCleaner(), debounceInterval: 0, settings: settings)
        monitor.isEnabled = true
        provider.setString("hello   ")
        monitor.checkClipboard()
        #expect(provider.lastSetString == "hello")
    }

    @Test("debounces rapid clipboard changes")
    func debouncesRapidChanges() {
        let provider = MockClipboardProvider()
        let settings = makeTestSettings()
        let monitor = ClipboardMonitor(provider: provider, cleaner: TextCleaner(), debounceInterval: 0.2, settings: settings)
        monitor.isEnabled = true
        provider.setString("hello   ")
        monitor.checkClipboard()
        provider.setString("world   ")
        monitor.checkClipboard()
        #expect(provider.setStringCallCount == 3)
    }

    @Test("does not write back if text unchanged")
    func noWriteIfUnchanged() {
        let provider = MockClipboardProvider()
        let settings = makeTestSettings()
        let monitor = ClipboardMonitor(provider: provider, cleaner: TextCleaner(), debounceInterval: 0, settings: settings)
        monitor.isEnabled = true
        provider.setString("already clean")
        monitor.checkClipboard()
        #expect(provider.setStringCallCount == 1) // only the initial setString
    }
}
