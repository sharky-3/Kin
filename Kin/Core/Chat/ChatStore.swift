import Foundation
import Observation

nonisolated struct ChatEntry: Identifiable, Codable, Hashable, Sendable {
    var id = UUID()
    var date = Date()
    var text = ""
    var files: [String] = []
    var voice: String?
    var duration: Double = 0
    var app = ""
}

@Observable
final class ChatStore {
    private var threads: [String: [ChatEntry]] = [:]

    init() {
        if let data = try? Data(contentsOf: fileURL), let saved = try? JSONDecoder().decode([String: [ChatEntry]].self, from: data) {
            threads = saved
        }
    }

    func entries(for id: UUID) -> [ChatEntry] {
        threads[id.uuidString] ?? []
    }

    func add(_ entry: ChatEntry, for id: UUID) {
        var thread = threads[id.uuidString] ?? []
        thread.append(entry)
        threads[id.uuidString] = Array(thread.suffix(40))
        save()
    }

    private var fileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Kin", isDirectory: true).appendingPathComponent("history.json")
    }

    private func save() {
        let url = fileURL
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        guard let data = try? JSONEncoder().encode(threads) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
