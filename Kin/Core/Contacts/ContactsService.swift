import Contacts
import Foundation

nonisolated struct ContactCandidate: Identifiable, Sendable {
    let id: String
    let name: String
    let phones: [String]
    let emails: [String]
    let imageData: Data?

    var detail: String {
        phones.first ?? emails.first ?? ""
    }
}

nonisolated enum ContactsService {
    static func load() async -> [ContactCandidate]? {
        guard await authorize() else { return nil }
        return await Task.detached(priority: .userInitiated) {
            fetch()
        }.value
    }

    private static func authorize() async -> Bool {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        if status == .authorized {
            return true
        }
        if status == .denied || status == .restricted {
            return false
        }
        return await withCheckedContinuation { continuation in
            CNContactStore().requestAccess(for: .contacts) { granted, _ in
                continuation.resume(returning: granted)
            }
        }
    }

    private static func fetch() -> [ContactCandidate] {
        let store = CNContactStore()
        let keys: [CNKeyDescriptor] = [CNContactGivenNameKey as CNKeyDescriptor, CNContactFamilyNameKey as CNKeyDescriptor, CNContactOrganizationNameKey as CNKeyDescriptor, CNContactPhoneNumbersKey as CNKeyDescriptor, CNContactEmailAddressesKey as CNKeyDescriptor, CNContactThumbnailImageDataKey as CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)
        var result: [ContactCandidate] = []
        do {
            try store.enumerateContacts(with: request) { contact, _ in
                let full = [contact.givenName, contact.familyName].filter { !$0.isEmpty }.joined(separator: " ")
                let name = full.isEmpty ? contact.organizationName : full
                let phones = contact.phoneNumbers.map { $0.value.stringValue }
                let emails = contact.emailAddresses.map { $0.value as String }
                guard !name.isEmpty, !(phones.isEmpty && emails.isEmpty) else { return }
                let image = contact.isKeyAvailable(CNContactThumbnailImageDataKey) ? contact.thumbnailImageData : nil
                result.append(ContactCandidate(id: contact.identifier, name: name, phones: phones, emails: emails, imageData: image))
            }
        } catch {
            return []
        }
        return result.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}
