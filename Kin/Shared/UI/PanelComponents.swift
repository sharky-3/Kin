import SwiftUI

struct PanelHeader: View {
    let title: String
    var onBack: (() -> Void)?
    let onClose: () -> Void
    var onExpand: (() -> Void)?

    var body: some View {
        HStack(spacing: 10) {
            if let onBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 26, height: 26)
                        .background(.white.opacity(0.12), in: Circle())
                }
                .buttonStyle(.plain)
            }
            Text(title)
                .font(.system(size: 19, weight: .bold))
                .lineLimit(1)
            Spacer()
            Button(action: onClose) {
                Text("Esc")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.12), in: Capsule())
            }
            .buttonStyle(.plain)
            if let onExpand {
                Button(action: onExpand) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 26)
    }
}

struct RingedAvatar<Badge: View>: View {
    let person: Person
    var size: CGFloat = 78
    let badge: Badge

    var body: some View {
        AvatarView(person: person, size: size)
            .padding(size * 0.1)
            .background(.white.opacity(0.08), in: Circle())
            .overlay(Circle().strokeBorder(.white.opacity(0.3), lineWidth: 1))
            .overlay(alignment: .topTrailing) { badge }
    }
}

struct BadgeIcon: View {
    let symbol: String

    var body: some View {
        Image(systemName: symbol)
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(.white.opacity(0.85))
            .frame(width: 24, height: 24)
            .background(.ultraThinMaterial, in: Circle())
            .overlay(Circle().strokeBorder(.white.opacity(0.2), lineWidth: 0.5))
            .contentShape(Circle())
    }
}

struct Chip: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.white.opacity(0.12), in: Capsule())
    }
}

struct SectionLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
    }
}

struct Caption: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 12))
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Spacer()
                trailing
            }
            Caption(text: caption)
        }
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
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(destructive ? Color.red : Color.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(prominent ? Color.accentColor.opacity(hovering ? 1 : 0.9) : Color.white.opacity(hovering ? 0.18 : 0.1), in: Capsule())
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

struct DropdownRow<Icon: View>: View {
    let title: String
    let icon: Icon
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                icon
                    .frame(width: 22, height: 22)
                Text(title)
                    .font(.system(size: 13.5, weight: .medium))
                    .foregroundStyle(.white.opacity(hovering ? 1 : 0.88))
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(height: 38)
            .background(.white.opacity(hovering ? 0.16 : 0), in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.12), value: hovering)
    }
}

struct DropdownSymbol: View {
    let name: String

    var body: some View {
        Image(systemName: name)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(.white.opacity(0.75))
    }
}

struct DropdownDivider: View {
    var body: some View {
        Rectangle()
            .fill(.white.opacity(0.14))
            .frame(height: 1)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
    }
}

struct HoverLabel: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold))
            .lineLimit(1)
            .padding(.horizontal, 11)
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
            .padding(.horizontal, 16)
            .padding(.vertical, 11)
            .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    func dropdownSurface() -> some View {
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
        return self
            .padding(7)
            .background(.black.opacity(0.28), in: shape)
            .background(.ultraThinMaterial, in: shape)
            .overlay(shape.strokeBorder(LinearGradient(colors: [.white.opacity(0.38), .white.opacity(0.06)], startPoint: .top, endPoint: .bottom), lineWidth: 1))
            .shadow(color: .black.opacity(0.35), radius: 28, y: 14)
    }
}
