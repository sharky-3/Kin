import AppKit
import SwiftUI

final class AnchorView: NSView {
    var screenCenter: CGPoint? {
        guard let window else { return nil }
        let rect = window.convertToScreen(convert(bounds, to: nil))
        return CGPoint(x: rect.midX, y: rect.midY)
    }
}

final class AnchorBox {
    weak var view: AnchorView?
}

struct ScreenAnchor: NSViewRepresentable {
    let box: AnchorBox

    func makeNSView(context: Context) -> AnchorView {
        let view = AnchorView()
        box.view = view
        return view
    }

    func updateNSView(_ nsView: AnchorView, context: Context) {
        box.view = nsView
    }
}
