import SwiftUI

struct ContactPickerView: View {
    let onPick: (ContactCandidate) -> Void
    let onBack: () -> Void
    let onClose: () -> Void
    @State private var contacts: [ContactCandidate] = []
    @State private var query = ""
    @State private var isLoading = true
    @State private var denied = false
    @FocusState private var searching: Bool

    private var results: [ContactCandidate] {
        let term = query.trimmingCharacters(in: .whitespaces)
        guard !term.isEmpty else { return contacts }
        return contacts.filter { $0.name.localizedCaseInsensitiveContains(term) || $0.detail.localizedCaseInsensitiveContains(term) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            PanelHeader(title: "Contacts", onBack: onBack, onClose: onClose)
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search", text: $query)
                    .focused($searching)
            }
            .pillField()
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .task {
            PanelGuard.holds += 1
            let loaded = await ContactsService.load()
            PanelGuard.holds -= 1
            if let loaded {
                contacts = loaded
            } else {
                denied = true
            }
            isLoading = false
            searching = true
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            ProgressView()
                .controlSize(.small)
        } else if denied {
            VStack(spacing: 8) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.secondary)
                Text("Kin can't read your contacts")
                    .font(.system(size: 13, weight: .semibold))
                Text("Allow access in System Settings › Privacy & Security › Contacts, or go back and type the details in.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        } else if results.isEmpty {
            Text("No contacts found")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        } else {
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(results) { contact in
                        ContactRow(contact: contact) { onPick(contact) }
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }
}

private struct ContactRow: View {
    let contact: ContactCandidate
    let action: () -> Void
    @State private var hovering = false

    private var preview: Person {
        Person(name: contact.name, imageData: contact.imageData, hue: Double(contact.name.unicodeScalars.reduce(0) { ($0 + Int($1.value)) % 100 }) / 100)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                AvatarView(person: preview, size: 30, tracks: false)
                VStack(alignment: .leading, spacing: 1) {
                    Text(contact.name)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)
                    Text(contact.detail)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.white.opacity(hovering ? 0.1 : 0), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}
