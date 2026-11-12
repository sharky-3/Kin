import SwiftUI
import UniformTypeIdentifiers

struct ChatBubbleView: View {
    let entry: ChatEntry
    let audio: AudioPreview

    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            if !entry.files.isEmpty {
                HStack(spacing: 6) {
                    ForEach(entry.files.prefix(4), id: \.self) { path in
                        FileThumb(url: URL(fileURLWithPath: path), side: 62)
                    }
                }
            }
            if let voice = entry.voice {
                voiceBubble(URL(fileURLWithPath: voice))
            } else if !entry.text.isEmpty {
                Text(entry.text)
                    .font(.system(size: 13, weight: .medium))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 8)
                    .glassBubble(cornerRadius: 17)
            }
        }
        .frame(maxWidth: 260, alignment: .trailing)
    }

    private func voiceBubble(_ url: URL) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Button(action: { audio.toggle(url) }) {
                    Image(systemName: audio.playing == url.path ? "pause.fill" : "play.fill")
                        .font(.system(size: 11))
                        .frame(width: 18, height: 18)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Text(Clock.format(entry.duration))
                    .font(.system(size: 12, weight: .medium).monospacedDigit())
                WaveformView(levels: Clock.pattern(seed: entry.id.hashValue, count: 26), height: 16)
                    .opacity(0.6)
            }
            if !entry.text.isEmpty {
                Text(entry.text)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 9)
        .glassBubble(cornerRadius: 17)
    }
}

struct FileThumb: View {
    let url: URL
    let side: CGFloat
    @State private var image: NSImage?

    var body: some View {
        ZStack {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                    .resizable()
                    .scaledToFit()
                    .padding(side * 0.14)
            }
        }
        .frame(width: side, height: side)
        .background(.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: side * 0.26, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: side * 0.26, style: .continuous).strokeBorder(.white.opacity(0.25), lineWidth: 1))
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        .help(url.lastPathComponent)
        .task(id: url) {
            guard image == nil, let type = UTType(filenameExtension: url.pathExtension), type.conforms(to: .image) else { return }
            image = NSImage(contentsOf: url)
        }
    }
}

struct WaveformView: View {
    let levels: [CGFloat]
    var height: CGFloat = 22

    var body: some View {
        HStack(alignment: .center, spacing: 2) {
            ForEach(Array(levels.enumerated()), id: \.offset) { _, level in
                Capsule()
                    .fill(.white.opacity(0.85))
                    .frame(width: 2, height: max(2, level * height))
            }
        }
        .frame(height: height)
    }
}

enum Clock {
    static func format(_ seconds: Double) -> String {
        let total = Int(seconds.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    static func pattern(seed: Int, count: Int) -> [CGFloat] {
        (0..<count).map { index in
            let wave = sin(Double(index) * 0.9 + Double(abs(seed) % 97)) * 0.5 + 0.5
            return CGFloat(0.2 + wave * 0.8)
        }
    }
}
