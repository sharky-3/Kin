import SwiftUI

struct FaceView: View {
    let person: Person
    let size: CGFloat
    var tracks = true
    var screenCenter: (() -> CGPoint?)?
    @State private var anchor = AnchorBox()

    private var look: CGSize {
        guard tracks else { return .zero }
        let pointer = PointerTracker.shared.location
        let origin = screenCenter.map { $0() } ?? anchor.view?.screenCenter
        guard let center = origin else { return .zero }
        let dx = pointer.x - center.x
        let dy = center.y - pointer.y
        let distance = hypot(dx, dy)
        guard distance > 1 else { return .zero }
        let strength = min(1, distance / 140)
        return CGSize(width: dx / distance * strength, height: dy / distance * strength)
    }

    var body: some View {
        let gaze = look
        let name = Monster.name(for: person.hue)
        ZStack {
            Image(name)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: size, height: size)
                .rotationEffect(.degrees(gaze.width * 9))
                .offset(x: gaze.width * size * 0.06, y: gaze.height * size * 0.05)
                .id(name)
                .transition(.scale(scale: 0.4).combined(with: .opacity))
        }
        .frame(width: size, height: size)
        .background {
            if screenCenter == nil && tracks {
                ScreenAnchor(box: anchor)
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.68), value: gaze)
        .animation(.spring(response: 0.45, dampingFraction: 0.6), value: name)
    }
}
