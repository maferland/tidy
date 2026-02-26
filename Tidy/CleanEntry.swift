import Foundation

struct CleanEntry: Codable, Identifiable {
    let id: UUID
    let original: String
    let cleaned: String
    let timestamp: Date

    init(id: UUID = UUID(), original: String, cleaned: String, timestamp: Date = Date()) {
        self.id = id
        self.original = original
        self.cleaned = cleaned
        self.timestamp = timestamp
    }
}
