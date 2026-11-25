import SwiftUI

/// Wraps panel content in Liquid Glass and gives it a liquid entrance and exit:
/// the glass starts as a small squashed droplet under the menu bar, stretches open
/// with two slightly different springs (width lags height, so it wobbles like a
/// drop), and the content fades in once there's room for it. Closing runs the
/// same motion in reverse before the window goes away.
struct GlassPanel<Content: View>: View {
    let cornerRadius: CGFloat
    var glass = true
    let content: Content
    @State private var tall = false
    @State private var wide = false
    @State private var filled = false
    @State private var anchor = AnchorBox()

    var body: some View {
        surface
            .scaleEffect(x: wide ? 1 : 0.42, y: tall ? 1 : 0.16, anchor: .top)
            .offset(y: tall ? 0 : -6)
            .opacity(tall || wide ? 1 : 0)
            .padding(FloatingPanel.inset)
            .background(ScreenAnchor(box: anchor))
            .environment(\.colorScheme, .dark)
            .onAppear(perform: open)
            .onReceive(NotificationCenter.default.publisher(for: FloatingPanel.willDismiss)) { note in
                guard let window = anchor.view?.window, (note.object as? NSWindow) === window else { return }
                close()
            }
    }

    @ViewBuilder
    private var surface: some View {
        let inner = content
            .opacity(filled ? 1 : 0)
            .blur(radius: filled ? 0 : 4)
        if glass {
            inner
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .shadow(color: .black.opacity(0.25), radius: 24, y: 12)
        } else {
            inner
        }
    }

    private func open() {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.62)) {
            tall = true
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.68).delay(0.02)) {
            wide = true
        }
        withAnimation(.easeOut(duration: 0.22).delay(0.1)) {
            filled = true
        }
    }

    private func close() {
        withAnimation(.easeIn(duration: 0.1)) {
            filled = false
        }
        withAnimation(.spring(response: 0.26, dampingFraction: 0.9).delay(0.03)) {
            tall = false
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.9).delay(0.06)) {
            wide = false
        }
    }
}

extension View {
    func glassPanel(cornerRadius: CGFloat) -> some View {
        GlassPanel(cornerRadius: cornerRadius, content: self)
    }

    func floatingStack() -> some View {
        GlassPanel(cornerRadius: 0, glass: false, content: self)
    }

    func glassBubble(cornerRadius: CGFloat) -> some View {
        self
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: .black.opacity(0.18), radius: 12, y: 5)
    }
}
