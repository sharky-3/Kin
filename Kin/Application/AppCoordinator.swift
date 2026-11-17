import AppKit
import SwiftUI

final class AppCoordinator {
    private let store = PeopleStore()
    private let dropState = DropState()
    private let dragMonitor = DragMonitor()
    private let panel = PersonPanelController()
    private let chat = ChatStore()
    private let label = HoverLabelController()
    private let airdrop = AirDropNearby()
    private var hoveredSlot: Int?
    private let settingsID = UUID()
    private var statusBar: StatusBarController?
    private var dropPanel: DropPanelController?

    func start() {
        _ = PointerTracker.shared
        let bar = StatusBarController(store: store, dropState: dropState)
        bar.onSelect = { [weak self] slot in self?.togglePanel(at: slot) }
        bar.onOpenSettings = { [weak self] in self?.toggleSettings() }
        bar.onHoverChange = { [weak self] slot in self?.showLabel(for: slot) }
        statusBar = bar

        let people = self.store
        let state = self.dropState
        dropPanel = DropPanelController { [weak self] in
            AnyView(DropZoneView(store: people, dropState: state) { person, urls in
                self?.hideDrop()
                FileSender.send(urls, to: person)
            })
        }

        store.onChange = { [weak self] in
            guard let self else { return }
            self.statusBar?.refresh()
            self.airdrop.setActive(self.store.airdropEnabled)
        }
        airdrop.onChange = { [weak self] in
            guard let self else { return }
            self.store.setGuests(self.airdrop.guests(excluding: self.store.people))
            if let slot = self.hoveredSlot {
                self.showLabel(for: slot)
            }
        }
        store.airdropAvailable = airdrop.isAvailable
        airdrop.setActive(store.airdropEnabled)

        dragMonitor.onMove = { [weak self] point in self?.dragMoved(to: point) }
        dragMonitor.onEnd = { [weak self] in
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(0.3))
                self?.hideDrop()
            }
        }
        dragMonitor.start()

        if store.people.isEmpty {
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(0.8))
                self?.openSettings(editing: nil)
            }
        }
    }

    func openSettings(editing person: Person?) {
        guard let anchor = settingsAnchor else { return }
        if person != nil {
            panel.close()
        }
        panel.open(id: settingsID, anchorX: anchor.x, top: anchor.y, content: settingsView(editing: person))
    }

    private func toggleSettings() {
        guard let anchor = settingsAnchor else { return }
        label.hide()
        panel.toggle(id: settingsID, anchorX: anchor.x, top: anchor.y, content: settingsView(editing: nil))
    }

    private var settingsAnchor: NSPoint? {
        guard let frame = statusBar?.frame, let x = statusBar?.settingsAnchorX else { return nil }
        return NSPoint(x: x, y: frame.minY)
    }

    private func settingsView(editing person: Person?) -> AnyView {
        AnyView(SettingsView(store: store, editing: person, onClose: { [weak self] in self?.panel.close() }))
    }

    private func togglePanel(at slot: Int) {
        guard let frame = statusBar?.frame, let anchorX = statusBar?.anchorX(for: slot), store.targets.indices.contains(slot) else { return }
        let person = store.targets[slot]
        if person.isGuest {
            label.hide()
            panel.close()
            FileSender.pickAndSend(to: person)
            return
        }
        let close: () -> Void = { [weak self] in self?.panel.close() }
        let view: AnyView
        if slot == 0 {
            view = AnyView(ProfilePanelView(store: store, onClose: close, onOpenSettings: { [weak self] in self?.openSettings(editing: nil) }))
        } else {
            view = AnyView(PersonPanelView(store: store, chat: chat, person: person, onClose: close, onEdit: { [weak self] in self?.openSettings(editing: person) }))
        }
        label.hide()
        panel.toggle(id: person.id, anchorX: anchorX, top: frame.minY, content: view)
    }

    private func dragMoved(to point: NSPoint) {
        guard store.dropEnabled, !panel.isOpen, let frame = statusBar?.frame, let dropPanel else { return }
        if dropPanel.isVisible {
            if !dropPanel.keepRect.contains(point) {
                hideDrop()
            }
            return
        }
        let trigger = NSRect(x: frame.midX - 380, y: frame.minY - 240, width: 760, height: frame.height + 240)
        if trigger.contains(point) {
            label.hide()
            dropState.isActive = true
            statusBar?.refresh()
            dropPanel.show(below: frame)
        }
    }

    private func showLabel(for slot: Int?) {
        hoveredSlot = slot
        guard let slot, !panel.isOpen, !dropState.isActive, store.targets.indices.contains(slot), let frame = statusBar?.frame, let x = statusBar?.anchorX(for: slot) else {
            label.hide()
            return
        }
        let person = store.targets[slot]
        let near = slot > 0 && store.airdropEnabled && (person.isGuest || airdrop.isNearby(person))
        let title = slot == 0 ? "You" : person.isGuest ? person.name : person.firstName
        label.show(title, nearby: near, centerX: x, top: frame.minY)
    }

    private func hideDrop() {
        guard dropState.isActive else { return }
        dropPanel?.hide()
        dropState.isActive = false
        dropState.targetIndex = nil
        dropState.location = nil
        statusBar?.refresh()
    }
}
