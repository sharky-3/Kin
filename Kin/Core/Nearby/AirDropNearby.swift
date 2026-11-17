import Foundation
import Observation

@Observable
final class AirDropNearby {
    static let guestLimit = 3
    private(set) var peers: [AirDropPeer] = []
    @ObservationIgnored var onChange: (() -> Void)?
    @ObservationIgnored private var bridge: AirDropBridge?
    @ObservationIgnored private var picked: [String] = []
    @ObservationIgnored private var ids: [String: UUID] = [:]

    var isAvailable: Bool {
        makeBridge().isAvailable
    }

    func setActive(_ active: Bool) {
        let bridge = makeBridge()
        if active {
            bridge.start()
        } else {
            bridge.stop()
        }
    }

    func isNearby(_ person: Person) -> Bool {
        peers.contains { Self.matches($0, person) }
    }

    func guests(excluding people: [Person]) -> [Person] {
        let strangers = peers.filter { peer in !people.contains { Self.matches(peer, $0) } }
        let present = Set(strangers.map(\.id))
        picked.removeAll { !present.contains($0) }
        for peer in strangers.shuffled() where picked.count < Self.guestLimit && !picked.contains(peer.id) {
            picked.append(peer.id)
        }
        return picked.compactMap { id in
            guard let peer = strangers.first(where: { $0.id == id }) else { return nil }
            let uuid = ids[id] ?? UUID()
            ids[id] = uuid
            let hue = Double(peer.name.unicodeScalars.reduce(0) { ($0 + Int($1.value) * 7) % 100 }) / 100
            return Person(id: uuid, name: peer.name, hue: hue, dropAction: .airdrop, isGuest: true)
        }
    }

    private func makeBridge() -> AirDropBridge {
        if let bridge {
            return bridge
        }
        let created = AirDropBridge { peers in
            Task { @MainActor [weak self] in
                self?.receive(peers)
            }
        }
        bridge = created
        return created
    }

    private func receive(_ next: [AirDropPeer]) {
        guard next != peers else { return }
        peers = next
        onChange?()
    }

    private static func matches(_ peer: AirDropPeer, _ person: Person) -> Bool {
        let peerName = peer.name.lowercased()
        let full = person.name.trimmingCharacters(in: .whitespaces).lowercased()
        guard !full.isEmpty else { return false }
        if peerName == full {
            return true
        }
        let first = person.firstName.lowercased()
        return first.count >= 3 && peerName.split(whereSeparator: { !$0.isLetter }).first.map(String.init) == first
    }
}
