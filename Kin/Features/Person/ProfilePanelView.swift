import PhotosUI
import ServiceManagement
import SwiftUI

struct ProfilePanelView: View {
    let store: PeopleStore
    let onClose: () -> Void
    let onOpenSettings: () -> Void
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled
    @State private var menuOpen = false
    @State private var cameraOpen = false
    @State private var pickingPhoto = false
    @State private var photoItem: PhotosPickerItem?
    @State private var nextHue = Double.random(in: 0...1)
    @State private var macPicture: NSImage?

    private var name: Binding<String> {
        Binding(get: { store.me.name }, set: { value in store.updateMe { $0.name = value } })
    }

    private var dropEnabled: Binding<Bool> {
        Binding(get: { store.dropEnabled }, set: { store.setDropEnabled($0) })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            PanelHeader(title: "Profile", onClose: onClose, onExpand: onOpenSettings)
            identity
            VStack(alignment: .leading, spacing: 10) {
                SectionLabel(text: "Name")
                TextField("First name and surname", text: name)
                    .pillField()
                Caption(text: "Your initials become the eyes of your face.")
            }
            SettingRow(title: "Drop files on people", caption: "Drag a file toward the menu bar and let go over someone to send it.", trailing: Toggle("", isOn: dropEnabled).labelsHidden().toggleStyle(.switch))
            SettingRow(title: "Open at login", caption: "Keep your people in the menu bar every time you start your Mac.", trailing: Toggle("", isOn: $launchAtLogin).labelsHidden().toggleStyle(.switch))
        }
        .padding(30)
        .frame(width: 340)
        .overlay {
            if menuOpen {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { menuOpen = false }
            }
        }
        .overlay(alignment: .topLeading) {
            if menuOpen {
                photoMenu
                    .padding(.leading, 30)
                    .padding(.top, 182)
                    .transition(.scale(scale: 0.82, anchor: .topLeading).combined(with: .opacity))
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
                .clipShape(RoundedRectangle(cornerRadius: 42, style: .continuous))
                .transition(.opacity)
            }
        }
        .glassPanel(cornerRadius: 42)
        .photosPicker(isPresented: $pickingPhoto, selection: $photoItem, matching: .images)
        .animation(.spring(response: 0.34, dampingFraction: 0.76), value: menuOpen)
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

    private var identity: some View {
        HStack(spacing: 16) {
            RingedAvatar(person: store.me, badge: Button(action: toggleMenu) { BadgeIcon(symbol: "pencil") }.buttonStyle(.plain))
                .onTapGesture(perform: toggleMenu)
            VStack(alignment: .leading, spacing: 6) {
                Text(store.me.name.isEmpty ? "You" : store.me.name)
                    .font(.system(size: 16, weight: .bold))
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Circle()
                        .fill(.green)
                        .frame(width: 7, height: 7)
                    Text("\(store.shown.count) of \(PeopleStore.limit) in menu bar")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Button(action: onOpenSettings) {
                    Chip(text: "Manage people")
                }
                .buttonStyle(.plain)
            }
            Spacer(minLength: 0)
        }
    }

    private func toggleMenu() {
        if macPicture == nil {
            macPicture = AccountPicture.image
        }
        menuOpen.toggle()
    }

    private var photoMenu: some View {
        VStack(alignment: .leading, spacing: 2) {
            DropdownRow(title: "Use Mac picture", icon: macIcon) {
                menuOpen = false
                if let macPicture, let data = ImageProcessor.avatarData(from: macPicture) {
                    store.updateMe { $0.imageData = data }
                }
            }
            DropdownRow(title: "Photo Library", icon: DropdownSymbol(name: "photo.on.rectangle")) {
                menuOpen = false
                NSApp.activate(ignoringOtherApps: true)
                pickingPhoto = true
            }
            DropdownRow(title: "Choose file…", icon: DropdownSymbol(name: "folder")) {
                menuOpen = false
                if let data = ImageProcessor.chooseFile() {
                    store.updateMe { $0.imageData = data }
                }
            }
            DropdownRow(title: "Take photo", icon: DropdownSymbol(name: "camera")) {
                menuOpen = false
                cameraOpen = true
            }
            DropdownDivider()
            DropdownRow(title: "Shuffle face", icon: FaceView(person: Person(name: store.me.name, hue: nextHue), size: 22, tracks: false)) {
                let hue = nextHue
                store.updateMe {
                    $0.imageData = nil
                    $0.hue = hue
                }
                nextHue = Double.random(in: 0...1)
            }
        }
        .frame(width: 236)
        .dropdownSurface()
    }

    @ViewBuilder
    private var macIcon: some View {
        if let macPicture {
            Image(nsImage: macPicture)
                .resizable()
                .scaledToFill()
                .frame(width: 22, height: 22)
                .clipShape(Circle())
        } else {
            DropdownSymbol(name: "person.crop.circle")
        }
    }
}
