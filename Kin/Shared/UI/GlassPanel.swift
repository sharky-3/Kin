import SwiftUI

struct GlassPanel<Content: View>: View {
    let cornerRadius: CGFloat
    var glass = true
    let content: Content
    @State private var shown = false

    var body: some View {
        surface
            .scaleEffect(shown ? 1 : 0.3, anchor: .top)
            .opacity(shown ? 1 : 0)
            .blur(radius: shown ? 0 : 8)
            .padding(FloatingPanel.inset)
            .environment(\.colorScheme, .dark)
            .onAppear {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) {
                    shown = true
                }
            }
    }

    @ViewBuilder
    private var surface: some View {
        if glass {
            content
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .shadow(color: .black.opacity(0.2), radius: 22, y: 10)
        } else {
            content
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
