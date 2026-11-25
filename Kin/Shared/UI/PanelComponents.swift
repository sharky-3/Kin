import SwiftUI

// Everything here sits directly on the glass panel: no nested cards, strokes or
// materials. Grouping comes from spacing and type, and hover gives a faint fill.

struct PanelHeader: View {
    let title: String
    var onBack: (() -> Void)?
    let onClose: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            if let onBack {
                CircleButton(symbol: "chevron.left", action: onBack)
            }
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .lineLimit(1)
            Spacer()
            CircleButton(symbol: "xmark", action: onClose)
        }
        .frame(height: 26)
    }
}

struct CircleButton: View {
    let symbol: String
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(.white.opacity(hovering ? 0.95 : 0.5))
                .frame(width: 26, height: 26)
                .background(.white.opacity(hovering ? 0.1 : 0), in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.12), value: hovering)
    }
}

struct PanelSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.tertiary)
                .padding(.leading, 8)
                .padding(.bottom, 2)
            content
        }
    }
}

/// A full-width row that lights up faintly on hover.
struct HoverRow<Content: View>: View {
    var action: (() -> Void)?
    @ViewBuilder let content: Content
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 11) {
            content
        }
        .padding(.horizontal, 8)
        .frame(height: 40)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(hovering && action != nil ? 0.07 : 0), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
        .contentShape(Rectangle())
        .onTapGesture { action?() }
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.14), value: hovering)
    }
}

struct OptionRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    var enabled = true

    var body: some View {
        HoverRow {
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13))
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.mini)
        }
        .frame(height: 44)
        .opacity(enabled ? 1 : 0.4)
        .disabled(!enabled)
        .animation(.easeOut(duration: 0.18), value: enabled)
    }
}

struct Chip: View {
    let text: String
    @State private var hovering = false

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.white.opacity(hovering ? 0.95 : 0.6))
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(.white.opacity(hovering ? 0.12 : 0.06), in: Capsule())
            .onHover { hovering = $0 }
            .animation(.easeOut(duration: 0.12), value: hovering)
    }
}

struct Caption: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11))
            .foregroundStyle(.tertiary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SettingRow<Trailing: View>: View {
    let title: String
    let caption: String
    let trailing: Trailing

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 13))
                Spacer()
                trailing
            }
            Caption(text: caption)
        }
        .padding(.horizontal, 4)
    }
}

struct PillButton: View {
    let title: String
    var symbol: String?
    var prominent = false
    var destructive = false
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 11, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundStyle(destructive ? Color.red.opacity(0.9) : prominent ? Color.black : Color.white.opacity(0.85))
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .background(background, in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.12), value: hovering)
    }

    private var background: Color {
        if prominent { return .white.opacity(hovering ? 1 : 0.9) }
        return .white.opacity(hovering ? 0.1 : 0.05)
    }
}

struct HoverLabel: View {
    let text: String
    var nearby = false

    var body: some View {
        HStack(spacing: 6) {
            if nearby {
                Circle()
                    .fill(.green)
                    .frame(width: 6, height: 6)
                    .shadow(color: .green.opacity(0.8), radius: 3)
            }
            Text(text)
                .font(.system(size: 12, weight: .medium))
                .lineLimit(1)
        }
        .padding(.leading, nearby ? 9 : 11)
        .padding(.trailing, 11)
        .padding(.vertical, 5)
        .fixedSize()
        .glassPanel(cornerRadius: 13)
    }
}

extension View {
    func pillField() -> some View {
        self
            .textFieldStyle(.plain)
            .font(.system(size: 13))
            .padding(.horizontal, 12)
            .frame(height: 34)
            .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
