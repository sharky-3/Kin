import AppKit
import Observation

@Observable
final class PointerTracker {
    static let shared = PointerTracker()
    /// Every face that follows the pointer redraws when this changes, so it's published at most
    /// ~40 times a second, and only after a real move.
    private(set) var location = NSEvent.mouseLocation
    @ObservationIgnored var onMove: (() -> Void)?
    @ObservationIgnored private var monitors: [Any] = []
    @ObservationIgnored private var lastPublish = Date.distantPast
    @ObservationIgnored private var pending = false
    private static let interval: TimeInterval = 1.0 / 40

    private init() {
        if let global = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged], handler: { [weak self] _ in self?.update() }) {
            monitors.append(global)
        }
        if let local = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged, .mouseEntered, .mouseExited], handler: { [weak self] event in
            self?.update()
            return event
        }) {
            monitors.append(local)
        }
    }

    private func update() {
        onMove?()
        let wait = Self.interval - Date().timeIntervalSince(lastPublish)
        if wait <= 0 {
            publish()
        } else if !pending {
            // Trailing update so faces settle on where the pointer actually stopped.
            pending = true
            DispatchQueue.main.asyncAfter(deadline: .now() + wait) { [weak self] in
                self?.pending = false
                self?.publish()
            }
        }
    }

    private func publish() {
        lastPublish = Date()
        let point = NSEvent.mouseLocation
        if abs(point.x - location.x) + abs(point.y - location.y) > 3 {
            location = point
        }
    }
}
