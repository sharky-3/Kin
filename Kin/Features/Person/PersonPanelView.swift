import SwiftUI
import UniformTypeIdentifiers

struct PersonPanelView: View {
    let store: PeopleStore
    let chat: ChatStore
    let person: Person
    let onClose: () -> Void
    let onEdit: () -> Void
    private let apps: [MessagingApp]
    @State private var selected: MessagingApp?
    @State private var text = ""
    @State private var attachments: [URL] = []
    @State private var mode = Mode.idle
    @State private var recorder = VoiceRecorder()
    @State private var audio = AudioPreview()
    @State private var isSending = false
    @State private var notice: String?
    @State private var dropTargeted = false
    @FocusState private var focused: Bool

    enum Mode {
        case idle
        case recording
        case recorded
    }

    init(store: PeopleStore, chat: ChatStore, person: Person, onClose: @escaping () -> Void, onEdit: @escaping () -> Void) {
        self.store = store
        self.chat = chat
        self.person = person
        self.onClose = onClose
        self.onEdit = onEdit
        let available = AppCatalog.apps(for: person)
        apps = available
        _selected = State(initialValue: available.first)
    }

    private var trimmed: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canDrop: Bool {
        guard selected != nil, !isSending else { return false }
        return mode == .recorded || !trimmed.isEmpty || !attachments.isEmpty
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 8) {
            ForEach(chat.entries(for: person.id).suffix(6)) { entry in
                ChatBubbleView(entry: entry, audio: audio)
                    .transition(.scale(scale: 0.8, anchor: .bottomTrailing).combined(with: .opacity))
            }
            composer
        }
        .frame(width: 310)
        .floatingStack()
        .onAppear { focused = true }
        .onDisappear {
            recorder.clear(deleting: mode != .idle)
            audio.stop()
        }
        .animation(.spring(response: 0.36, dampingFraction: 0.8), value: chat.entries(for: person.id).count)
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: mode)
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: attachments)
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !attachments.isEmpty {
                attachmentRow
            }
            switch mode {
            case .idle:
                TextField("Note to \(person.firstName)…", text: $text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .lineLimit(1...5)
                    .focused($focused)
                    .onSubmit(drop)
            case .recording, .recorded:
                voiceBlock
            }
            controls
            if let notice {
                Caption(text: notice)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(dropTargeted ? 0.1 : 0), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .glassBubble(cornerRadius: 26)
        .onDrop(of: [.fileURL], isTargeted: $dropTargeted) { _ in
            add(DragMonitor.draggedFiles)
            return true
        }
    }

    private var attachmentRow: some View {
        HStack(spacing: 8) {
            ForEach(attachments, id: \.self) { url in
                FileThumb(url: url, side: 52)
                    .overlay(alignment: .topTrailing) {
                        Button(action: { attachments.removeAll { $0 == url } }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 7, weight: .heavy))
                                .foregroundStyle(.white)
                                .frame(width: 16, height: 16)
                                .background(.black.opacity(0.55), in: Circle())
                        }
                        .buttonStyle(.plain)
                        .offset(x: 4, y: -4)
                    }
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private var voiceBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "captions.bubble")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                WaveformView(levels: recorder.levels.isEmpty ? Array(repeating: 0.08, count: 40) : recorder.levels)
                Spacer(minLength: 0)
            }
            Text(recorder.transcript.isEmpty ? (mode == .recording ? "Listening…" : "Voice note") : recorder.transcript)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(recorder.transcript.isEmpty ? 0.5 : 0.9))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var controls: some View {
        switch mode {
        case .idle:
            HStack(spacing: 14) {
                appMenu
                icon("waveform", help: "Record a voice note", action: startRecording)
                icon("paperclip", help: "Attach files", action: pickFiles)
                icon("pencil", help: "Edit \(person.firstName)", action: onEdit)
                Spacer(minLength: 0)
                pill("Drop", symbol: "return", active: canDrop, action: drop)
            }
        case .recording:
            HStack(spacing: 8) {
                Circle()
                    .fill(.orange)
                    .frame(width: 8, height: 8)
                Text("Recording")
                    .font(.system(size: 12, weight: .medium))
                Text(Clock.format(recorder.elapsed))
                    .font(.system(size: 12).monospacedDigit())
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
                pill("Stop", symbol: "return", active: false, action: stopRecording)
            }
        case .recorded:
            HStack(spacing: 10) {
                icon("trash", help: "Discard", action: discard)
                Spacer(minLength: 0)
                if let url = recorder.fileURL {
                    pill(Clock.format(recorder.elapsed), symbol: audio.playing == url.path ? "pause.fill" : "play.fill", active: false, leading: true) { audio.toggle(url) }
                }
                pill("Drop", symbol: "return", active: canDrop, action: drop)
            }
        }
    }

    @ViewBuilder
    private var appMenu: some View {
        if let selected {
            Menu {
                ForEach(apps) { app in
                    Button(app.title) { self.selected = app }
                }
            } label: {
                AppIcon(app: selected)
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .menuIndicator(.hidden)
            .fixedSize()
            .help("Send with \(selected.title)")
        } else {
            Image(systemName: "exclamationmark.bubble")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .help("Add a phone number or email for \(person.firstName) in Settings")
        }
    }

    private func icon(_ symbol: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 22, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(help)
    }

    private func pill(_ title: String, symbol: String, active: Bool, leading: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if leading {
                    Image(systemName: symbol)
                        .font(.system(size: 9, weight: .bold))
                }
                Text(title)
                    .font(.system(size: 12, weight: .semibold).monospacedDigit())
                if !leading {
                    Image(systemName: symbol)
                        .font(.system(size: 9, weight: .bold))
                        .opacity(0.7)
                }
            }
            .foregroundStyle(.white.opacity(active || leading || title == "Stop" ? 1 : 0.45))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(active ? Color.accentColor : Color.white.opacity(0.12), in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func add(_ urls: [URL]) {
        for url in urls where !attachments.contains(url) && attachments.count < 5 {
            attachments.append(url)
        }
    }

    private func pickFiles() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 1)
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK else { return }
        add(panel.urls)
    }

    private func startRecording() {
        notice = nil
        Task {
            if await recorder.start() {
                mode = .recording
            } else {
                notice = "Kin can't use the microphone. Allow it in System Settings › Privacy & Security."
            }
        }
    }

    private func stopRecording() {
        recorder.stop()
        mode = .recorded
    }

    private func discard() {
        audio.stop()
        recorder.clear(deleting: true)
        mode = .idle
        focused = true
    }

    private func drop() {
        if mode == .recording {
            stopRecording()
            return
        }
        guard let app = selected, !isSending else { return }
        let voice = mode == .recorded ? recorder.fileURL : nil
        let message = mode == .recorded ? recorder.transcript : trimmed
        var files = attachments
        if let voice {
            files.append(voice)
        }
        let length = recorder.elapsed
        isSending = true
        notice = nil
        audio.stop()
        Task {
            let result = await MessageSender.send(message, files: files, to: person, via: app)
            isSending = false
            switch result {
            case .failed:
                notice = "Couldn't reach \(app.title) for \(person.firstName)."
            case .sent, .opened:
                guard !message.isEmpty || !files.isEmpty else {
                    onClose()
                    return
                }
                chat.add(ChatEntry(text: message, files: attachments.map { $0.path }, voice: voice?.path, duration: length, app: app.rawValue), for: person.id)
                text = ""
                attachments = []
                recorder.clear(deleting: false)
                mode = .idle
                focused = true
            }
        }
    }
}

private struct AppIcon: View {
    let app: MessagingApp

    var body: some View {
        if let image = AppCatalog.icon(for: app) {
            Image(nsImage: image)
                .resizable()
                .interpolation(.high)
                .frame(width: 22, height: 22)
        } else {
            Image(systemName: app.symbol)
                .font(.system(size: 14, weight: .medium))
                .frame(width: 22, height: 22)
        }
    }
}
