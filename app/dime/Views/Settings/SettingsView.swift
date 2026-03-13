//
//  SettingsView.swift
//  xpenz
//
//  Created by Rafael Soh on 20/5/22.
//

import Combine
import ConfettiSwiftUI
import Foundation
import StoreKit
import SwiftUI
import UIKit
import UserNotifications
import WidgetKit

struct SettingsView: View {
  @Environment(\.dynamicTypeSize) var dynamicTypeSize
  @Environment(\.dismiss) var dismiss
  @Environment(\.presentationMode) var presentationMode

  @AppStorage("colourScheme", store: UserDefaults(suiteName: "group.farm.poplar.budgetthing"))
  var colourScheme: Int = 0
  var colourSchemeString: String {
    if colourScheme == 1 {
      return String(localized: "Light")
    } else if colourScheme == 2 {
      return String(localized: "Dark")
    } else {
      return String(localized: "System")
    }
  }

  @AppStorage("activeIcon", store: UserDefaults(suiteName: "group.farm.poplar.budgetthing"))
  var activeIcon: String = "AppIcon"
  var appIconString: String {
    if activeIcon == "AppIcon1" {
      return "v2.0"
    } else if activeIcon == "AppIcon2" {
      return "Unicorn"
    } else if activeIcon == "AppIcon3" {
      return "v1.5"
    } else {
      return "O.G."
    }
  }

  @AppStorage("firstWeekday", store: UserDefaults(suiteName: "group.farm.poplar.budgetthing"))
  var firstWeekday: Int = 1
  var firstWeekdayString: String {
    if firstWeekday == 1 {
      return String(localized: "Sunday")
    } else {
      return String(localized: "Monday")
    }
  }

  @AppStorage("showNotifications", store: UserDefaults(suiteName: "group.farm.poplar.budgetthing"))
  var showNotifications: Bool = false
  @AppStorage("notificationOption", store: UserDefaults(suiteName: "group.farm.poplar.budgetthing"))
  var option: Int = 1
  var notificationString: String {
    if showNotifications {
      if option == 1 {
        return String(localized: "Mornings")
      } else if option == 2 {
        return String(localized: "Evenings")
      } else {
        return String(localized: "Custom")
      }
    } else {
      return String(localized: "Off")
    }
  }

  @EnvironmentObject var appLockVM: AppLockViewModel
  @Namespace var animation

  var iCloudString: String {
    if NSUbiquitousKeyValueStore.default.bool(forKey: "icloud_sync") {
      return String(localized: "On")
    } else {
      return String(localized: "Off")
    }
  }

  @Environment(\.openURL) var openURL
  let supportEmail = SupportEmail(toAddress: "rafasohhh@gmail.com", subject: "Support Email")
  let featureRequestEmail = SupportEmail(
    toAddress: "rafasohhh@gmail.com", subject: "Feature Request")

  @AppStorage("numberEntryType", store: UserDefaults(suiteName: "group.farm.poplar.budgetthing"))
  var numberEntryType: Int = 2

  var numberEntryString: String {
    if numberEntryType == 1 {
      return String(localized: "Type 1")
    } else {
      return String(localized: "Type 2")
    }
  }

  @AppStorage("showCents", store: UserDefaults(suiteName: "group.farm.poplar.budgetthing"))
  var showCents: Bool = true

  @AppStorage("animated", store: UserDefaults(suiteName: "group.farm.poplar.budgetthing")) var animated:
    Bool = true

  @AppStorage("currency", store: UserDefaults(suiteName: "group.farm.poplar.budgetthing")) var currency:
    String = Locale.current.currency?.identifier ?? "USD"

  @AppStorage("incomeTracking", store: UserDefaults(suiteName: "group.farm.poplar.budgetthing"))
  var incomeTracking: Bool = true
    
  @AppStorage("showExpenseOrIncomeSign", store: UserDefaults(suiteName: "group.farm.poplar.budgetthing"))
  var showExpenseOrIncomeSign: Bool = true

  @AppStorage(
    "showUpcomingTransactions", store: UserDefaults(suiteName: "group.farm.poplar.budgetthing"))
  var showUpcoming: Bool = true

  var upcomingString: String {
    if showUpcoming {
      return String(localized: "Shown")
    } else {
      return String(localized: "Hidden")
    }
  }

    @AppStorage("haptics", store: UserDefaults(suiteName: "group.farm.poplar.budgetthing"))
    var hapticType: Int = 1

    var hapticString: String {
      if hapticType == 0 {
        return String(localized: "None")
      } else if hapticType == 1 {
        return String(localized: "Subtle")
      } else {
        return String(localized: "Excessive")
      }
    }

  // popups

  @State var showTipJarMenu = false
  @State var showImportGuide = false
  @State var showUpdate: Bool = false

  @EnvironmentObject var tabBarManager: TabBarManager

  @EnvironmentObject var dataController: DataController

  var body: some View {
    NavigationView {
      List {
        generalSection

        appearanceSection

        dataSection

        otherSection

        aboutSection
      }
      .listStyle(.insetGrouped)
      .background(NavigationBarConfigurator())
      .scrollContentBackground(.hidden)
      .background(Color(.systemGroupedBackground))
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            DispatchQueue.main.async {
              dismiss()
              presentationMode.wrappedValue.dismiss()
            }
          } label: {
            Image(systemName: "xmark")
              .font(.system(.subheadline, design: .rounded).weight(.semibold))
              .foregroundColor(Color.SubtitleText)
              .padding(8)
          }
          .accessibilityLabel("Close")
        }
      }
      .onChange(of: currency) { 
        WidgetCenter.shared.reloadAllTimelines()
      }
      .onChange(of: firstWeekday) { 
        WidgetCenter.shared.reloadAllTimelines()
      }
      .onChange(of: showCents) { 
        WidgetCenter.shared.reloadAllTimelines()
      }
      .fullScreenCover(isPresented: $showTipJarMenu) {
        TipJarAlert()
      }
      .fullScreenCover(isPresented: $showUpdate) {
        UpdateAlert()
      }
      .fullScreenCover(isPresented: $showImportGuide) {
        ImportDataView()
      }
    }
  }


  @ViewBuilder
  private var generalSection: some View {
    Section(header: settingsSectionHeader("General")) {
      NavigationLink(destination: SettingsNotificationsView()) {
        settingsRow(title: "Notifications", systemImage: "bell", color: "102", detail: notificationString)
      }
      .listRowBackground(Color(.secondarySystemGroupedBackground))

      NavigationLink(destination: SettingsCurrencyView()) {
        settingsRow(title: "Currency", systemImage: "coloncurrencysign.square", color: "103", detail: currency)
      }
      .listRowBackground(Color(.secondarySystemGroupedBackground))

      NavigationLink(
        destination: SettingsNumberEntryView()
          .onAppear {
            withAnimation(.easeOut.speed(1.5)) {
              tabBarManager.navigationHideTab()
            }
          }
          .onDisappear {
            withAnimation(.easeOut.speed(1.5)) {
              tabBarManager.navigationShowTab()
            }
          }
      ) {
        settingsRow(title: "Number Entry", systemImage: "keyboard", color: "104", detail: numberEntryString)
      }
      .listRowBackground(Color(.secondarySystemGroupedBackground))

      Toggle(
        isOn: Binding(
          get: { appLockVM.isAppLockEnabled },
          set: { appLockVM.appLockStateChange(appLockState: $0) }
        )
      ) {
        HStack(spacing: 12) {
          settingsIcon("faceid", color: "105")
          Text("Authentication")
        }
      }
      .listRowBackground(Color(.secondarySystemGroupedBackground))

      Toggle(
        isOn: Binding(
          get: { incomeTracking },
          set: { newValue in
            incomeTracking = newValue
            if !newValue {
              UserDefaults(suiteName: "group.farm.poplar.budgetthing")!.set(
                false, forKey: "insightsViewIncomeFiltering")
              UserDefaults(suiteName: "group.farm.poplar.budgetthing")!.set(
                3, forKey: "logInsightsType")
            }
          }
        )
      ) {
        HStack(spacing: 12) {
          settingsIcon("banknote", color: "106")
          Text("Income Tracking")
        }
      }
      .listRowBackground(Color(.secondarySystemGroupedBackground))

      NavigationLink(destination: SettingsWeekStartView()) {
        settingsRow(title: "Time Frames", systemImage: "calendar", color: "109")
      }
      .listRowBackground(Color(.secondarySystemGroupedBackground))
    }
  }

  @ViewBuilder
  private var appearanceSection: some View {
    Section(header: settingsSectionHeader("Appearance")) {
      NavigationLink(destination: SettingsAppearanceView()) {
        settingsRow(title: "Theme", systemImage: "circle.righthalf.filled", color: "100", detail: colourSchemeString)
      }
      .listRowBackground(Color(.secondarySystemGroupedBackground))

      NavigationLink(destination: SettingsAppIconView()) {
        settingsRow(title: "App Icon", systemImage: "app.badge", color: "101", detail: appIconString)
      }
      .listRowBackground(Color(.secondarySystemGroupedBackground))

      Toggle(isOn: $showCents) {
        HStack(spacing: 12) {
          settingsIcon("centsign.circle", color: "107")
          Text("Display Cents")
        }
      }
      .listRowBackground(Color(.secondarySystemGroupedBackground))

      NavigationLink(destination: SettingsUpcomingView()) {
        settingsRow(title: "Upcoming Logs", systemImage: "sun.min", color: "108", detail: upcomingString)
      }
      .listRowBackground(Color(.secondarySystemGroupedBackground))

      Toggle(isOn: $showExpenseOrIncomeSign) {
        HStack(spacing: 12) {
          settingsIcon("plusminus", color: "123")
          Text("Display +/- Symbol")
        }
      }
      .listRowBackground(Color(.secondarySystemGroupedBackground))

      Toggle(isOn: $animated) {
        HStack(spacing: 12) {
          settingsIcon("hare", color: "121")
          Text("Animated Charts")
        }
      }
      .listRowBackground(Color(.secondarySystemGroupedBackground))
    }
  }

  @ViewBuilder
  private var dataSection: some View {
    Section(header: settingsSectionHeader("Data")) {
      NavigationLink(
        destination: SettingsCategoryView()
          .onAppear {
            withAnimation(.easeOut.speed(1.5)) {
              tabBarManager.navigationHideTab()
            }
          }
          .onDisappear {
            withAnimation(.easeOut.speed(1.5)) {
              tabBarManager.navigationShowTab()
            }
          }
      ) {
        settingsRow(title: "Categories", systemImage: "rectangle.grid.2x2", color: "110")
      }
      .listRowBackground(Color(.secondarySystemGroupedBackground))

      NavigationLink(destination: SettingsCloudView()) {
        settingsRow(title: "iCloud Sync", systemImage: "icloud", color: "111", detail: iCloudString)
      }
      .listRowBackground(Color(.secondarySystemGroupedBackground))

      Button {
        showImportGuide = true
      } label: {
        settingsRow(title: "Import Data", systemImage: "square.and.arrow.down", color: "112")
      }
      .listRowBackground(Color(.secondarySystemGroupedBackground))

      ShareLink(item: exportCSVFileURL()) {
        settingsRow(title: "Export Data", systemImage: "square.and.arrow.up", color: "113")
      }
      .listRowBackground(Color(.secondarySystemGroupedBackground))

      NavigationLink(destination: SettingsEraseView()) {
        settingsRow(title: "Erase Data", systemImage: "xmark.bin", color: "114")
      }
      .listRowBackground(Color(.secondarySystemGroupedBackground))
    }
  }

  @ViewBuilder
  private var otherSection: some View {
    Section(header: settingsSectionHeader("Other")) {
      NavigationLink(destination: SettingsHapticsView()) {
        settingsRow(title: "Haptics", systemImage: "hand.tap", color: "100", detail: hapticString)
      }
      .listRowBackground(Color(.secondarySystemGroupedBackground))

      NavigationLink(destination: SettingsGoofyView()) {
        settingsRow(title: "Feature Lab", systemImage: "flame", color: "122")
      }
      .listRowBackground(Color(.secondarySystemGroupedBackground))

      Button {
        showTipJarMenu = true
      } label: {
        settingsRow(title: "Tip Jar", systemImage: "heart", color: "123")
      }
      .listRowBackground(Color(.secondarySystemGroupedBackground))

      Button {
        supportEmail.send(openURL: openURL)
      } label: {
        settingsRow(title: "Report Bug", systemImage: "ladybug", color: "124")
      }
      .listRowBackground(Color(.secondarySystemGroupedBackground))

      Button {
        featureRequestEmail.send(openURL: openURL)
      } label: {
        settingsRow(title: "Feature Request", systemImage: "hand.wave", color: "125")
      }
      .listRowBackground(Color(.secondarySystemGroupedBackground))

      Button {
        let url = "https://apps.apple.com/app/id1635280255?action=write-review"
        guard let writeReviewURL = URL(string: url)
        else { fatalError("Expected a valid URL") }
        UIApplication.shared.open(writeReviewURL, options: [:], completionHandler: nil)
      } label: {
        settingsRow(title: "Rate on App Store", systemImage: "star", color: "126")
      }
      .listRowBackground(Color(.secondarySystemGroupedBackground))

      ShareLink(item: URL(string: "https://apps.apple.com/app/id1635280255")!) {
        settingsRow(title: "Share with Friends", systemImage: "square.and.arrow.up", color: "127")
      }
      .listRowBackground(Color(.secondarySystemGroupedBackground))

      Button {
        if let url = URL(string: "https://www.x.com/budgetwithdime") {
          UIApplication.shared.open(url)
        }
      } label: {
        settingsRow(title: "Follow Dime on X", systemImage: "bird", color: "128")
      }
      .listRowBackground(Color(.secondarySystemGroupedBackground))

      Button {
        if let url = URL(string: "https://www.x.com/rarfell") {
          UIApplication.shared.open(url)
        }
      } label: {
        settingsRow(title: "Follow Rafael on X", systemImage: "camera", color: "129")
      }
      .listRowBackground(Color(.secondarySystemGroupedBackground))
    }
  }

  @ViewBuilder
  private var aboutSection: some View {
    Section {
      VStack(spacing: 6) {
        HStack(spacing: 6) {
          Text("Version \(UIApplication.appVersion ?? "") (\(UIApplication.buildNumber ?? ""))")
            .foregroundColor(.secondary)
          Text("·")
            .foregroundColor(.secondary)
          Text("What's New")
            .foregroundColor(.primary)
            .onTapGesture {
              showUpdate = true
            }
        }

        Text("Made with ❤️ by \(makeAttributedString()) from 🇸🇬")
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
      }
      .frame(maxWidth: .infinity)
    }
    .listRowBackground(Color(.secondarySystemGroupedBackground))
  }

  private struct NavigationBarConfigurator: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
      UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
      guard let navBar = uiViewController.navigationController?.navigationBar else { return }

      let largeSize = UIFont.preferredFont(forTextStyle: .largeTitle).pointSize
      let titleSize = UIFont.preferredFont(forTextStyle: .headline).pointSize
      let largeFont = UIFont.rounded(ofSize: largeSize, weight: .bold)
      let titleFont = UIFont.rounded(ofSize: titleSize, weight: .semibold)

      let appearance = UINavigationBarAppearance()
      appearance.configureWithDefaultBackground()
      appearance.largeTitleTextAttributes = [
        .font: largeFont
      ]
      appearance.titleTextAttributes = [
        .font: titleFont
      ]

      navBar.prefersLargeTitles = true
      navBar.standardAppearance = appearance
      navBar.scrollEdgeAppearance = appearance
      navBar.compactAppearance = appearance
    }
  }

  private func settingsSectionHeader(_ title: String) -> some View {
    Text(title.uppercased())
      .font(.system(.footnote, design: .rounded).weight(.semibold))
      .foregroundColor(.secondary)
  }

  @ViewBuilder
  private func settingsRow(title: String, systemImage: String, color: String, detail: String? = nil) -> some View {
    HStack(spacing: 12) {
      settingsIcon(systemImage, color: color)

      Text(title)

      Spacer()

      if let detail {
        Text(detail)
          .foregroundColor(.secondary)
      }
    }
  }

  private func settingsIcon(_ systemImage: String, color: String) -> some View {
    Image(systemName: systemImage)
      .font(.system(.body, design: .rounded))
      .foregroundColor(.white)
      .frame(width: 28, height: 28)
      .background(Color(color), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
  }

  @ViewBuilder
    func ToggleRow(icon: String, color: String, text: String, bool: Bool, smaller: Bool = false, onTap: @escaping () -> Void)
    -> some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
            .font(.system(smaller ? .subheadline : .body, design: .rounded))
        .foregroundColor(.white)
        .frame(
          width: dynamicTypeSize > .xLarge ? 40 : 30, height: dynamicTypeSize > .xLarge ? 40 : 30,
          alignment: .center
        )
        .background(Color(color), in: RoundedRectangle(cornerRadius: 6))

      Text(text)
        .font(.system(.body, design: .rounded).weight(.medium))
        .lineLimit(1)
        .foregroundColor(Color.PrimaryText)

      Spacer()

      ZStack(alignment: bool ? .trailing : .leading) {
        Capsule()
          .frame(width: 42, height: 28)
          .foregroundColor(bool ? .green : .gray.opacity(0.8))

        Circle()
          .foregroundColor(Color.white)
          .padding(2)
          .frame(width: 28, height: 28)
          .matchedGeometryEffect(id: "toggle\(color)", in: animation)
      }
      .onTapGesture {
        withAnimation {
          onTap()
        }
      }
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 8)
    .glassRoundedRect(cornerRadius: 16, tint: Color.SecondaryBackground.opacity(0.35))
    .frame(maxWidth: .infinity)
  }

  func makeAttributedString() -> AttributedString {
    var string = AttributedString("Rafael")
    string.foregroundColor = Color.PrimaryText
    string.link = URL(string: "https://www.x.com/rarfell")

    return string
  }

  func shareSheet(url: String) {
    let url = URL(string: url)
    let activityView = UIActivityViewController(activityItems: [url!], applicationActivities: nil)

    let allScenes = UIApplication.shared.connectedScenes
    let scene = allScenes.first { $0.activationState == .foregroundActive }

    if let windowScene = scene as? UIWindowScene {
      windowScene.keyWindow?.rootViewController?.present(
        activityView, animated: true, completion: nil)
    }
  }

  func exportCSVText() -> String {
    let descriptor = dataController.fetchDescriptorForExport()
    let transactions = dataController.results(for: descriptor)

    var csvText = "Date,Note,Amount,Category,Type\n"

    for transaction in transactions {
      var string = transaction.wrappedNote
      let type: String

      if transaction.income {
        type = "Income"
      } else {
        type = "Expense"
      }

      string.removeAll(where: { $0 == "," })

      csvText +=
        "\(transaction.wrappedDate),\(string),\(String(format: "%.2f", transaction.wrappedAmount)),\(transaction.category?.wrappedName ?? ""),\(type)\n"
    }

    return csvText
  }

  func exportCSVFileURL() -> URL {
    let csvText = exportCSVText()
    let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("export.csv")

    do {
      try csvText.write(to: fileURL, atomically: true, encoding: .utf8)
    } catch {
      print("\(error)")
    }

    return fileURL
  }
}


struct TipJarAlert: View {
  @Environment(\.dismiss) var dismiss
  @Environment(\.colorScheme) var systemColorScheme
  @EnvironmentObject var unlockManager: UnlockManager

  @State private var offset: CGFloat = 0

  @AppStorage("bottomEdge", store: UserDefaults(suiteName: "group.farm.poplar.budgetthing"))
  var bottomEdge: Double = 15

  @State var opacity = 0.0
  @State var counter = 0

  var bottomCaption: String {
    if unlockManager.failedTransaction {
      return "Tip failed to go through, please try again!"
    } else if unlockManager.purchaseCount > 0 {
      return "Thanks a million, \(Image(systemName: "heart.fill")) Rafael"
    } else {
      return "Have a great day ahead!"
    }
  }

  //    var sortedProducts: [SKProduct] {
  //        let holding = unlockManager.loadedProducts.sorted {
  //            $0.price.doubleValue > $1.price.doubleValue
  //        }
  //
  //        return holding
  //    }

  var body: some View {
    ZStack(alignment: .bottom) {
      Color.PrimaryBackground.opacity(opacity)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
          withAnimation(.easeIn(duration: 0.15)) {
            opacity = 0
            offset += 300
          }
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            dismiss()
          }
        }
        .onAppear {
          DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation {
              opacity = 0.4
            }
          }
        }

      VStack {
        switch unlockManager.requestState {
        case .loading:
          ProgressView {
            Text("Loading")
              .font(.system(.body, design: .rounded).weight(.medium))
              //                            .font(.system(size: 18, weight: .medium, design: .rounded))
              .foregroundColor(Color.SubtitleText)
              .frame(maxWidth: .infinity)
              .frame(height: 200)
          }
        case .failed:
          VStack(spacing: 14) {
            Text("Unable to load tip options, please try again later 🥲")
              .font(.system(.body, design: .rounded).weight(.medium))
              .multilineTextAlignment(.center)
              .foregroundColor(Color.SubtitleText)
              .frame(maxWidth: .infinity)

            Button {
              unlockManager.reloadProducts()
            } label: {
              Text("Try Again")
                .font(.system(.body, design: .rounded).weight(.semibold))
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(
                  RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.SecondaryBackground)
                )
            }
            .foregroundColor(.PrimaryText)
          }
          .frame(maxWidth: .infinity)
          .frame(height: 200)
        default:
          VStack(alignment: .leading, spacing: 4) {
            HStack {
              Image(systemName: "heart.fill")
                .font(.system(.callout, design: .rounded))

              //                                .font(.system(size: 16))
              Text("Tip Jar")
                .font(.system(.title2, design: .rounded).weight(.medium))

              //                                .font(.system(size: 22, weight: .medium, design: .rounded))
            }
            .foregroundColor(.PrimaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(alignment: .trailing) {
              Button {
                withAnimation(.easeIn(duration: 0.15)) {
                  opacity = 0
                  offset += 300
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                  dismiss()
                }
              } label: {
                Image(systemName: "xmark")
                  .font(.system(.subheadline, design: .rounded).weight(.semibold))

                  //                                    .font(.system(size: 14, weight: .semibold))
                  .foregroundColor(Color.SubtitleText)
                  .padding(7)
                  .background(Color.SecondaryBackground, in: Circle())
                  .contentShape(Circle())
              }
              .offset(x: 5, y: -5)
            }

            Text(
              "Hey! Dime was built by a solo student developer, and is intended to be completely free-of-charge, with no paywalls or ads. If you enjoy using Dime and want to support development, please consider a small tip."
            )
            .font(.system(.callout, design: .rounded).weight(.medium))

            //                            .font(.system(size: 16, weight: .medium, design: .rounded))
            .foregroundColor(.SubtitleText)
            .padding(.bottom, 20)

            ProductView(
              products: unlockManager.loadedProducts.sorted {
                $0.price < $1.price
              }
            )
            .padding(.bottom, 20)

            Text(bottomCaption)
              .font(.system(.subheadline, design: .rounded).weight(.medium))

              //                                .font(.system(size: 14, weight: .medium, design: .rounded))
              .frame(maxWidth: .infinity)
              .foregroundColor(.SubtitleText)
          }
        }
      }
      .padding(18)
      .animation(.easeInOut, value: unlockManager.failedTransaction)
      .background(
        RoundedRectangle(cornerRadius: 13).fill(Color.PrimaryBackground).shadow(
          color: systemColorScheme == .dark ? Color.clear : Color.gray.opacity(0.25), radius: 6)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 13).stroke(
          systemColorScheme == .dark ? Color.gray.opacity(0.1) : Color.clear, lineWidth: 1.3)
      )
      .offset(y: offset)
      .confettiCannon(
        counter: $counter, num: 50, openingAngle: Angle(degrees: 0),
        closingAngle: Angle(degrees: 360), radius: 200
      )
      .gesture(
        DragGesture()
          .onChanged { gesture in
            if gesture.translation.height < 0 {
              offset = gesture.translation.height / 3
            } else {
              offset = gesture.translation.height
            }
          }
          .onEnded { value in
            if value.translation.height > 30 {
              withAnimation(.easeIn(duration: 0.15)) {
                opacity = 0
                offset += 300
              }
              DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                dismiss()
              }

            } else {
              withAnimation {
                offset = 0
              }
            }
          }
      )
      .padding(.horizontal, 17)
      .padding(.bottom, bottomEdge == 0 ? 13 : bottomEdge)
      .onChange(of: unlockManager.purchaseCount) { 
        counter += 1
      }
    }
    .edgesIgnoringSafeArea(.all)
    .background(BackgroundBlurView())
    .onAppear {
      if unlockManager.requestState == .failed {
        unlockManager.reloadProducts()
      }
    }
  }
}

struct ProductView: View {
  @EnvironmentObject var unlockManager: UnlockManager
  let products: [Product]

  var body: some View {
    VStack {
      ForEach(products, id: \.id) { product in
        HStack {
          Text(getText(product.id))

          Spacer()

          Button {
            unlock(product)
          } label: {
            Text(product.displayPrice)
              .monospacedDigit()
              .padding(6)
              .background(
                Color.SecondaryBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous)
              )
          }
        }
      }
    }
    .foregroundColor(.PrimaryText)
    .font(.system(.body, design: .rounded).weight(.semibold))
    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    //        .font(.system(size: 18, weight: .semibold, design: .rounded))
  }

  func unlock(_ product: Product) {
    unlockManager.buy(product: product)
  }

  func getText(_ string: String) -> String {
    if string == "farm.poplar.budgetthing.smalltip" {
      return String(localized: "☕ Coffee-Sized Tip")
    } else if string == "farm.poplar.budgetthing.mediumtip" {
      return String(localized: "🌮 Taco-Sized Tip")
    } else if string == "farm.poplar.budgetthing.largetip" {
      return String(localized: "🍕 Pizza-Sized Tip")
    } else {
      return ""
    }
  }
}

struct SettingsRowView: View {
  var systemImage: String
  var title: String
  var colour: Int
  var optionalText: String?

  @Environment(\.dynamicTypeSize) var dynamicTypeSize

  var body: some View {
    GlassCard(cornerRadius: 18, tint: Color.SecondaryBackground.opacity(0.35)) {
      HStack(spacing: 12) {
        Image(systemName: systemImage)
          .font(.system(.body, design: .rounded))

          //                .font(.system(size: 17))
          //                .padding(5)
          .foregroundColor(.white)
          .frame(
            width: dynamicTypeSize > .xLarge ? 40 : 30, height: dynamicTypeSize > .xLarge ? 40 : 30,
            alignment: .center
          )
          .background(Color("\(colour)"), in: RoundedRectangle(cornerRadius: 6, style: .continuous))

        Text(LocalizedStringKey(title))
          .font(.system(.body, design: .rounded).weight(.medium))

          //                .font(.system(size: 17, weight: .medium, design: .rounded))
          .lineLimit(1)
          .foregroundColor(Color.PrimaryText)

        Spacer()

        if optionalText != nil {
          Text(optionalText!)
            .font(.system(.body, design: .rounded))

            //                    .font(.system(size: 17, weight: .regular, design: .rounded))
            .foregroundColor(.DarkIcon.opacity(0.6))
            .layoutPriority(1)
            .padding(.trailing, -8)
        }

        Image(systemName: "chevron.forward")
          .font(.system(.subheadline, design: .rounded))
          //                .font(.system(size: 15))
          .foregroundColor(.DarkIcon.opacity(0.6))
      }
      .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
    .frame(maxWidth: .infinity)
  }
}

struct SettingsCategoryView: View {
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>

  var body: some View {
    CategoryView(mode: .settings, income: false)
      .navigationBarBackButtonHidden(true)
      .navigationBarTitle("")
      .navigationBarHidden(true)
      .liquidGlassBackground()
  }
}
