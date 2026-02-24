import AppKit
import Combine

final class ClipboardMonitor: ObservableObject {
    @Published var lastResult: CleanResult?

    let settings: SettingsStore
    private let provider: ClipboardProvider
    private let cleaner: TextCleaner
    private let debounceInterval: TimeInterval
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private var lastCleanedAt: Date?

    var isEnabled: Bool {
        get { settings.isEnabled }
        set { settings.isEnabled = newValue }
    }

    init(provider: ClipboardProvider = SystemClipboardProvider(), cleaner: TextCleaner = TextCleaner(), debounceInterval: TimeInterval = 0.3, settings: SettingsStore = SettingsStore()) {
        self.provider = provider
        self.cleaner = cleaner
        self.debounceInterval = debounceInterval
        self.settings = settings
    }

    deinit {
        stop()
    }

    func start() {
        lastChangeCount = provider.changeCount
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func checkClipboard() {
        guard isEnabled else { return }

        let currentCount = provider.changeCount

        guard currentCount != lastChangeCount else { return }
        lastChangeCount = currentCount

        if let lastCleanedAt, Date().timeIntervalSince(lastCleanedAt) < debounceInterval {
            return
        }

        guard let text = provider.string() else { return }

        let result = cleaner.clean(text, settings: settings)
        guard result.didChange else { return }

        provider.setString(result.cleaned)
        lastChangeCount = provider.changeCount
        lastCleanedAt = Date()

        DispatchQueue.main.async {
            self.lastResult = result
        }
    }
}
