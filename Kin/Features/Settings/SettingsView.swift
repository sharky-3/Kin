import SwiftUI

struct SettingsView: View {
    let store: PeopleStore
    let onClose: () -> Void
    @State private var route: Route
    @State private var draft: Person

    enum Route {
        case list
        case editor
        case contacts
    }

    init(store: PeopleStore, editing: Person?, onClose: @escaping () -> Void) {
        self.store = store
        self.onClose = onClose
        _route = State(initialValue: editing == nil ? .list : .editor)
        _draft = State(initialValue: editing ?? Person())
    }

    var body: some View {
        ZStack {
            switch route {
            case .list:
                list
                    .padding(10)
                    .frame(width: 290)
                    .transition(.blurReplace)
            case .editor:
                PersonEditorView(draft: $draft, isNew: !store.contains(draft), canShow: canShow(draft), onBack: { go(.list) }, onClose: onClose, onImport: { go(.contacts) }, onSave: save, onDelete: delete)
                    .padding(26)
                    .frame(width: 330)
                    .transition(.blurReplace)
            case .contacts:
                ContactPickerView(onPick: apply, onBack: { go(.editor) }, onClose: onClose)
                    .padding(26)
                    .frame(width: 330, height: 460)
                    .transition(.blurReplace)
            }
        }
        .glassPanel(cornerRadius: 30)
    }

    private var list: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("People")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(store.shown.count) of \(PeopleStore.limit) in menu bar")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)
            .padding(.bottom, 6)
            if store.people.count > 7 {
                ScrollView {
                    rows
                }
                .scrollIndicators(.hidden)
                .frame(height: 330)
            } else {
                rows
            }
            DropdownRow(title: store.people.isEmpty ? "Add your first person…" : "Add person…", icon: DropdownSymbol(name: "plus.circle.fill")) { edit(Person(isShown: !store.isFull)) }
            DropdownDivider()
            DropdownRow(title: "Quit Kin", icon: DropdownSymbol(name: "power")) { NSApp.terminate(nil) }
        }
    }

    private var rows: some View {
        VStack(spacing: 2) {
            ForEach(Array(store.people.enumerated()), id: \.element.id) { index, person in
                PersonRow(person: person, canShow: canShow(person), canMoveUp: index > 0, canMoveDown: index < store.people.count - 1, onToggle: { toggle(person) }, onMove: { offset in move(person, by: offset) }, onEdit: { edit(person) }, onDelete: { remove(person) })
            }
        }
    }

    private func go(_ next: Route) {
        withAnimation(.spring(response: 0.36, dampingFraction: 0.86)) {
            route = next
        }
    }

    private func edit(_ person: Person) {
        draft = person
        go(.editor)
    }

    private func save() {
        draft.name = draft.name.trimmingCharacters(in: .whitespaces)
        store.save(draft)
        go(.list)
    }

    private func delete() {
        store.remove(draft)
        go(.list)
    }

    private func canShow(_ person: Person) -> Bool {
        let stored = store.people.first { $0.id == person.id }
        return stored?.isShown == true || !store.isFull
    }

    private func toggle(_ person: Person) {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
            store.setShown(person, !person.isShown)
        }
    }

    private func move(_ person: Person, by offset: Int) {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
            store.move(person, by: offset)
        }
    }

    private func remove(_ person: Person) {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
            store.remove(person)
        }
    }

    private func apply(_ contact: ContactCandidate) {
        draft.name = contact.name
        draft.phone = contact.phones.first ?? ""
        draft.email = contact.emails.first ?? ""
        draft.imageData = contact.imageData.flatMap { ImageProcessor.avatarData(from: $0) }
        go(.editor)
    }
}

private struct PersonRow: View {
    let person: Person
    let canShow: Bool
    let canMoveUp: Bool
    let canMoveDown: Bool
    let onToggle: () -> Void
    let onMove: (Int) -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(person: person, size: 28, tracks: false)
                .opacity(person.isShown ? 1 : 0.45)
            Text(person.name)
                .font(.system(size: 13.5, weight: .medium))
                .foregroundStyle(.white.opacity(person.isShown ? 0.95 : 0.55))
                .lineLimit(1)
            Spacer(minLength: 4)
            if hovering {
                HStack(spacing: 0) {
                    control("chevron.up", enabled: canMoveUp) { onMove(-1) }
                    control("chevron.down", enabled: canMoveDown) { onMove(1) }
                    control("trash", enabled: true, action: onDelete)
                }
                .transition(.opacity)
            }
            Button(action: onToggle) {
                Image(systemName: person.isShown ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 17))
                    .foregroundStyle(person.isShown ? Color.accentColor : Color.white.opacity(canShow ? 0.4 : 0.15))
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!canShow)
            .help(person.isShown ? "Hide from menu bar" : canShow ? "Show in menu bar" : "Menu bar is full")
        }
        .padding(.leading, 9)
        .padding(.trailing, 10)
        .frame(height: 42)
        .background(.white.opacity(hovering ? 0.16 : 0), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture(perform: onEdit)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.12), value: hovering)
    }

    private func control(_ symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 22, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.3)
    }
}
