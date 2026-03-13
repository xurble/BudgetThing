//
//  ContentView.swift
//
//  Created by Rafael Soh on 3/6/22.
//

import SwiftUI
import WidgetKit

struct ContentView: View {
    @EnvironmentObject var appLockVM: AppLockViewModel
    @EnvironmentObject var dataController: DataController

    @AppStorage("colourScheme", store: UserDefaults(suiteName: "group.farm.poplar.budgetthing")) var colourScheme: Int = 0
    @Environment(\.scenePhase) var scenePhase
    @AppStorage("showNotifications", store: UserDefaults(suiteName: "group.farm.poplar.budgetthing")) var showNotifications: Bool = false
    @AppStorage("notificationsEnabled", store: UserDefaults(suiteName: "group.farm.poplar.budgetthing")) var notificationsEnabled: Bool = true

    @AppStorage("firstLaunch", store: UserDefaults(suiteName: "group.farm.poplar.budgetthing")) var firstLaunch: Bool = true

    @AppStorage("currency", store: UserDefaults(suiteName: "group.farm.poplar.budgetthing")) var currency: String = Locale.current.currency?.identifier ?? "USD"

    @State var showIntro: Bool = false
    @State var showUpdate: Bool = false

    @AppStorage("topEdge", store: UserDefaults(suiteName: "group.farm.poplar.budgetthing")) var savedTopEdge: Double = 30
    @AppStorage("bottomEdge", store: UserDefaults(suiteName: "group.farm.poplar.budgetthing")) var savedBottomEdge: Double = 15

    // updateSheetShowing

    @AppStorage("previousVersion", store: UserDefaults(suiteName: "group.farm.poplar.budgetthing")) var previousVersionString: String = "Version \(UIApplication.appVersion ?? "") (\(UIApplication.buildNumber ?? ""))"

    @AppStorage("showUpdateSheet", store: UserDefaults(suiteName: "group.farm.poplar.budgetthing")) var showUpdateSheet: Bool = true

    var body: some View {
        GeometryReader { proxy in
            let topEdge = proxy.safeAreaInsets.top
            let bottomEdge = proxy.safeAreaInsets.bottom

            HomeView(topEdge: topEdge, bottomEdge: bottomEdge == 0 ? 15 : bottomEdge)
                .ignoresSafeArea(.all, edges: .bottom)
                .preferredColorScheme(colourScheme == 1 ? .light : colourScheme == 2 ? .dark : nil)
                .fullScreenCover(isPresented: $showIntro) {
                    WelcomeSheetView()
                }
                .fullScreenCover(isPresented: $showUpdate) {
                    UpdateAlert()
                }
                .onAppear {
                    savedTopEdge = topEdge
                    savedBottomEdge = bottomEdge
                }
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
//            UserDefaults(suiteName: "group.farm.poplar.budgetthing")!.set(false, forKey: "newTransactionAdded")
//            WidgetCenter.shared.reloadTimelines(ofKind: "TemplateTransactions")

            if appLockVM.isAppLockEnabled {
                appLockVM.appLockValidation()
            }

            let defaults =
                UserDefaults(suiteName: "group.farm.poplar.budgetthing") ?? UserDefaults.standard

            if defaults.object(forKey: "firstDayOfMonth") == nil {
                defaults.set(1, forKey: "firstDayOfMonth")
            }

            if firstLaunch {
                showIntro = true
                firstLaunch = false
                showUpdateSheet = false

                defaults.set(1, forKey: "firstWeekday")
                defaults.set(1, forKey: "haptics")
                defaults.set(1, forKey: "firstDayOfMonth")
                defaults.set(1, forKey: "notificationOption")
                defaults.set(false, forKey: "confetti")
                defaults.set(false, forKey: "chromatic")
                defaults.set(true, forKey: "showCents")
                defaults.set(true, forKey: "animated")

                if NSUbiquitousKeyValueStore.default.string(forKey: "currency") == nil {
                    NSUbiquitousKeyValueStore.default.set(Locale.current.currency?.identifier ?? "USD", forKey: "currency")
                } else {
                    currency = NSUbiquitousKeyValueStore.default.string(forKey: "currency")!
                }

                defaults.set(2, forKey: "numberEntryType")
            } else {
                if let holdingCurrency = NSUbiquitousKeyValueStore.default.string(forKey: "currency") {
                    currency = holdingCurrency
                } else {
                    currency = Locale.current.currency?.identifier ?? "USD"
                    NSUbiquitousKeyValueStore.default.set(Locale.current.currency?.identifier ?? "USD", forKey: "currency")
                }
            }

            if showUpdateSheet {
                showUpdate = true
                showUpdateSheet = false
            }

            UNUserNotificationCenter.current().getNotificationSettings { settings in
                let authorizationStatus = settings.authorizationStatus
                Task { @MainActor in
                    handleNotificationSettings(authorizationStatus)
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background || newPhase == .inactive {
                if appLockVM.isAppLockEnabled {
                    appLockVM.isAppUnLocked = false
                }
            } else if newPhase == .active {
                UNUserNotificationCenter.current().getNotificationSettings { settings in
                    let authorizationStatus = settings.authorizationStatus
                    Task { @MainActor in
                        handleNotificationSettings(authorizationStatus)
                    }
                }
            }
        }
    }

    @MainActor
    private func handleNotificationSettings(_ authorizationStatus: UNAuthorizationStatus) {
        let center = UNUserNotificationCenter.current()

        if authorizationStatus == .authorized {
            if !showNotifications && notificationsEnabled == false {
                showNotifications = true
                notificationsEnabled = true
                newNotification()
            }
        } else if authorizationStatus == .denied {
            notificationsEnabled = false

            if showNotifications {
                showNotifications = false
                center.removeAllPendingNotificationRequests()
            }
        }
    }
}
