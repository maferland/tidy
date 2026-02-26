import Foundation
import Testing
@testable import Tidy

final class MockClipboardProvider: ClipboardProvider {
    private var _changeCount = 0
    private var _string: String?
    var lastSetString: String?
    var setStringCallCount = 0
    var alwaysReturnNil = false

    var changeCount: Int { _changeCount }

    func string() -> String? { alwaysReturnNil ? nil : _string }

    func setString(_ string: String) {
        _string = string
        _changeCount += 1
        lastSetString = string
        setStringCallCount += 1
    }

    func simulateExternalChange() {
        _changeCount += 1
    }
}

@Suite("ClipboardMonitor")
struct ClipboardMonitorTests {
    @Test("does not clean when disabled")
    func disabledDoesNotClean() {
        let provider = MockClipboardProvider()
        let settings = makeTestSettings()
        let monitor = ClipboardMonitor(provider: provider, settings: settings)
        monitor.isEnabled = false
        provider.setString("hello   ")
        monitor.checkClipboard()
        #expect(provider.lastSetString == "hello   ")
    }

    @Test("cleans clipboard text when enabled")
    func cleansWhenEnabled() {
        let provider = MockClipboardProvider()
        let settings = makeTestSettings()
        let monitor = ClipboardMonitor(provider: provider, debounceInterval: 0, settings: settings)
        monitor.isEnabled = true
        provider.setString("hello   ")
        monitor.checkClipboard()
        #expect(provider.lastSetString == "hello")
    }

    @Test("debounces rapid clipboard changes")
    func debouncesRapidChanges() {
        let provider = MockClipboardProvider()
        let settings = makeTestSettings()
        let monitor = ClipboardMonitor(provider: provider, debounceInterval: 0.2, settings: settings)
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
        let monitor = ClipboardMonitor(provider: provider, debounceInterval: 0, settings: settings)
        monitor.isEnabled = true
        provider.setString("already clean")
        monitor.checkClipboard()
        #expect(provider.setStringCallCount == 1)
    }

    @Test("ignores nil clipboard content")
    func nilClipboard() {
        let provider = MockClipboardProvider()
        let settings = makeTestSettings()
        let monitor = ClipboardMonitor(provider: provider, debounceInterval: 0, settings: settings)
        monitor.isEnabled = true
        provider.alwaysReturnNil = true
        provider.simulateExternalChange()
        monitor.checkClipboard()
        #expect(provider.setStringCallCount == 0)
    }

    @Test("skips clipboard content over 1MB")
    func largeClipboardSkipped() {
        let provider = MockClipboardProvider()
        let settings = makeTestSettings()
        let monitor = ClipboardMonitor(provider: provider, debounceInterval: 0, settings: settings)
        monitor.isEnabled = true
        let largeText = String(repeating: "a ", count: 600_000)
        provider.setString(largeText)
        monitor.checkClipboard()
        #expect(provider.setStringCallCount == 1)
    }

    @Test("start then stop prevents further checks")
    func startStop() {
        let provider = MockClipboardProvider()
        let settings = makeTestSettings()
        let monitor = ClipboardMonitor(provider: provider, debounceInterval: 0, settings: settings)
        monitor.start()
        monitor.stop()
        // After stop, timer should be nil — manual check still works but timer won't fire
        provider.setString("hello   ")
        monitor.checkClipboard()
        #expect(provider.lastSetString == "hello")
    }

    @Test("multiple start calls don't leak timers")
    func multipleStarts() {
        let provider = MockClipboardProvider()
        let settings = makeTestSettings()
        let monitor = ClipboardMonitor(provider: provider, debounceInterval: 0, settings: settings)
        monitor.start()
        monitor.start()
        monitor.stop()
        // No crash, no leak — stop invalidates the last timer
    }
}

@Suite("Stats & History")
struct StatsHistoryTests {
    @Test("totalCleans increments on clean")
    func totalCleansIncrements() {
        let provider = MockClipboardProvider()
        let settings = makeTestSettings()
        let monitor = ClipboardMonitor(provider: provider, debounceInterval: 0, settings: settings)
        monitor.isEnabled = true
        provider.setString("hello   ")
        monitor.checkClipboard()
        #expect(settings.totalCleans == 1)
        provider.setString("world   ")
        monitor.checkClipboard()
        #expect(settings.totalCleans == 2)
    }

    @Test("totalCleans does not increment when text unchanged")
    func totalCleansNoIncrementWhenClean() {
        let provider = MockClipboardProvider()
        let settings = makeTestSettings()
        let monitor = ClipboardMonitor(provider: provider, debounceInterval: 0, settings: settings)
        monitor.isEnabled = true
        provider.setString("already clean")
        monitor.checkClipboard()
        #expect(settings.totalCleans == 0)
    }

    @Test("totalCleans persists to UserDefaults")
    func totalCleansPersists() {
        let suiteName = "test-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let settings = SettingsStore(userDefaults: defaults)
        settings.totalCleans = 42
        let reloaded = SettingsStore(userDefaults: defaults)
        #expect(reloaded.totalCleans == 42)
    }

    @Test("history appends entries with correct original/cleaned")
    func historyEntries() {
        let provider = MockClipboardProvider()
        let settings = makeTestSettings()
        let monitor = ClipboardMonitor(provider: provider, debounceInterval: 0, settings: settings)
        monitor.isEnabled = true
        provider.setString("hello   ")
        monitor.checkClipboard()
        #expect(settings.history.count == 1)
        #expect(settings.history[0].original == "hello   ")
        #expect(settings.history[0].cleaned == "hello")
    }

    @Test("history caps at 5 entries")
    func historyCapsAtFive() {
        let settings = makeTestSettings()
        for i in 0..<7 {
            settings.addCleanEntry(original: "orig \(i)", cleaned: "clean \(i)")
        }
        #expect(settings.history.count == 5)
        #expect(settings.history[0].original == "orig 6")
        #expect(settings.history[4].original == "orig 2")
    }

    @Test("history persists to UserDefaults")
    func historyPersists() {
        let suiteName = "test-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let settings = SettingsStore(userDefaults: defaults)
        settings.addCleanEntry(original: "test", cleaned: "cleaned")
        let reloaded = SettingsStore(userDefaults: defaults)
        #expect(reloaded.history.count == 1)
        #expect(reloaded.history[0].original == "test")
    }
}
