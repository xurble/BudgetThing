//
//  SettingsCloudView.swift
//  dime
//
//  Created by Rafael Soh on 5/11/23.
//

import Foundation
import SwiftUI

struct SettingsCloudView: View {
  @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
  @EnvironmentObject var dataController: DataController
  @State private var iCloudStorage: Bool = false
  @State private var showRelaunchPrompt = false
  @State private var shouldIgnoreNextToggle = true
  @Namespace var animation

  private let appGroupID = "group.farm.poplar.budgetthing"

  private var cloudKitDatabaseLabel: String {
    String(describing: dataController.cloudKitDatabase)
  }

  var body: some View {
    VStack(spacing: 10) {
      Text("iCloud Sync")
        .font(.system(.title3, design: .rounded).weight(.semibold))
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        //                .font(.system(size: 20, weight: .semibold, design: .rounded))
        .foregroundColor(Color.PrimaryText)
        .frame(maxWidth: .infinity)
        .overlay(alignment: .leading) {
          Button {
            self.presentationMode.wrappedValue.dismiss()
          } label: {
            SettingsBackButton()
          }
        }
        .padding(.bottom, 20)

      VStack(spacing: 0) {
        HStack {
          Text("Enable Sync")
            .font(.system(.body, design: .rounded))
            .foregroundColor(Color.PrimaryText)

          Spacer()

          ZStack(alignment: iCloudStorage ? .trailing : .leading) {
            Capsule()
              .frame(width: 42, height: 28)
              .foregroundColor(iCloudStorage ? .green : .gray.opacity(0.8))

            Circle()
              .foregroundColor(Color.white)
              .padding(2)
              .frame(width: 28, height: 28)
              .matchedGeometryEffect(id: "toggle", in: animation)
          }
          .onTapGesture {
            iCloudStorage.toggle()
          }
          .onChange(of: iCloudStorage) { _, newValue in
            if shouldIgnoreNextToggle {
              shouldIgnoreNextToggle = false
              return
            }
            UserDefaults(suiteName: appGroupID)?.set(newValue, forKey: "icloud_sync")
            NSUbiquitousKeyValueStore.default.set(newValue, forKey: "icloud_sync")
            NSUbiquitousKeyValueStore.default.synchronize()
            showRelaunchPrompt = true
          }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
      }
      .padding(.horizontal, 15)
      .background(Color.SettingsBackground, in: RoundedRectangle(cornerRadius: 9))

      Text("Close and reload app for change to take effect.")
        .font(.system(.caption, design: .rounded).weight(.medium))
        .multilineTextAlignment(.leading)
        .foregroundColor(Color.SubtitleText)
        .padding(.horizontal, 15)
        .frame(maxWidth: .infinity, alignment: .leading)

#if DEBUG
      VStack(alignment: .leading, spacing: 6) {
        Text("CloudKit Debug")
          .font(.system(.caption, design: .rounded).weight(.semibold))
          .foregroundColor(Color.SubtitleText)

        let storePath = dataController.storeURL?.path ?? "nil"
        let appGroupValue = UserDefaults(suiteName: appGroupID)?.bool(forKey: "icloud_sync") ?? false
        let ubiquitousValue = NSUbiquitousKeyValueStore.default.bool(forKey: "icloud_sync")
        let bundleId = Bundle.main.bundleIdentifier ?? "unknown"

        Text("cloudKitEnabled: \(dataController.cloudKitEnabled)")
        Text("cloudKitDatabase: \(cloudKitDatabaseLabel)")
        Text("storeURL: \(storePath)")
        Text("appGroup iCloud: \(appGroupValue)")
        Text("ubiquitous iCloud: \(ubiquitousValue)")
        Text("bundle: \(bundleId)")
      }
      .font(.system(.caption2, design: .monospaced))
      .foregroundColor(Color.SubtitleText)
      .padding(.horizontal, 15)
      .padding(.top, 6)
      .frame(maxWidth: .infinity, alignment: .leading)
#endif
    }
    .onAppear {
      if let storedValue = UserDefaults(suiteName: appGroupID)?.object(forKey: "icloud_sync") as? Bool {
        iCloudStorage = storedValue
      } else {
        iCloudStorage = NSUbiquitousKeyValueStore.default.bool(forKey: "icloud_sync")
      }
      shouldIgnoreNextToggle = true
    }
    .alert("Restart Required", isPresented: $showRelaunchPrompt) {
      Button("OK", role: .cancel) {}
    } message: {
      Text("Please force-quit and relaunch the app to apply the iCloud sync change.")
    }
    .modifier(SettingsSubviewModifier())

  }
}
