import Foundation
import Combine

final class SettingsStore: ObservableObject {
    private let userDefaults: UserDefaults

    @Published var isEnabled: Bool {
        didSet { userDefaults.set(isEnabled, forKey: "isEnabled") }
    }
    @Published var stripTrailing: Bool {
        didSet { userDefaults.set(stripTrailing, forKey: "transform.stripTrailing") }
    }
    @Published var collapseSpaces: Bool {
        didSet { userDefaults.set(collapseSpaces, forKey: "transform.collapseSpaces") }
    }
    @Published var unwrapParagraphs: Bool {
        didSet { userDefaults.set(unwrapParagraphs, forKey: "transform.unwrapParagraphs") }
    }
    @Published var trimIndent: Bool {
        didSet { userDefaults.set(trimIndent, forKey: "transform.trimIndent") }
    }
    @Published var collapseBlankLines: Bool {
        didSet { userDefaults.set(collapseBlankLines, forKey: "transform.collapseBlankLines") }
    }
    @Published var totalCleans: Int {
        didSet { userDefaults.set(totalCleans, forKey: "stats.totalCleans") }
    }
    @Published var history: [CleanEntry] {
        didSet {
            if let data = try? JSONEncoder().encode(history) {
                userDefaults.set(data, forKey: "stats.history")
            }
        }
    }

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.isEnabled = Self.bool(for: "isEnabled", default: true, in: userDefaults)
        self.stripTrailing = Self.bool(for: "transform.stripTrailing", default: true, in: userDefaults)
        self.collapseSpaces = Self.bool(for: "transform.collapseSpaces", default: true, in: userDefaults)
        self.unwrapParagraphs = Self.bool(for: "transform.unwrapParagraphs", default: true, in: userDefaults)
        self.trimIndent = Self.bool(for: "transform.trimIndent", default: true, in: userDefaults)
        self.collapseBlankLines = Self.bool(for: "transform.collapseBlankLines", default: true, in: userDefaults)
        self.totalCleans = userDefaults.integer(forKey: "stats.totalCleans")
        if let data = userDefaults.data(forKey: "stats.history"),
           let decoded = try? JSONDecoder().decode([CleanEntry].self, from: data) {
            self.history = decoded
        } else {
            self.history = []
        }
    }

    func addCleanEntry(original: String, cleaned: String) {
        let entry = CleanEntry(original: original, cleaned: cleaned)
        history = [entry] + history.prefix(4)
        totalCleans += 1
    }

    private static func bool(for key: String, default defaultValue: Bool, in store: UserDefaults) -> Bool {
        store.object(forKey: key) == nil ? defaultValue : store.bool(forKey: key)
    }
}
