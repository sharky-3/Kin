import AppKit

final class DragMonitor {
    var onMove: ((NSPoint) -> Void)?
    var onEnd: (() -> Void)?
    private let pasteboard = NSPasteboard(name: .drag)
    private var monitors: [Any] = []
    private var baseline = 0
    private var carriesFiles: Bool?

    static var draggedFiles: [URL] {
        let items = NSPasteboard(name: .drag).readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true])
        return (items as? [URL]) ?? []
    }

    func start() {
        baseline = pasteboard.changeCount
        observe(.leftMouseDown) { [weak self] in self?.began() }
        observe(.leftMouseDragged) { [weak self] in self?.moved() }
        observe(.leftMouseUp) { [weak self] in self?.ended() }
    }

    private func observe(_ mask: NSEvent.EventTypeMask, action: @escaping () -> Void) {
        if let monitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: { _ in action() }) {
            monitors.append(monitor)
        }
    }

    private func began() {
        baseline = pasteboard.changeCount
        carriesFiles = nil
    }

    private func moved() {
        if carriesFiles == nil {
            guard pasteboard.changeCount != baseline else { return }
            carriesFiles = pasteboard.canReadObject(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true])
        }
        guard carriesFiles == true else { return }
        onMove?(NSEvent.mouseLocation)
    }

    private func ended() {
        guard carriesFiles == true else { return }
        carriesFiles = nil
        baseline = pasteboard.changeCount
        onEnd?()
    }
}
