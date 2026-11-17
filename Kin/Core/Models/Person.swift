import Foundation

nonisolated enum DropAction: String, Codable, CaseIterable, Identifiable, Sendable {
    case airdrop
    case messages
    case mail

    var id: String { rawValue }

    var title: String {
        switch self {
        case .airdrop: "AirDrop"
        case .messages: "Messages"
        case .mail: "Mail"
        }
    }

    var symbol: String {
        switch self {
        case .airdrop: "dot.radiowaves.left.and.right"
        case .messages: "message.fill"
        case .mail: "envelope.fill"
        }
    }
}

nonisolated struct Person: Identifiable, Codable, Hashable, Sendable {
    var id = UUID()
    var name = ""
    var phone = ""
    var email = ""
    var telegram = ""
    var imageData: Data?
    var hue = Double.random(in: 0...1)
    var dropAction = DropAction.airdrop
    var isShown = true
    var isGuest = false

    var firstName: String {
        name.split(separator: " ").first.map(String.init) ?? name
    }

    var eyes: [String] {
        let letters = name.split(separator: " ").compactMap { $0.first }.map { String($0).uppercased() }
        let first = letters.first ?? "o"
        let second = letters.count > 1 ? letters[letters.count - 1] : first
        return [first, second]
    }

    var digits: String {
        phone.filter { $0.isNumber }
    }

    var compactPhone: String {
        phone.filter { $0.isNumber || $0 == "+" }
    }

    var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var telegramHandle: String {
        telegram.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "@", with: "")
    }

    var messageHandle: String? {
        if !compactPhone.isEmpty { return compactPhone }
        if !trimmedEmail.isEmpty { return trimmedEmail }
        return nil
    }

    var summary: String {
        [phone.trimmingCharacters(in: .whitespaces), trimmedEmail].filter { !$0.isEmpty }.joined(separator: "  ·  ")
    }
}

extension Person {
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init()
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        phone = try container.decodeIfPresent(String.self, forKey: .phone) ?? ""
        email = try container.decodeIfPresent(String.self, forKey: .email) ?? ""
        telegram = try container.decodeIfPresent(String.self, forKey: .telegram) ?? ""
        imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
        hue = try container.decodeIfPresent(Double.self, forKey: .hue) ?? Double.random(in: 0...1)
        dropAction = try container.decodeIfPresent(DropAction.self, forKey: .dropAction) ?? .airdrop
        isShown = try container.decodeIfPresent(Bool.self, forKey: .isShown) ?? true
        isGuest = false
    }
}
