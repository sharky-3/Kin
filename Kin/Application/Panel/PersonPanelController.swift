import AppKit
import SwiftUI

enum PanelGuard {
    static var holds = 0
}

final class PersonPanelController {
    private let panel = FloatingPanel(keyable: true)
    private var monitor: Any?
    private var currentID: UUID?

    var isOpen: Bool {
        currentID != nil
    }

    init() {
        panel.onCancel = { [weak self] in self?.close() }
    }

    func toggle(id: UUID, anchorX: CGFloat, top: CGFloat, content: AnyView) {
        if currentID == id {
            close()
            return
        }
        open(id: id, anchorX: anchorX, top: top, content: content)
    }

    func open(id: UUID, anchorX: CGFloat, top: CGFloat, content: AnyView) {
        guard currentID != id else { return }
        removeMonitor()
        currentID = id
        let sized = content.fixedSize().onGeometryChange(for: CGSize.self) { proxy in proxy.size } action: { [weak self] size in
            Task { @MainActor in
                self?.panel.resize(to: size)
            }
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        let host = NSHostingView(rootView: sized)
        host.sizingOptions = []
        let size = NSHostingView(rootView: content).fittingSize
        panel.host(host)
        panel.present(size: size, centerX: anchorX, top: top)
        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard PanelGuard.holds == 0 else { return }
            self?.close()
        }
    }

    func close() {
        guard currentID != nil else { return }
        currentID = nil
        removeMonitor()
        panel.dismiss()
    }

    private func removeMonitor() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
    }
}
