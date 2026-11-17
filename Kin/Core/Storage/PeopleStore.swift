import Foundation
import Observation

@Observable
final class PeopleStore {
    static let limit = 5

    private(set) var people: [Person] = []
    private(set) var me = Person(name: NSFullUserName(), hue: 0.14)
    private(set) var dropEnabled = true
    private(set) var airdropEnabled = true
    private(set) var showGuests = false
    private(set) var guests: [Person] = []
    var airdropAvailable = true

    var shown: [Person] {
        Array(people.filter { $0.isShown }.prefix(Self.limit))
    }

    var targets: [Person] {
        [me] + shown + (airdropEnabled && showGuests ? guests : [])
    }

    @ObservationIgnored var onChange: (() -> Void)?

    var isFull: Bool {
        shown.count >= Self.limit
    }

    init() {
        people = load()
        if let data = try? Data(contentsOf: profileURL), let saved = try? JSONDecoder().decode(Person.self, from: data) {
            me = saved
        }
        if UserDefaults.standard.object(forKey: "airdropEnabled") != nil {
            airdropEnabled = UserDefaults.standard.bool(forKey: "airdropEnabled")
        }
        showGuests = UserDefaults.standard.bool(forKey: "showGuests")
        if UserDefaults.standard.object(forKey: "dropEnabled") != nil {
            dropEnabled = UserDefaults.standard.bool(forKey: "dropEnabled")
        }
    }

    func updateMe(_ change: (inout Person) -> Void) {
        change(&me)
        if let data = try? JSONEncoder().encode(me) {
            try? FileManager.default.createDirectory(at: profileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? data.write(to: profileURL, options: .atomic)
        }
        onChange?()
    }

    func setAirDropEnabled(_ enabled: Bool) {
        airdropEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "airdropEnabled")
        onChange?()
    }

    func setShowGuests(_ enabled: Bool) {
        showGuests = enabled
        UserDefaults.standard.set(enabled, forKey: "showGuests")
        onChange?()
    }

    func setGuests(_ next: [Person]) {
        guard next != guests else { return }
        guests = next
        onChange?()
    }

    func setDropEnabled(_ enabled: Bool) {
        dropEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "dropEnabled")
    }

    func contains(_ person: Person) -> Bool {
        people.contains { $0.id == person.id }
    }

    func save(_ person: Person) {
        var updated = person
        if let index = people.firstIndex(where: { $0.id == person.id }) {
            if updated.isShown && !people[index].isShown && isFull {
                updated.isShown = false
            }
            people[index] = updated
        } else {
            if isFull {
                updated.isShown = false
            }
            people.append(updated)
        }
        commit()
    }

    func setShown(_ person: Person, _ shown: Bool) {
        guard let index = people.firstIndex(where: { $0.id == person.id }) else { return }
        if shown && isFull { return }
        people[index].isShown = shown
        commit()
    }

    func remove(_ person: Person) {
        people.removeAll { $0.id == person.id }
        commit()
    }

    func move(_ person: Person, by offset: Int) {
        guard let index = people.firstIndex(where: { $0.id == person.id }) else { return }
        let target = index + offset
        guard people.indices.contains(target) else { return }
        people.swapAt(index, target)
        commit()
    }

    private func commit() {
        persist()
        onChange?()
    }

    private var fileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Kin", isDirectory: true).appendingPathComponent("people.json")
    }

    private var profileURL: URL {
        fileURL.deletingLastPathComponent().appendingPathComponent("me.json")
    }

    private func load() -> [Person] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        var decoded = (try? JSONDecoder().decode([Person].self, from: data)) ?? []
        var visible = 0
        for index in decoded.indices where decoded[index].isShown {
            visible += 1
            if visible > Self.limit {
                decoded[index].isShown = false
            }
        }
        return decoded
    }

    private func persist() {
        let url = fileURL
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        guard let data = try? JSONEncoder().encode(people) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
