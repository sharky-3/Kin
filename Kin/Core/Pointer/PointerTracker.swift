import AppKit
import Observation

@Observable
final class PointerTracker {
    static let shared = PointerTracker()
    private(set) var location = NSEvent.mouseLocation
    @ObservationIgnored var onMove: (() -> Void)?
    @ObservationIgnored private var monitors: [Any] = []

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
        let point = NSEvent.mouseLocation
        if abs(point.x - location.x) + abs(point.y - location.y) > 3 {
            location = point
        }
        onMove?()
    }
}
