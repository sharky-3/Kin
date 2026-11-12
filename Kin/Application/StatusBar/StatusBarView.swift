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

    private var showsMore: Bool {
        !spread && state.expanded
    }

    var body: some View {
        let people = store.targets
        ZStack(alignment: .trailing) {
            ForEach(Array(people.enumerated()), id: \.element.id) { slot, person in
                avatar(person, slot: slot, count: people.count - 1)
            }
            Image(systemName: "ellipsis")
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(.black.opacity(0.75))
                .frame(width: StatusBarMetrics.more, height: StatusBarMetrics.more)
                .background(.white, in: Circle())
                .opacity(showsMore ? 1 : 0)
                .scaleEffect(showsMore ? 1 : 0.4)
                .offset(x: -(StatusBarMetrics.moreRightOffset - StatusBarMetrics.more / 2))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        .contentShape(Rectangle())
        .onContinuousHover { _ in onHover() }
        .animation(.spring(response: 0.3, dampingFraction: 0.72), value: state.hovered)
        .animation(.smooth(duration: 0.28), value: showsMore)
        .animation(.spring(response: 0.3, dampingFraction: 0.72), value: dropState.targetIndex)
        .animation(.spring(response: 0.36, dampingFraction: 0.76), value: spread)
    }

    private func avatar(_ person: Person, slot: Int, count: Int) -> some View {
        let own = slot == 0
        let targeted = spread && dropState.targetIndex == slot
        let lifted = targeted || (!spread && state.hovered == slot)
        let ringed = own || targeted
        let size = StatusBarMetrics.avatar
        let ring: Color = targeted ? .white : own ? (person.imageData == nil ? Color(hue: person.hue, saturation: 0.85, brightness: 1) : .white.opacity(0.6)) : .clear
        let right = StatusBarMetrics.rightOffset(for: slot, count: count, spread: spread, expanded: state.expanded)
        return AvatarView(person: person, size: size - (ringed ? 5 : 0), screenCenter: { center(slot) })
            .frame(width: size, height: size)
            .overlay(Circle().strokeBorder(ring, lineWidth: 1.5))
            .overlay(Circle().strokeBorder(.black.opacity(ringed ? 0 : 0.22), lineWidth: 0.5))
            .scaleEffect(targeted ? 1.2 : lifted ? 1.12 : 1)
            .offset(x: -(right - size / 2))
            .zIndex(lifted ? 100 : Double(slot))
    }
}
