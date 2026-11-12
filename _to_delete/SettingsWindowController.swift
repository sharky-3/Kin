import AppKit
import SwiftUI

final class SettingsWindowController {
    private var window: NSWindow?

    func show(store: PeopleStore) {
        if window == nil {
            let created = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 520, height: 640), styleMask: [.titled, .closable, .fullSizeContentView], backing: .buffered, defer: false)
            created.title = "Kin"
            created.titleVisibility = .hidden
            created.titlebarAppearsTransparent = true
            created.isMovableByWindowBackground = true
            created.isReleasedWhenClosed = false
            created.contentViewController = NSHostingController(rootView: SettingsView(store: store))
            created.setContentSize(NSSize(width: 520, height: 640))
            created.center()
            window = created
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
