import AppKit

enum FileSender {
    static func compose(text: String, files: [URL], to person: Person) -> Bool {
        guard let service = NSSharingService(named: .composeMessage) else { return false }
        service.recipients = person.messageHandle.map { [$0] }
        var items: [Any] = files
        if !text.isEmpty {
            items.insert(text, at: 0)
        }
        guard service.canPerform(withItems: items) else { return false }
        NSApp.activate(ignoringOtherApps: true)
        service.perform(withItems: items)
        return true
    }

    static func send(_ urls: [URL], to person: Person) {
        guard !urls.isEmpty else { return }
        let service: NSSharingService?
        switch person.dropAction {
        case .airdrop:
            service = NSSharingService(named: .sendViaAirDrop)
        case .messages:
            service = NSSharingService(named: .composeMessage)
            service?.recipients = person.messageHandle.map { [$0] }
        case .mail:
            service = NSSharingService(named: .composeEmail)
            service?.recipients = person.trimmedEmail.isEmpty ? nil : [person.trimmedEmail]
        }
        NSApp.activate(ignoringOtherApps: true)
        guard let service, service.canPerform(withItems: urls) else {
            NSSharingService(named: .sendViaAirDrop)?.perform(withItems: urls)
            return
        }
        service.perform(withItems: urls)
    }
}
