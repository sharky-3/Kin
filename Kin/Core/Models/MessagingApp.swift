import Foundation

nonisolated enum MessagingApp: String, CaseIterable, Identifiable, Sendable {
    case messages
    case whatsapp
    case telegram
    case signal
    case facetime
    case mail

    var id: String { rawValue }

    var title: String {
        switch self {
        case .messages: "Messages"
        case .whatsapp: "WhatsApp"
        case .telegram: "Telegram"
        case .signal: "Signal"
        case .facetime: "FaceTime"
        case .mail: "Mail"
        }
    }

    var symbol: String {
        switch self {
        case .messages: "message.fill"
        case .whatsapp: "phone.bubble.fill"
        case .telegram: "paperplane.fill"
        case .signal: "bubble.left.and.bubble.right.fill"
        case .facetime: "video.fill"
        case .mail: "envelope.fill"
        }
    }

    var bundleIDs: [String] {
        switch self {
        case .messages: ["com.apple.MobileSMS"]
        case .whatsapp: ["net.whatsapp.WhatsApp", "WhatsApp", "desktop.WhatsApp"]
        case .telegram: ["ru.keepcoder.Telegram", "org.telegram.desktop", "com.tdesktop.Telegram"]
        case .signal: ["org.whispersystems.signal-desktop"]
        case .facetime: ["com.apple.FaceTime"]
        case .mail: ["com.apple.mail"]
        }
    }

    var acceptsText: Bool {
        switch self {
        case .signal, .facetime: false
        default: true
        }
    }

    func canReach(_ person: Person) -> Bool {
        switch self {
        case .messages, .facetime: person.messageHandle != nil
        case .whatsapp, .signal: !person.digits.isEmpty
        case .telegram: !person.telegramHandle.isEmpty || !person.digits.isEmpty
        case .mail: !person.trimmedEmail.isEmpty
        }
    }

    func url(for person: Person, text: String) -> URL? {
        let body = Self.encode(text)
        let hasText = !text.isEmpty
        switch self {
        case .messages:
            guard let handle = person.messageHandle else { return nil }
            return URL(string: "sms:" + Self.encode(handle, keeping: "+") + (hasText ? "&body=" + body : ""))
        case .whatsapp:
            return URL(string: "whatsapp://send?phone=" + person.digits + (hasText ? "&text=" + body : ""))
        case .telegram:
            if !person.telegramHandle.isEmpty {
                return URL(string: "tg://resolve?domain=" + Self.encode(person.telegramHandle) + (hasText ? "&text=" + body : ""))
            }
            return URL(string: "tg://resolve?phone=" + person.digits + (hasText ? "&text=" + body : ""))
        case .signal:
            return URL(string: "sgnl://signal.me/#p/+" + person.digits)
        case .facetime:
            guard let handle = person.messageHandle else { return nil }
            return URL(string: "facetime://" + Self.encode(handle, keeping: "+"))
        case .mail:
            return URL(string: "mailto:" + Self.encode(person.trimmedEmail) + (hasText ? "?body=" + body : ""))
        }
    }

    private static func encode(_ value: String, keeping extra: String = "") -> String {
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~@" + extra)
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }
}
