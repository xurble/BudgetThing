//
//  HomeView.swift
//  xpenz
//
//  Created by Rafael Soh on 20/5/22.
//

import ConfettiSwiftUI
import FabBar
import Foundation
import SwiftData
import SwiftUI
import UIKit

class OverallToastPresenter: ObservableObject {
    @Published var showToast: Bool = false
}

enum DeletionType {
    case instant
    case prompt
}

enum AppTab: Hashable {
    case log
    case insights
    case budget
    case bank
}

class OverallTransactionManager: ObservableObject {
    @Published var toEdit: Transaction?
    @Published var toDelete: Transaction?
    @Published var showToast: Bool = false
    @Published var showPopup: Bool = false
    @Published var future: Bool = false
}

struct HomeView: View {
    @EnvironmentObject var appLockVM: AppLockViewModel

    @StateObject var toastPresenter = OverallToastPresenter()
    @StateObject var transactionManager = OverallTransactionManager()
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var dataController: DataController

    @State private var currentTab: AppTab = .log
    @State private var addTransaction = false
    @State private var transactionCount = 0

    var topEdge: CGFloat
    var bottomEdge: CGFloat

    @State var fromURL1: Bool = false
    @State var fromURL2: Bool = false
    @State var fromURL3: Bool = false
    @State var fromURL4: Bool = false

    @State var launchAdd: Bool = false
    @State var launchSearch: Bool = false

    @State var counter = 0

    @EnvironmentObject var tabBarManager: TabBarManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Query private var transactions: [Transaction]

    @AppStorage("confetti", store: UserDefaults(suiteName: "group.farm.poplar.budgetthing")) var confetti: Bool = false
    @AppStorage("firstTransactionViewLaunch", store: UserDefaults(suiteName: "group.farm.poplar.budgetthing")) var firstLaunch: Bool = true

    init(topEdge: CGFloat, bottomEdge: CGFloat) {
        self.topEdge = topEdge
        self.bottomEdge = bottomEdge
    }

    private var tabBarVisibility: Visibility {
        horizontalSizeClass == .compact || tabBarManager.hideTab ? .hidden : .visible
    }

    private var fabBarTabs: [FabBarTab<AppTab>] {
        [
            FabBarTab(value: .log, title: "Log", image: "Log", imageBundle: .main),
            FabBarTab(value: .insights, title: "Insights", image: "Insights", imageBundle: .main),
            FabBarTab(value: .budget, title: "Budget", image: "Budget", imageBundle: .main),
            FabBarTab(value: .bank, title: "Bank", image: "Bank", imageBundle: .main)
        ]
    }

    private var fabBarAction: FabBarAction {
        FabBarAction(systemImage: "plus", accessibilityLabel: "Add Transaction") {
            presentAddTransaction()
        }
    }

    private var shouldStopRecurring: Bool {
        if let toDelete = transactionManager.toDelete {
            return transactionManager.future && toDelete.wrappedDate < Date.now && toDelete.recurringType > 0
        }

        return false
    }

    private var deleteDialogTitle: String {
        if shouldStopRecurring {
            return "Stop Recurring?"
        }

        let note = transactionManager.toDelete?.wrappedNote ?? ""
        if note.isEmpty {
            return "Delete Transaction?"
        }

        return "Delete '\(note)'?"
    }

    private var deleteDialogMessage: String {
        shouldStopRecurring ? "The transaction will no longer be automatically logged." : "This action cannot be undone."
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            LiquidGlassBackground()
            TabView(selection: $currentTab) {
                NavigationStack {
                    LogView(topEdge: topEdge, bottomEdge: bottomEdge, launchSearch: launchSearch)
                }
                .fabBarSafeAreaPadding()
                .toolbarVisibility(tabBarVisibility, for: .tabBar)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .tag(AppTab.log)
                .tabItem {
                    Label("Log", image: "Log")
                }

                InsightsView()
                    .fabBarSafeAreaPadding()
                    .toolbarVisibility(tabBarVisibility, for: .tabBar)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .tag(AppTab.insights)
                    .tabItem {
                        Label("Insights", image: "Insights")
                    }

                BudgetView()
                    .fabBarSafeAreaPadding()
                    .toolbarVisibility(tabBarVisibility, for: .tabBar)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .tag(AppTab.budget)
                    .tabItem {
                        Label("Budget", image: "Budget")
                    }

                BankView()
                    .fabBarSafeAreaPadding()
                    .toolbarVisibility(tabBarVisibility, for: .tabBar)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .tag(AppTab.bank)
                    .tabItem {
                        Label("Bank", image: "Bank")
                    }
            }
            .fabBar(
                selection: $currentTab,
                tabs: fabBarTabs,
                action: fabBarAction,
                isVisible: !tabBarManager.hideTab
            )
            .environmentObject(toastPresenter)
            .environmentObject(transactionManager)
            .onChange(of: currentTab) { _, newTab in
                if newTab == .bank {
                    dataController.startBffNegotiationIfNeeded()
                }
            }

            if appLockVM.isAppLockEnabled && !appLockVM.isAppUnLocked {
                AppLockView()
                    .ignoresSafeArea(.all)
                    .onOpenURL { url in

                        if url.host == "newExpense" {
                            fromURL1 = true
                        } else if url.host == "search" {
                            fromURL2 = true
                        } else if url.host == "insights" {
                            fromURL3 = true
                        } else if url.host == "budget" {
                            fromURL4 = true
                        }
                    }
            }
        }
        .toast(isPresenting: $toastPresenter.showToast, duration: 4, tapToDismiss: true, offsetY: 12, alert: {
            AlertToast(displayMode: .hud, type: .systemImage("checkmark.circle.fill", Color.IncomeGreen), title: "Image Saved", subTitle: "Check it out in Photos")
        })
        .toast(isPresenting: $transactionManager.showToast, duration: 4, tapToDismiss: true, offsetY: 12, alert: {
            AlertToast(displayMode: .hud, type: .systemImage("arrow.uturn.backward.circle.fill", Color.AlertRed), title: "Log Deleted", subTitle: "Tap to Undo")
        }, onTap: {
            withAnimation(.easeInOut(duration: 0.5)) {
                modelContext.rollback()
            }
            transactionManager.toDelete = nil
        }, completion: {
            dataController.save(context: modelContext)
            transactionManager.toDelete = nil
        })
        .confirmationDialog(
            deleteDialogTitle,
            isPresented: $transactionManager.showPopup,
            titleVisibility: .visible
        ) {
            Button(shouldStopRecurring ? "Stop Recurring" : "Delete", role: .destructive) {
                guard let toDelete = transactionManager.toDelete else {
                    transactionManager.showPopup = false
                    return
                }

                transactionManager.showPopup = false

                if shouldStopRecurring {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        toDelete.recurringType = 0
                        dataController.save(context: modelContext)
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        modelContext.delete(toDelete)
                        transactionManager.showToast = true
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                transactionManager.showPopup = false
            }
        } message: {
            Text(deleteDialogMessage)
        }
        .fullScreenCover(item: $transactionManager.toEdit, onDismiss: {
            transactionManager.toEdit = nil
        }) { transaction in
            TransactionView(toEdit: transaction)
        }
        .fullScreenCover(isPresented: $addTransaction, onDismiss: {
            if confetti, transactionCount != transactions.count {
                counter += 1
            }

            if firstLaunch {
                firstLaunch = false
            }
        }) {
            TransactionView(toEdit: nil)
        }
        .confettiCannon(counter: $counter, num: 50, openingAngle: Angle(degrees: 0), closingAngle: Angle(degrees: 360), radius: 200)
        .onAppear {
            transactionCount = transactions.count

            if appLockVM.isAppLockEnabled && fromURL1 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    launchAdd.toggle()
                }

                fromURL1 = false
            }

            if appLockVM.isAppLockEnabled && fromURL2 {
                currentTab = .log

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    launchSearch.toggle()
                }

                fromURL2 = false
            }

            if appLockVM.isAppLockEnabled && fromURL3 {
                currentTab = .insights
            }

            if appLockVM.isAppLockEnabled && fromURL4 {
                currentTab = .budget
            }
        }
        .onChange(of: launchAdd) { 
            presentAddTransaction()
        }
        .onOpenURL { url in
            if url.host == "newExpense" {
                presentAddTransaction()
            } else if url.host == "search" {
                currentTab = .log
            } else if url.host == "insights" {
                currentTab = .insights
            } else if url.host == "budget" {
                currentTab = .budget
            }
        }
    }

    private func presentAddTransaction() {
        let impactMed = UIImpactFeedbackGenerator(style: .light)
        impactMed.impactOccurred()
        addTransaction = true
    }
}

struct AppLockView: View {
    @EnvironmentObject var appLockVM: AppLockViewModel

    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "lock.fill")
                .font(.system(size: 65))
                .foregroundColor(Color.DarkIcon.opacity(0.7))

            Text("App Locked")
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundColor(Color.PrimaryText)
                .padding(.bottom, 30)

            Button {
                appLockVM.appLockValidation()
            } label: {
                HStack {
                    Image(systemName: "faceid")

                    Text("Unlock App")
                }
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(Color.PrimaryText)
                .padding(.horizontal, 40)
                .padding(.vertical, 15)
                .glassRoundedRect(cornerRadius: 14, tint: Color.SecondaryBackground.opacity(0.4))
            }

            if appLockVM.enrollmentError {
                Text("Please re-enable Face ID access in the Settings app to unlock application.")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(Color.SubtitleText)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .liquidGlassBackground()
    }
}
