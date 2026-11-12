import AppKit

final class FloatingPanel: NSPanel {
    static let inset: CGFloat = 24
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
        alphaValue = 0
        if keyable {
            makeKeyAndOrderFront(nil)
        } else {
            orderFrontRegardless()
        }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.16
            animator().alphaValue = 1
        }
    }

    func resize(to size: NSSize) {
        guard isVisible, size.width > 1, size.height > 1 else { return }
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
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            animator().alphaValue = 0
        }
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(0.14))
            guard let self, self.generation == current else { return }
            self.orderOut(nil)
        }
    }
}
