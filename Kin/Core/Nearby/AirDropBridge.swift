import Foundation

nonisolated struct AirDropPeer: Hashable, Sendable {
    let id: String
    let name: String
}

nonisolated final class AirDropBridge: @unchecked Sendable {
    private let queue = DispatchQueue(label: "app.Kin.airdrop")
    private let api = SharingAPI.load()
    private let onUpdate: @Sendable ([AirDropPeer]) -> Void
    private var browser: OpaquePointer?
    private var context: UnsafeMutablePointer<SFContext>?

    var isAvailable: Bool {
        api != nil
    }

    init(onUpdate: @escaping @Sendable ([AirDropPeer]) -> Void) {
        self.onUpdate = onUpdate
    }

    func start() {
        queue.async { self.begin() }
    }

    func stop() {
        queue.async { self.end() }
    }

    private func begin() {
        guard browser == nil, let api, let created = api.create(nil, api.kind) else { return }
        let pointer = UnsafeMutablePointer<SFContext>.allocate(capacity: 1)
        pointer.initialize(to: SFContext(version: 0, info: Unmanaged.passUnretained(self).toOpaque(), retain: nil, release: nil, copyDescription: nil))
        context = pointer
        api.setQueue(created, OpaquePointer(Unmanaged.passUnretained(queue).toOpaque()))
        api.setClient(created, { _, _, _, _, _, info in
            guard let info else { return }
            Unmanaged<AirDropBridge>.fromOpaque(info).takeUnretainedValue().refresh()
        }, UnsafeMutableRawPointer(pointer))
        browser = created
        if let root = api.root(created) {
            api.open(created, root, nil, 0)
        }
    }

    private func end() {
        guard let api, let browser else { return }
        api.invalidate(browser)
        Unmanaged<AnyObject>.fromOpaque(UnsafeRawPointer(browser)).release()
        self.browser = nil
        context?.deinitialize(count: 1)
        context?.deallocate()
        context = nil
        onUpdate([])
    }

    private func refresh() {
        guard let api, let browser, let root = api.root(browser), let array = api.children(browser, root)?.takeRetainedValue() else {
            onUpdate([])
            return
        }
        var peers: [AirDropPeer] = []
        for index in 0..<CFArrayGetCount(array) {
            guard let raw = CFArrayGetValueAtIndex(array, index) else { continue }
            let node = OpaquePointer(raw)
            let display = (api.displayName(node)?.takeRetainedValue() as String?) ?? ""
            let computer = (api.computerName?(node)?.takeRetainedValue() as String?) ?? ""
            let name = display.isEmpty ? computer : display
            guard !name.isEmpty else { continue }
            peers.append(AirDropPeer(id: name + "|" + computer, name: name))
        }
        onUpdate(peers)
    }
}
