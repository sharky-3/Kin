import AppKit
import SwiftUI

final class StatusBarController: NSObject {
    private let item = NSStatusBar.system.statusItem(withLength: StatusBarMetrics.width(for: 0, spread: false))
    private let state = StatusBarState()
    private let store: PeopleStore
    private let dropState: DropState
    private var clickMonitor: Any?
    private var host: NSView?
    private var handledAt = Date.distantPast
    var onSelect: ((Int) -> Void)?
    var onOpenSettings: (() -> Void)?
    var onHoverChange: ((Int?) -> Void)?

    private var count: Int {
        store.targets.count - 1
    }

    var frame: NSRect? {
        item.button?.window?.frame
    }

    private var rightEdge: CGFloat? {
        guard let host, let window = host.window else { return frame?.maxX }
        return window.convertToScreen(host.convert(host.bounds, to: nil)).maxX
    }

    var settingsAnchorX: CGFloat? {
        guard let rightEdge else { return nil }
        return rightEdge - StatusBarMetrics.moreRightOffset
    }

    init(store: PeopleStore, dropState: DropState) {
        self.store = store
        self.dropState = dropState
        super.init()
        let view = StatusBarView(store: store, dropState: dropState, state: state, onHover: { [weak self] in self?.updateHover() }, center: { [weak self] slot in self?.screenCenter(for: slot) })
        let host = NSHostingView(rootView: view)
        host.sizingOptions = []
        self.host = host
        if let button = item.button {
            button.title = ""
            button.image = nil
            button.isBordered = false
            button.focusRingType = .none
            (button.cell as? NSButtonCell)?.highlightsBy = []
            (button.cell as? NSButtonCell)?.showsStateBy = []
            button.target = self
            button.action = #selector(buttonClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            host.translatesAutoresizingMaskIntoConstraints = false
            button.addSubview(host)
            NSLayoutConstraint.activate([host.leadingAnchor.constraint(equalTo: button.leadingAnchor), host.trailingAnchor.constraint(equalTo: button.trailingAnchor), host.topAnchor.constraint(equalTo: button.topAnchor), host.bottomAnchor.constraint(equalTo: button.bottomAnchor)])
        }
        clickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp]) { [weak self] event in
            guard let self, self.isOverItem(event) else { return event }
            switch event.type {
            case .leftMouseDown:
                self.handledAt = Date()
                self.click()
            case .rightMouseDown:
                self.handledAt = Date()
                self.showMenu(for: event)
            default:
                break
            }
            return nil
        }
        if item.responds(to: NSSelectorFromString("setHighlightMode:")) {
            item.setValue(false, forKey: "highlightMode")
        }
        PointerTracker.shared.onMove = { [weak self] in self?.updateHover() }
        refresh()
    }

    func anchorX(for slot: Int) -> CGFloat? {
        guard let rightEdge else { return nil }
        return rightEdge - StatusBarMetrics.rightOffset(for: slot, count: count, spread: false, expanded: state.expanded)
    }

    func refresh() {
        if dropState.isActive {
            if state.expanded {
                state.expanded = false
            }
            setHovered(nil)
        }
        item.length = StatusBarMetrics.width(for: count, spread: dropState.isActive)
        item.button?.window?.acceptsMouseMovedEvents = true
    }

    private func screenCenter(for slot: Int) -> CGPoint? {
        guard let frame, let rightEdge else { return nil }
        let right = StatusBarMetrics.rightOffset(for: slot, count: count, spread: dropState.isActive, expanded: state.expanded)
        return CGPoint(x: rightEdge - right, y: frame.midY)
    }

    private func isOverItem(_ event: NSEvent) -> Bool {
        guard let window = item.button?.window else { return false }
        if event.window === window {
            return true
        }
        return window.frame.contains(NSEvent.mouseLocation)
    }

    private var pointerDistance: CGFloat? {
        guard let frame, let rightEdge else { return nil }
        let pointer = NSEvent.mouseLocation
        guard frame.insetBy(dx: -1, dy: -3).contains(pointer) else { return nil }
        return rightEdge - pointer.x
    }

    private func updateHover() {
        guard !dropState.isActive, let distance = pointerDistance else {
            setHovered(nil)
            setExpanded(false)
            return
        }
        let moreZone = StatusBarMetrics.padding + StatusBarMetrics.moreSpace
        if state.expanded {
            if distance <= moreZone + 4 {
                setHovered(nil)
            } else {
                setExpanded(false)
                setHovered(StatusBarMetrics.slot(atRight: distance, count: count, expanded: true))
            }
        } else if distance <= StatusBarMetrics.padding + 10 {
            setHovered(nil)
            setExpanded(true)
        } else {
            setHovered(StatusBarMetrics.slot(atRight: distance, count: count, expanded: false))
        }
    }

    private func setHovered(_ slot: Int?) {
        if state.hovered != slot {
            state.hovered = slot
            onHoverChange?(slot)
        }
    }

    private func setExpanded(_ expanded: Bool) {
        guard state.expanded != expanded else { return }
        state.expanded = expanded
    }

    private func click() {
        guard !dropState.isActive, let rightEdge else { return }
        let distance = rightEdge - NSEvent.mouseLocation.x
        if state.expanded && distance <= StatusBarMetrics.padding + StatusBarMetrics.moreSpace + 2 {
            onOpenSettings?()
        } else if let slot = StatusBarMetrics.slot(atRight: distance, count: count, expanded: state.expanded) {
            onSelect?(slot)
        }
    }

    @objc private func buttonClicked() {
        guard let event = NSApp.currentEvent, Date().timeIntervalSince(handledAt) > 0.6 else { return }
        if event.type == .rightMouseUp {
            showMenu(for: event)
        } else {
            click()
        }
    }

    private func showMenu(for event: NSEvent) {
        guard let button = item.button else { return }
        let menu = NSMenu()
        let settings = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: "")
        settings.target = self
        menu.addItem(settings)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit Kin", action: #selector(quit), keyEquivalent: "")
        quit.target = self
        menu.addItem(quit)
        NSMenu.popUpContextMenu(menu, with: event, for: button)
    }

    @objc private func openSettings() {
        onOpenSettings?()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
