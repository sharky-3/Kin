import PhotosUI
import ServiceManagement
import SwiftUI

/// The one panel you get by clicking yourself: your profile, your people, options and Quit.
struct ProfilePanelView: View {
    let store: PeopleStore
    let onClose: () -> Void
    @State private var route: Route
    @State private var draft: Person
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var choosingPicture = false
    @State private var cameraOpen = false
    @State private var pickingPhoto = false
    @State private var photoItem: PhotosPickerItem?
    @State private var nextHue = Double.random(in: 0...1)
    @State private var macPicture: NSImage?

    enum Route {
        case home
        case editor
        case contacts
    }

    private static let width: CGFloat = 300
    private static let avatar: CGFloat = 48

    init(store: PeopleStore, editing: Person?, onClose: @escaping () -> Void) {
        self.store = store
        self.onClose = onClose
        _route = State(initialValue: editing == nil ? .home : .editor)
        _draft = State(initialValue: editing ?? Person())
    }

    private var name: Binding<String> {
        Binding(get: { store.me.name }, set: { value in store.updateMe { $0.name = value } })
    }

    private var airdropEnabled: Binding<Bool> {
        Binding(get: { store.airdropEnabled }, set: { store.setAirDropEnabled($0) })
    }

    private var showGuests: Binding<Bool> {
        Binding(get: { store.showGuests }, set: { store.setShowGuests($0) })
    }

    private var dropEnabled: Binding<Bool> {
        Binding(get: { store.dropEnabled }, set: { store.setDropEnabled($0) })
    }

    private var page: AnyTransition {
        .asymmetric(insertion: .scale(scale: 0.97, anchor: .top).combined(with: .opacity), removal: .opacity)
    }

    var body: some View {
        ZStack(alignment: .top) {
            switch route {
            case .home:
                home
                    .padding(14)
                    .frame(width: Self.width)
                    .transition(page)
            case .editor:
                PersonEditorView(draft: $draft, isNew: !store.contains(draft), canShow: canShow(draft), onBack: { go(.home) }, onClose: onClose, onImport: { go(.contacts) }, onSave: save, onDelete: delete)
                    .padding(18)
                    .frame(width: Self.width)
                    .transition(page)
            case .contacts:
                ContactPickerView(onPick: apply, onBack: { go(.editor) }, onClose: onClose)
                    .padding(18)
                    .frame(width: Self.width, height: 440)
                    .transition(page)
            }
        }
        .overlay {
            if cameraOpen {
                CameraCaptureView(onCapture: { image in
                    if let data = ImageProcessor.avatarData(from: image) {
                        store.updateMe { $0.imageData = data }
                    }
                    cameraOpen = false
                }, onCancel: { cameraOpen = false })
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .transition(.opacity)
            }
        }
        .glassPanel(cornerRadius: 28)
        .photosPicker(isPresented: $pickingPhoto, selection: $photoItem, matching: .images)
        .animation(.spring(response: 0.36, dampingFraction: 0.8), value: choosingPicture)
        .animation(.easeOut(duration: 0.2), value: cameraOpen)
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task {
                if let raw = try? await item.loadTransferable(type: Data.self), let data = ImageProcessor.avatarData(from: raw) {
                    store.updateMe { $0.imageData = data }
                }
                photoItem = nil
            }
        }
        .onChange(of: launchAtLogin) { _, enabled in
            if enabled {
                try? SMAppService.mainApp.register()
            } else {
                try? SMAppService.mainApp.unregister()
            }
        }
    }

    // MARK: Home

    private var home: some View {
        VStack(alignment: .leading, spacing: 0) {
            identity
                .padding(.horizontal, 6)
                .padding(.top, 4)
            if choosingPicture {
                pictureChoices
                    .padding(.top, 14)
                    .transition(.asymmetric(insertion: .scale(scale: 0.92, anchor: .top).combined(with: .opacity), removal: .opacity))
            }
            PanelSection(title: "People") {
                people
            }
            .padding(.top, 20)
            PanelSection(title: "Options") {
                OptionRow(title: "Drop files on people", subtitle: "Drag a file to the menu bar to send it", isOn: dropEnabled)
                OptionRow(title: "AirDrop dot", subtitle: store.airdropAvailable ? "Shows who's nearby right now" : "Not available on this Mac", isOn: airdropEnabled, enabled: store.airdropAvailable)
                OptionRow(title: "Nearby people", subtitle: "Add up to 3 people around you", isOn: showGuests, enabled: store.airdropAvailable && store.airdropEnabled)
                OptionRow(title: "Open at login", subtitle: "Start Kin with your Mac", isOn: $launchAtLogin)
            }
            .padding(.top, 16)
            HoverRow(action: { NSApp.terminate(nil) }) {
                Text("Quit Kin")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.top, 10)
        }
    }

    private var identity: some View {
        HStack(spacing: 12) {
            Button(action: togglePictures) {
                AvatarView(person: store.me, size: Self.avatar)
                    .scaleEffect(choosingPicture ? 0.92 : 1)
            }
            .buttonStyle(.plain)
            .help("Change picture")
            VStack(alignment: .leading, spacing: 1) {
                TextField("Your name", text: name)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16, weight: .semibold))
                Text("\(store.shown.count) of \(PeopleStore.limit) in menu bar")
                    .font(.system(size: 11.5))
                    .foregroundStyle(.tertiary)
                    .contentTransition(.numericText())
            }
            Spacer(minLength: 0)
            CircleButton(symbol: "xmark", action: onClose)
                .frame(maxHeight: .infinity, alignment: .top)
        }
        .frame(height: Self.avatar)
    }

    @ViewBuilder
    private var people: some View {
        if store.people.count > 6 {
            ScrollView {
                rows
            }
            .scrollIndicators(.hidden)
            .frame(height: 6 * 40)
        } else {
            rows
        }
        HoverRow(action: { edit(Person(isShown: !store.isFull)) }) {
            Image(systemName: "plus")
                .font(.system(size: 11, weight: .semibold))
                .frame(width: 26, height: 26)
            Text(store.people.isEmpty ? "Add your first person" : "Add person")
                .font(.system(size: 13))
        }
        .foregroundStyle(.secondary)
    }

    private var rows: some View {
        VStack(spacing: 0) {
            ForEach(Array(store.people.enumerated()), id: \.element.id) { index, person in
                PersonRow(person: person, canShow: canShow(person), canMoveUp: index > 0, canMoveDown: index < store.people.count - 1, onToggle: { toggle(person) }, onMove: { offset in move(person, by: offset) }, onEdit: { edit(person) }, onDelete: { remove(person) })
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
    }

    // MARK: Picture

    private func togglePictures() {
        if macPicture == nil {
            macPicture = AccountPicture.image
        }
        choosingPicture.toggle()
    }

    private var pictureChoices: some View {
        HStack(spacing: 0) {
            PictureChoice(title: "Shuffle") {
                FaceView(person: Person(name: store.me.name, hue: nextHue), size: 30, tracks: false)
            } action: {
                let hue = nextHue
                store.updateMe {
                    $0.imageData = nil
                    $0.hue = hue
                }
                nextHue = Monster.shuffledHue(from: hue)
            }
            PictureChoice(title: "Mac") {
                macIcon
            } action: {
                if let macPicture, let data = ImageProcessor.avatarData(from: macPicture) {
                    store.updateMe { $0.imageData = data }
                }
            }
            PictureChoice(title: "Photos") {
                symbol("photo")
            } action: {
                NSApp.activate(ignoringOtherApps: true)
                pickingPhoto = true
            }
            PictureChoice(title: "File") {
                symbol("folder")
            } action: {
                if let data = ImageProcessor.chooseFile() {
                    store.updateMe { $0.imageData = data }
                }
            }
            PictureChoice(title: "Camera") {
                symbol("camera")
            } action: {
                choosingPicture = false
                cameraOpen = true
            }
        }
    }

    private func symbol(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.white.opacity(0.8))
    }

    @ViewBuilder
    private var macIcon: some View {
        if let macPicture {
            Image(nsImage: macPicture)
                .resizable()
                .scaledToFill()
                .frame(width: 30, height: 30)
                .clipShape(Circle())
        } else {
            symbol("person.crop.circle")
        }
    }

    // MARK: People

    private func go(_ next: Route) {
        choosingPicture = false
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
        go(.home)
    }

    private func delete() {
        store.remove(draft)
        go(.home)
    }

    private func canShow(_ person: Person) -> Bool {
        let stored = store.people.first { $0.id == person.id }
        return stored?.isShown == true || !store.isFull
    }

    private func toggle(_ person: Person) {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            store.setShown(person, !person.isShown)
        }
    }

    private func move(_ person: Person, by offset: Int) {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            store.move(person, by: offset)
        }
    }

    private func remove(_ person: Person) {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
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

private struct PictureChoice<Icon: View>: View {
    let title: String
    @ViewBuilder let icon: Icon
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                icon
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(hovering ? 0.12 : 0.06), in: Circle())
                    .scaleEffect(hovering ? 1.06 : 1)
                Text(title)
                    .font(.system(size: 10.5))
                    .foregroundStyle(.white.opacity(hovering ? 0.9 : 0.5))
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: hovering)
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
        HoverRow(action: onEdit) {
            AvatarView(person: person, size: 26, tracks: false)
                .opacity(person.isShown ? 1 : 0.4)
            Text(person.name)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(person.isShown ? 0.95 : 0.45))
                .lineLimit(1)
            Spacer(minLength: 4)
            HStack(spacing: 0) {
                control("chevron.up", enabled: canMoveUp) { onMove(-1) }
                control("chevron.down", enabled: canMoveDown) { onMove(1) }
                control("trash", enabled: true, action: onDelete)
            }
            .opacity(hovering ? 1 : 0)
            .allowsHitTesting(hovering)
            Button(action: onToggle) {
                Image(systemName: person.isShown ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 15))
                    .foregroundStyle(.white.opacity(person.isShown ? 0.9 : canShow ? 0.3 : 0.1))
                    .contentTransition(.symbolEffect(.replace))
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!canShow)
            .help(person.isShown ? "Hide from menu bar" : canShow ? "Show in menu bar" : "Menu bar is full")
        }
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.14), value: hovering)
    }

    private func control(_ symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.55))
                .frame(width: 22, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.3)
    }
}
