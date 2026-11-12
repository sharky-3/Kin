import SwiftUI

struct FaceView: View {
    let person: Person
    let size: CGFloat
    var tracks = true
    var screenCenter: (() -> CGPoint?)?
    @State private var anchor = AnchorBox()

    private var ink: Color {
        .black.opacity(0.9)
    }

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
        let eyes = person.eyes
        let tint = Color(hue: person.hue, saturation: 0.82, brightness: 1)
        ZStack {
            tint.opacity(0.2)
            Blob(seed: person.hue)
                .fill(tint)
                .frame(width: size, height: size * 1.18)
                .offset(y: size * 0.3)
            VStack(spacing: size * 0.02) {
                HStack(spacing: size * 0.11) {
                    eye(eyes[0])
                    eye(eyes[1])
                }
                .offset(x: gaze.width * size * 0.035, y: gaze.height * size * 0.03)
                Mouth()
                    .fill(ink)
                    .frame(width: size * 0.14, height: size * 0.075)
            }
            .offset(x: gaze.width * size * 0.07, y: size * 0.11 + gaze.height * size * 0.05)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .background {
            if screenCenter == nil && tracks {
                ScreenAnchor(box: anchor)
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.68), value: gaze)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: person.hue)
    }

    private func eye(_ letter: String) -> some View {
        Text(letter)
            .font(.system(size: size * 0.28, weight: .black, design: .rounded))
            .foregroundStyle(ink)
            .fixedSize()
    }
}

private struct Blob: Shape {
    var seed: Double

    var animatableData: Double {
        get { seed }
        set { seed = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let count = 7
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radiusX = rect.width / 2
        let radiusY = rect.height / 2
        var points: [CGPoint] = []
        for index in 0..<count {
            let angle = Double(index) / Double(count) * 2 * Double.pi + seed * 6.283
            let wobble = 0.87 + 0.13 * (0.5 + 0.5 * sin(seed * 37 + Double(index) * 2.4))
            let reach = CGFloat(wobble)
            points.append(CGPoint(x: center.x + CGFloat(cos(angle)) * radiusX * reach, y: center.y + CGFloat(sin(angle)) * radiusY * reach))
        }
        var path = Path()
        path.move(to: points[0])
        for index in 0..<count {
            let before = points[(index + count - 1) % count]
            let start = points[index]
            let end = points[(index + 1) % count]
            let after = points[(index + 2) % count]
            let first = CGPoint(x: start.x + (end.x - before.x) / 6, y: start.y + (end.y - before.y) / 6)
            let second = CGPoint(x: end.x - (after.x - start.x) / 6, y: end.y - (after.y - start.y) / 6)
            path.addCurve(to: end, control1: first, control2: second)
        }
        path.closeSubpath()
        return path
    }
}

private struct Mouth: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addCurve(to: CGPoint(x: rect.minX, y: rect.minY), control1: CGPoint(x: rect.maxX, y: rect.maxY * 1.35), control2: CGPoint(x: rect.minX, y: rect.maxY * 1.35))
        path.closeSubpath()
        return path
    }
}
