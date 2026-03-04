//
//  CustomTabBar.swift
//  xpenz
//
//  Created by Rafael Soh on 20/5/22.
//

import Foundation
import SwiftUI

struct CustomTabBar: View {
    @EnvironmentObject var appLockVM: AppLockViewModel
    @Binding var currentTab: String
    var topEdge: CGFloat
    var bottomEdge: CGFloat
    @State var addTransaction: Bool = false

    @State var checkingFace: Bool = false

    @FetchRequest(sortDescriptors: []) private var transactions: FetchedResults<Transaction>

    @State var count = 0
    @Binding var counter: Int

    var launchAdd: Bool

    @AppStorage("confetti", store: UserDefaults(suiteName: "group.farm.poplar.budgetthing")) var confetti: Bool = false
    @AppStorage("firstTransactionViewLaunch", store: UserDefaults(suiteName: "group.farm.poplar.budgetthing")) var firstLaunch: Bool = true

    @State var animate = false

    var body: some View {
        GlassEffectContainer(spacing: 16) {
            HStack(spacing: 4) {
                TabButton(image: "Log", currentTab: $currentTab)

                TabButton(image: "Insights", currentTab: $currentTab)

                ZStack {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.SecondaryBackground.opacity(0.3))
                        .frame(width: 86, height: 56)
                        .opacity(self.animate ? 0 : 1)
                        .scaleEffect(self.animate ? 1 : 0.5)

                    Button {
                        let impactMed = UIImpactFeedbackGenerator(style: .light)
                        impactMed.impactOccurred()

                        addTransaction = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color.PrimaryText)
                            .frame(width: 58, height: 40)
                            .glassRoundedRect(cornerRadius: 16, tint: Color.SecondaryBackground.opacity(0.45))
                    }
                    .buttonStyle(.plain)
                }
                .onAppear {
                    if transactions.isEmpty {
                        withAnimation(.easeInOut(duration: 1.9).repeatForever(autoreverses: false)) {
                            self.animate.toggle()
                        }
                    }
                }
                .accessibilityLabel("Add New Transaction")

                TabButton(image: "Budget", currentTab: $currentTab)

                TabButton(image: "Settings", currentTab: $currentTab)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .glassRoundedRect(cornerRadius: 26, tint: Color.SecondaryBackground.opacity(0.35))
        }
        .padding(.horizontal, 12)
        .padding(.bottom, max(8, bottomEdge - 8))
        .fullScreenCover(isPresented: $addTransaction, onDismiss: {
            if confetti {
                if count != transactions.count {
                    counter += 1
                }
            }

            if firstLaunch {
                firstLaunch = false
            }

        }, content: {
            TransactionView(toEdit: nil)
        })
        .onChange(of: launchAdd) { _, _ in
            addTransaction = true
        }
        .onChange(of: addTransaction) { _, _ in
            if addTransaction {
                count = transactions.count
            }
        }
        .onChange(of: transactions.count) { _, _ in
            if !transactions.isEmpty {
                self.animate = false
            } else {
                self.animate = true
            }
        }
        .onOpenURL { url in
            guard
                url.host == "newExpense"

            else {
                return
            }

            addTransaction = true
        }
    }
}

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

    var body: some View {
        Button {
            DispatchQueue.main.async {
                currentTab = image
            }
        } label: {
            Image(image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 28, maxHeight: 28)
                .animation(.easeInOut(duration: 0.3), value: currentTab)
                .frame(maxWidth: .infinity)
                .foregroundColor(currentTab == image ? Color.DarkIcon : Color.GreyIcon)
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
