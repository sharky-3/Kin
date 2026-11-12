import AppKit

enum AppCatalog {
    static func location(of app: MessagingApp) -> URL? {
        for identifier in app.bundleIDs {
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: identifier) {
                return url
            }
        }
        return nil
    }

    static func isInstalled(_ app: MessagingApp) -> Bool {
        location(of: app) != nil
    }

    static func icon(for app: MessagingApp) -> NSImage? {
        guard let url = location(of: app) else { return nil }
        return NSWorkspace.shared.icon(forFile: url.path)
    }

    static func apps(for person: Person) -> [MessagingApp] {
        MessagingApp.allCases.filter { isInstalled($0) && $0.canReach(person) }
    }
}
