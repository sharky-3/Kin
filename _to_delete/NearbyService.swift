import CryptoKit
import Foundation
import MultipeerConnectivity
import Observation

nonisolated enum NearbyIdentity {
    static func hashes(for person: Person) -> Set<String> {
        var result = Set<String>()
        let digits = person.digits
        if digits.count >= 6 {
            result.insert(hash("p:" + String(digits.suffix(8))))
        }
        let mail = person.trimmedEmail.lowercased()
        if mail.contains("@") {
            result.insert(hash("e:" + mail))
        }
        return result
    }

    private static func hash(_ value: String) -> String {
        SHA256.hash(data: Data(("kin-nearby|" + value).utf8)).prefix(8).map { String(format: "%02x", $0) }.joined()
    }
}

@Observable
final class NearbyService: NSObject {
    private(set) var nearby: Set<String> = []
    @ObservationIgnored var onChange: (() -> Void)?
    @ObservationIgnored private let peer = MCPeerID(displayName: Host.current().localizedName ?? "Mac")
    @ObservationIgnored private var advertiser: MCNearbyServiceAdvertiser?
    @ObservationIgnored private var browser: MCNearbyServiceBrowser?
    @ObservationIgnored private var peers: [Int: Set<String>] = [:]
    @ObservationIgnored private var advertised: Set<String> = []
    private static let service = "kin-near"

    func isNearby(_ person: Person) -> Bool {
        !NearbyIdentity.hashes(for: person).isDisjoint(with: nearby)
    }

    func update(me: Person, enabled: Bool) {
        guard enabled else {
            stop()
            return
        }
        if browser == nil {
            let created = MCNearbyServiceBrowser(peer: peer, serviceType: Self.service)
            created.delegate = self
            created.startBrowsingForPeers()
            browser = created
        }
        let own = NearbyIdentity.hashes(for: me)
        guard own != advertised else { return }
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        advertised = own
        guard !own.isEmpty else { return }
        let created = MCNearbyServiceAdvertiser(peer: peer, discoveryInfo: ["h": own.sorted().joined(separator: ",")], serviceType: Self.service)
        created.delegate = self
        created.startAdvertisingPeer()
        advertiser = created
    }

    private func stop() {
        advertiser?.stopAdvertisingPeer()
        advertiser = nil
        advertised = []
        browser?.stopBrowsingForPeers()
        browser = nil
        peers = [:]
        publish()
    }

    private func set(_ key: Int, _ hashes: Set<String>?) {
        guard browser != nil else { return }
        peers[key] = hashes
        publish()
    }

    private func publish() {
        let next = peers.values.reduce(into: Set<String>()) { $0.formUnion($1) }
        guard next != nearby else { return }
        nearby = next
        onChange?()
    }
}

extension NearbyService: MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate {
    nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        let key = peerID.hash
        let hashes = Set((info?["h"] ?? "").split(separator: ",").map(String.init))
        Task { @MainActor in
            self.set(key, hashes)
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        let key = peerID.hash
        Task { @MainActor in
            self.set(key, nil)
        }
    }

    nonisolated func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {}

    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(false, nil)
    }

    nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {}
}
