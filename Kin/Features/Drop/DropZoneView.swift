import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    let store: PeopleStore
    let dropState: DropState
    let onDrop: (Person, [URL]) -> Void
    private let size = CGSize(width: 380, height: 186)

    private var target: Person? {
        guard let slot = dropState.targetIndex, store.targets.indices.contains(slot) else { return nil }
        return store.targets[slot]
    }

    private var label: String {
        guard let slot = dropState.targetIndex, let target else { return "Drop to send" }
        return slot == 0 ? "Drop to Me" : "Drop to \(target.firstName)"
    }

    var body: some View {
        ZStack {
            DotGrid(focus: dropState.location)
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(target == nil ? 0.6 : 0.95))
                .id(label)
                .transition(.blurReplace)
        }
        .frame(width: size.width, height: size.height)
        .contentShape(Rectangle())
        .onDrop(of: [.fileURL], delegate: PeopleDropDelegate(count: store.targets.count, width: size.width, dropState: dropState, perform: perform))
        .glassPanel(cornerRadius: 46)
        .animation(.easeOut(duration: 0.22), value: label)
    }

    private func perform(_ slot: Int) {
        guard store.targets.indices.contains(slot) else { return }
        onDrop(store.targets[slot], DragMonitor.draggedFiles)
    }
}

private struct PeopleDropDelegate: DropDelegate {
    let count: Int
    let width: CGFloat
    let dropState: DropState
    let perform: (Int) -> Void

    func validateDrop(info: DropInfo) -> Bool {
        count > 0 && info.hasItemsConforming(to: [.fileURL])
    }

    func dropEntered(info: DropInfo) {
        update(info)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        update(info)
        return DropProposal(operation: .copy)
    }

    func dropExited(info: DropInfo) {
        dropState.targetIndex = nil
        dropState.location = nil
    }

    func performDrop(info: DropInfo) -> Bool {
        perform(slot(for: info))
        return true
    }

    private func slot(for info: DropInfo) -> Int {
        let span = width / CGFloat(max(count, 1))
        return min(max(Int(info.location.x / span), 0), max(count - 1, 0))
    }

    private func update(_ info: DropInfo) {
        let target = slot(for: info)
        if dropState.targetIndex != target {
            dropState.targetIndex = target
        }
        dropState.location = info.location
    }
}

private struct DotGrid: View {
    let focus: CGPoint?

    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 12
            let columns = Int(size.width / spacing)
            let rows = Int(size.height / spacing)
            let offsetX = (size.width - CGFloat(columns - 1) * spacing) / 2
            let offsetY = (size.height - CGFloat(rows - 1) * spacing) / 2
            for column in 0..<columns {
                for row in 0..<rows {
                    let x = offsetX + CGFloat(column) * spacing
                    let y = offsetY + CGFloat(row) * spacing
                    var glow: CGFloat = 0
                    if let focus {
                        glow = max(0, 1 - hypot(x - focus.x, y - focus.y) / 110)
                    }
                    let radius: CGFloat = 0.8 + glow * 0.9
                    let opacity = Double(0.1 + glow * 0.75)
                    context.fill(Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)), with: .color(.white.opacity(opacity)))
                }
            }
        }
        .mask(RoundedRectangle(cornerRadius: 34, style: .continuous).padding(10))
        .allowsHitTesting(false)
    }
}
