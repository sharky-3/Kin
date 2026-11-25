import AppKit

final class FloatingPanel: NSPanel {
    static let inset: CGFloat = 24
    /// Posted with the panel as the object, so its SwiftUI content can play its exit before the window hides.
    static let willDismiss = Notification.Name("FloatingPanelWillDismiss")
    private let keyable: Bool
    private var generation = 0
    var onCancel: (() -> Void)?

    init(keyable: Bool) {
        self.keyable = keyable
        super.init(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
        isFloatingPanel = true
        level = .statusBar
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        hidesOnDeactivate = false
        isMovable = false
        acceptsMouseMovedEvents = true
        isReleasedWhenClosed = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
    }

    override var canBecomeKey: Bool { keyable }
    override var canBecomeMain: Bool { false }

    override func cancelOperation(_ sender: Any?) {
        onCancel?()
    }

    func host(_ view: NSView) {
        let container = NSView(frame: NSRect(origin: .zero, size: frame.size))
        view.frame = container.bounds
        view.autoresizingMask = [.width, .height]
        container.addSubview(view)
        contentView = container
    }

    func present(size: NSSize, centerX: CGFloat, top: CGFloat) {
        let anchor = NSPoint(x: centerX, y: top - 1)
        let screen = NSScreen.screens.first { $0.frame.contains(anchor) } ?? NSScreen.main
        var x = centerX - size.width / 2
        if let bounds = screen?.frame {
            x = min(max(x, bounds.minX - Self.inset + 8), bounds.maxX - size.width + Self.inset - 8)
        }
        let y = top + Self.inset - 6 - size.height
        setFrame(NSRect(x: x, y: y, width: size.width, height: size.height), display: true)
        generation += 1
        // The SwiftUI content animates itself in (see GlassPanel), so the window just appears.
        alphaValue = 1
        if keyable {
            makeKeyAndOrderFront(nil)
        } else {
            orderFrontRegardless()
        }
    }

    private var resizeGeneration = 0

    /// Grows right away so new content has room, but shrinks only after SwiftUI's
    /// transition has finished, so the outgoing content isn't clipped mid-animation.
    func resize(to size: NSSize) {
        guard isVisible, size.width > 1, size.height > 1 else { return }
        guard abs(frame.width - size.width) > 0.5 || abs(frame.height - size.height) > 0.5 else { return }
        resizeGeneration += 1
        let current = resizeGeneration
        let grows = size.width >= frame.width && size.height >= frame.height
        if grows {
            applySize(size)
        } else {
            let grown = NSSize(width: max(size.width, frame.width), height: max(size.height, frame.height))
            applySize(grown)
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(0.38))
                guard let self, self.resizeGeneration == current else { return }
                self.applySize(size)
            }
        }
    }

    private func applySize(_ size: NSSize) {
        guard abs(frame.width - size.width) > 0.5 || abs(frame.height - size.height) > 0.5 else { return }
        var x = frame.midX - size.width / 2
        if let bounds = screen?.frame {
            x = min(max(x, bounds.minX - Self.inset + 8), bounds.maxX - size.width + Self.inset - 8)
        }
        setFrame(NSRect(x: x, y: frame.maxY - size.height, width: size.width, height: size.height), display: true)
    }

    func dismiss() {
        guard isVisible else { return }
        generation += 1
        let current = generation
        NotificationCenter.default.post(name: Self.willDismiss, object: self)
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(0.2))
            guard let self, self.generation == current else { return }
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.08
                self.animator().alphaValue = 0
            }, completionHandler: nil)
            try? await Task.sleep(for: .seconds(0.09))
            guard self.generation == current else { return }
            self.orderOut(nil)
        }
    }
}
