import SwiftUI

struct PersonEditorView: View {
    @Binding var draft: Person
    let isNew: Bool
    let canShow: Bool
    let onBack: () -> Void
    let onClose: () -> Void
    let onImport: () -> Void
    let onSave: () -> Void
    let onDelete: () -> Void

    private var canSave: Bool {
        !draft.name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            PanelHeader(title: isNew ? "New person" : "Edit person", onBack: onBack, onClose: onClose)
            VStack(alignment: .leading, spacing: 16) {
                identity
                VStack(spacing: 6) {
                    field("Name", text: $draft.name, prompt: "Full name")
                    field("Phone", text: $draft.phone, prompt: "+386 40 123 456")
                    field("Email", text: $draft.email, prompt: "name@example.com")
                    field("Telegram", text: $draft.telegram, prompt: "username")
                }
                SettingRow(title: "Show in menu bar", caption: canShow ? "Up to 5 people sit in the menu bar. Everyone else waits in your list." : "The menu bar is full. Hide someone else first.", trailing: Toggle("", isOn: $draft.isShown).labelsHidden().toggleStyle(.switch).disabled(!canShow))
                SettingRow(title: "Dropped files", caption: "Use the phone number with its country code so WhatsApp, Signal and Telegram can find the chat.", trailing: dropPicker)
            }
            VStack(spacing: 8) {
                PillButton(title: isNew ? "Add person" : "Save", prominent: true, action: onSave)
                    .disabled(!canSave)
                    .opacity(canSave ? 1 : 0.5)
                if !isNew {
                    PillButton(title: "Remove", destructive: true, action: onDelete)
                }
            }
        }
    }

    private var identity: some View {
        HStack(spacing: 14) {
            AvatarView(person: draft, size: 52, tracks: false)
            VStack(alignment: .leading, spacing: 6) {
                Button(action: onImport) {
                    Chip(text: "From Contacts…")
                }
                .buttonStyle(.plain)
                Button(action: choosePhoto) {
                    Chip(text: "Choose photo…")
                }
                .buttonStyle(.plain)
                if draft.imageData != nil {
                    Button(action: { draft.imageData = nil }) {
                        Chip(text: "Use monster")
                    }
                    .buttonStyle(.plain)
                } else {
                    Button(action: { draft.hue = Monster.shuffledHue(from: draft.hue) }) {
                        Chip(text: "Shuffle monster")
                    }
                    .buttonStyle(.plain)
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var dropPicker: some View {
        Picker("", selection: $draft.dropAction) {
            ForEach(DropAction.allCases) { action in
                Text(action.title).tag(action)
            }
        }
        .labelsHidden()
        .pickerStyle(.menu)
        .fixedSize()
    }

    private func field(_ title: String, text: Binding<String>, prompt: String) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .foregroundStyle(.secondary)
                .frame(width: 62, alignment: .leading)
            TextField("", text: text, prompt: Text(prompt))
        }
        .pillField()
    }

    private func choosePhoto() {
        if let data = ImageProcessor.chooseFile() {
            draft.imageData = data
        }
    }
}
