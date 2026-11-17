import AppKit
import SwiftUI

final class HoverLabelController {
    private let panel = FloatingPanel(keyable: false)
    private var current: String?

    init() {
        panel.ignoresMouseEvents = true
    }

    func show(_ text: String, nearby: Bool, centerX: CGFloat, top: CGFloat) {
        let key = text + "\(Int(centerX))\(nearby)"
        guard current != key else { return }
        current = key
        let host = NSHostingView(rootView: HoverLabel(text: text, nearby: nearby))
        let size = host.fittingSize
        host.sizingOptions = []
        panel.host(host)
        panel.present(size: size, centerX: centerX, top: top)
    }

    func hide() {
        guard current != nil else { return }
        current = nil
        panel.dismiss()
    }
}
