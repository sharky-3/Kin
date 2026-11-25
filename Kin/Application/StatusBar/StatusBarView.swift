import SwiftUI

struct StatusBarView: View {
    let store: PeopleStore
    let dropState: DropState
    let state: StatusBarState
    let onHover: () -> Void
    let center: (Int) -> CGPoint?

    private var spread: Bool {
        dropState.isActive
    }

    var body: some View {
        let people = store.targets
        ZStack(alignment: .trailing) {
            ForEach(Array(people.enumerated()), id: \.element.id) { slot, person in
                avatar(person, slot: slot, count: people.count - 1)
                    .transition(.scale(scale: 0.5).combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        .contentShape(Rectangle())
        .onContinuousHover { _ in onHover() }
        .animation(.spring(response: 0.28, dampingFraction: 0.74), value: state.hovered)
        .animation(.spring(response: 0.3, dampingFraction: 0.78), value: dropState.targetIndex)
        .animation(.spring(response: 0.34, dampingFraction: 0.8), value: spread)
        .animation(.spring(response: 0.36, dampingFraction: 0.82), value: people.map(\.id))
    }

    private func avatar(_ person: Person, slot: Int, count: Int) -> some View {
        let own = slot == 0
        let targeted = spread && dropState.targetIndex == slot
        let lifted = targeted || (!spread && state.hovered == slot)
        let monster = person.imageData == nil
        let ringed = !monster && (own || targeted)
        let size = StatusBarMetrics.avatar
        let ring: Color = !ringed ? .clear : targeted ? .white : .white.opacity(0.6)
        let right = StatusBarMetrics.rightOffset(for: slot, count: count, spread: spread, target: dropState.targetIndex)
        return AvatarView(person: person, size: size - (ringed ? 5 : 0), screenCenter: { center(slot) })
            .frame(width: size, height: size)
            .overlay(Circle().strokeBorder(ring, lineWidth: 1.5))
            .overlay(Circle().strokeBorder(.black.opacity(ringed || monster ? 0 : 0.22), lineWidth: 0.5))
            .scaleEffect(targeted ? 1.2 : lifted ? 1.12 : 1)
            .offset(x: -(right - size / 2))
            .zIndex(lifted ? 100 : Double(slot))
    }
}
