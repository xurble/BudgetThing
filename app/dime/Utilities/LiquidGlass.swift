import SwiftUI

struct LiquidGlassBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.PrimaryBackground,
                    Color.SecondaryBackground.opacity(0.75),
                    Color.PrimaryBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    Color.SecondaryBackground.opacity(0.6),
                    Color.clear
                ],
                center: .topTrailing,
                startRadius: 40,
                endRadius: 320
            )
        }
        .ignoresSafeArea()
    }
}

struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat
    var tint: Color?
    var content: Content

    init(
        cornerRadius: CGFloat = 22,
        tint: Color? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(glassStyle, in: .rect(cornerRadius: cornerRadius))
    }

    private var glassStyle: Glass {
        if let tint {
            return .regular.tint(tint).interactive()
        }

        return .regular.interactive()
    }
}

extension View {
    func liquidGlassBackground() -> some View {
        background(LiquidGlassBackground())
    }

    func glassCapsule(tint: Color? = nil) -> some View {
        glassEffect(glassStyle(for: tint), in: .capsule)
    }

    func glassRoundedRect(cornerRadius: CGFloat = 18, tint: Color? = nil) -> some View {
        glassEffect(glassStyle(for: tint), in: .rect(cornerRadius: cornerRadius))
    }

    private func glassStyle(for tint: Color?) -> Glass {
        if let tint {
            return .regular.tint(tint).interactive()
        }

        return .regular.interactive()
    }
}
