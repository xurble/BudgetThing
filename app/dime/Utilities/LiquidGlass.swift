//
//  LiquidGlass.swift
//  BudgetThing
//
//  Created by Gareth Simpson on 3/3/26.
//

import SwiftUI

struct LiquidGlassBackground: View {
    var body: some View {
        ZStack {

            LinearGradient(
                colors: [
                    Color.PrimaryBackground,
                    Color.SecondaryBackground,
                    Color.PrimaryBackground
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    Color.SecondaryBackground,
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

struct ToastStyle {
    static let cornerRadius: CGFloat = 9
    static let tintOpacity: Double = 0.2
}

struct ToastAnimationStyle {
    static let insertionScale: CGFloat = 0.6
    static let insertionOffset: CGFloat = 18
    static let removalOffset: CGFloat = 150
    static let springResponse: Double = 0.5
    static let springDampingFraction: Double = 0.6
    static let springBlendDuration: Double = 0.1

    static var transition: AnyTransition {
        .asymmetric(
            insertion: .offset(y: -insertionOffset)
                .combined(with: .scale(scale: insertionScale, anchor: .top))
                .combined(with: .opacity),
            removal: .offset(y: -removalOffset)
        )
    }

    static var animation: Animation {
        .spring(
            response: springResponse,
            dampingFraction: springDampingFraction,
            blendDuration: springBlendDuration
        )
    }
}

extension View {
    func liquidGlassBackground() -> some View {
        background(LiquidGlassBackground())
    }

    func liquidGlassBackground(opacity: Double) -> some View {
        background(LiquidGlassBackground().opacity(opacity))
    }

    func glassCapsule(tint: Color? = nil) -> some View {
        glassEffect(glassStyle(for: tint), in: .capsule)
    }

    func glassRoundedRect(cornerRadius: CGFloat = 18, tint: Color? = nil) -> some View {
        glassEffect(glassStyle(for: tint), in: .rect(cornerRadius: cornerRadius))
    }

    func toastGlassRoundedRect(tint: Color) -> some View {
        background(
            RoundedRectangle(cornerRadius: ToastStyle.cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ToastStyle.cornerRadius, style: .continuous)
                .fill(tint.opacity(ToastStyle.tintOpacity))
        )
        .compositingGroup()
    }

    private func glassStyle(for tint: Color?) -> Glass {
        if let tint {
            return .regular.tint(tint).interactive()
        }

        return .regular.interactive()
    }
}
