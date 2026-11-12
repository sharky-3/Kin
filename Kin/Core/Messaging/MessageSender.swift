import AppKit

enum SendResult {
    case sent
    case opened
    case failed
}

enum MessageSender {
    static func send(_ text: String, files: [URL], to person: Person, via app: MessagingApp) async -> SendResult {
        let hasContent = !text.isEmpty || !files.isEmpty
        if app == .messages, hasContent, let handle = person.messageHandle {
            PanelGuard.holds += 1
            let delivered = await deliver(text, files: files, to: handle)
            PanelGuard.holds -= 1
            if delivered {
                return .sent
            }
            if !files.isEmpty {
                return FileSender.compose(text: text, files: files, to: person) ? .opened : .failed
            }
        }
        if !files.isEmpty {
            FileSender.send(files, to: person)
        }
        guard let url = app.url(for: person, text: app.acceptsText ? text : "") else { return files.isEmpty ? .failed : .opened }
        return NSWorkspace.shared.open(url) ? .opened : .failed
    }

    private static func deliver(_ text: String, files: [URL], to handle: String) async -> Bool {
        var lines = ["tell application \"Messages\"", "set targetService to 1st account whose service type = iMessage", "set targetBuddy to participant \"\(escape(handle))\" of targetService"]
        if !text.isEmpty {
            lines.append("send \"\(escape(text))\" to targetBuddy")
        }
        for file in files {
            lines.append("send (POSIX file \"\(escape(file.path))\") to targetBuddy")
        }
        lines.append("end tell")
        let source = lines.joined(separator: "\n")
        return await Task.detached {
            var error: NSDictionary?
            NSAppleScript(source: source)?.executeAndReturnError(&error)
            return error == nil
        }.value
    }

    private static func escape(_ value: String) -> String {
        value.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
    }
}
