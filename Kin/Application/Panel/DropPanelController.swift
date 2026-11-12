import AppKit
import SwiftUI

final class DropPanelController {
    private let panel = FloatingPanel(keyable: false)
    private let makeContent: () -> AnyView
    private var showing = false

    var isVisible: Bool { showing }

    var keepRect: NSRect {
        let frame = panel.frame
        return NSRect(x: frame.minX - 60, y: frame.minY - 60, width: frame.width + 120, height: frame.height + 200)
    }

    init(makeContent: @escaping () -> AnyView) {
        self.makeContent = makeContent
    }

    func show(below frame: NSRect) {
        showing = true
        let host = NSHostingView(rootView: makeContent())
        let size = host.fittingSize
        host.sizingOptions = []
        panel.host(host)
        panel.present(size: size, centerX: frame.midX, top: frame.minY)
    }

    func hide() {
        guard showing else { return }
        showing = false
        panel.dismiss()
    }
}
