//
//  Derived from CustomTabBar.swift
//  xpenz
//
//  Created by Rafael Soh on 20/5/22.
//

import Foundation
import SwiftUI

struct MyButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(Color.LightIcon)
            .frame(width: 65, height: 38)
            .background(configuration.isPressed ? Color.SubtitleText : Color.DarkBackground, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
    }
}

struct BouncyButton: ButtonStyle {
    var duration: Double
    var scale: Double

    public func makeBody(configuration: Self.Configuration) -> some View {
        return configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
//            .scaleEffect(configuration.isPressed ? 1.3 : 1)
            .animation(.easeOut(duration: duration), value: configuration.isPressed)
    }
}

struct TabButton: View {
    var image: String
    @Binding var currentTab: String
    var glassNamespace: Namespace.ID

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.35)) {
                currentTab = image
            }
        } label: {
            ZStack {
                if currentTab == image {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.clear)
                        .frame(height: 36)
                        .glassEffect(
                            .regular.tint(Color.SecondaryBackground.opacity(0.5)).interactive(),
                            in: .rect(cornerRadius: 14)
                        )
                        .glassEffectID("tab-selection", in: glassNamespace)
                        .glassEffectTransition(.matchedGeometry)
                }

                Image(image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 28, maxHeight: 28)
                    .animation(.easeInOut(duration: 0.3), value: currentTab)
                    .frame(maxWidth: .infinity)
                    .foregroundColor(currentTab == image ? Color.DarkIcon : Color.GreyIcon)
            }
        }
        .buttonStyle(BouncyButton(duration: 0.3, scale: 0.6))
        .accessibilityLabel("\(image) tab")
        .accessibilityAddTraits(
            currentTab == image
                ? [.isButton, .isSelected]
                : .isButton
        )
    }
}
