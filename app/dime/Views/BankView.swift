//
//  BankView.swift
//  dime
//
//  Created by Gareth Simpson on 7/3/2026
//

import LinkKit
import SwiftData
import SwiftUI
import UIKit

struct BankView: View {
    @EnvironmentObject private var dataController: DataController

    @Query(sort: [SortDescriptor(\BankConnection.createdAt, order: .reverse)])
    private var connections: [BankConnection]

    @State private var isPresentingLink = false

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Bank")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            Task { await dataController.startBankLink() }
                        } label: {
                            if dataController.bankIsLinking {
                                ProgressView()
                                    .tint(Color.PrimaryText)
                            } else {
                                Label("Add Bank", systemImage: "plus")
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            }
                        }
                        .disabled(dataController.bankIsLinking)
                    }
                }
        }
        .toast(isPresenting: $dataController.bankingShowToast, duration: 4, tapToDismiss: true, offsetY: 12, alert: {
            AlertToast(
                displayMode: .hud,
                type: .systemImage("exclamationmark.triangle.fill", Color.AlertRed),
                title: "Banking setup failed",
                subTitle: dataController.bankingStatusMessage ?? ""
            )
        })
        .onChange(of: dataController.bankLinkToken) { _, newValue in
            isPresentingLink = (newValue != nil)
        }
        .sheet(isPresented: $isPresentingLink, onDismiss: {
            Task { @MainActor in
                dataController.clearBankLinkToken()
            }
        }) {
            if let token = dataController.bankLinkToken {
                PlaidLinkSheet(
                    linkToken: token,
                    onSuccess: { publicToken in
                        Task { await dataController.handleBankLinkSuccess(publicToken: publicToken) }
                    },
                    onExit: {
                        Task { await dataController.handleBankLinkExit() }
                    },
                    onFailure: { error in
                        Task { await dataController.handleBankLinkError(error) }
                    }
                )
            } else {
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if connections.isEmpty {
            BankEmptyStateView(
                statusMessage: dataController.bankingStatusMessage,
                isError: dataController.bankingStatusIsError
            )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .liquidGlassBackground()
        } else {
            List {
                ForEach(connections) { connection in
                    NavigationLink {
                        BankConnectionDetailView(connection: connection)
                    } label: {
                        BankConnectionRow(connection: connection)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .liquidGlassBackground()
        }
    }

}

private struct BankEmptyStateView: View {
    let statusMessage: String?
    let isError: Bool

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "building.columns")
                .font(.system(size: 46, weight: .semibold, design: .rounded))
                .foregroundColor(Color.PrimaryText)

            Text("Connect your bank")
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundColor(Color.PrimaryText)

            Text("Bank sync is coming soon. We're finishing the BFF setup first.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(Color.SubtitleText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if let statusMessage, !statusMessage.isEmpty {
                Text(statusMessage)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(isError ? Color.AlertRed : Color.SubtitleText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
        .padding(.horizontal, 24)
    }
}

private struct BankConnectionRow: View {
    let connection: BankConnection

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "banknote")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(Color.PrimaryText)
                .frame(width: 42, height: 42)
                .background(Color.SecondaryBackground.opacity(0.45), in: RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(connection.wrappedInstitutionName)
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundColor(Color.PrimaryText)

                HStack(spacing: 8) {
                    BankStatusBadge(status: connection.status)

                    Text(accountLabel)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(Color.SubtitleText)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let lastSyncAt = connection.lastSyncAt {
                    Text(lastSyncAt, style: .relative)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(Color.SubtitleText)
                } else {
                    Text("Not synced")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(Color.SubtitleText)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .glassRoundedRect(cornerRadius: 16, tint: Color.SecondaryBackground.opacity(0.35))
    }

    private var accountLabel: String {
        let count = connection.accountCount
        return count == 1 ? "1 account" : "\(count) accounts"
    }
}

private struct BankStatusBadge: View {
    let status: String

    var body: some View {
        Text(label)
            .font(.system(.caption2, design: .rounded).weight(.semibold))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(color.opacity(0.12), in: Capsule())
    }

    private var label: String {
        status.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private var color: Color {
        switch status {
        case "active":
            return Color.IncomeGreen
        case "needs_reauth":
            return Color.AlertRed
        case "revoked", "error":
            return Color.AlertRed
        default:
            return Color.SubtitleText
        }
    }
}

private struct BankConnectionDetailView: View {
    let connection: BankConnection

    @Query private var transactions: [BankTransaction]

    init(connection: BankConnection) {
        self.connection = connection
        let connectionId = connection.connectionId
        _transactions = Query(
            filter: #Predicate<BankTransaction> { $0.connectionId == connectionId },
            sort: [SortDescriptor(\BankTransaction.date, order: .reverse)]
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                header

                if recentTransactions.isEmpty {
                    emptyTransactions
                } else {
                    VStack(spacing: 12) {
                        ForEach(recentTransactions) { transaction in
                            BankTransactionRow(transaction: transaction)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 32)
        }
        .navigationTitle(connection.wrappedInstitutionName)
        .navigationBarTitleDisplayMode(.inline)
        .liquidGlassBackground()
    }

    private var recentTransactions: [BankTransaction] {
        transactions.filter { !$0.isRemoved }.prefix(15).map { $0 }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(connection.wrappedInstitutionName)
                        .font(.system(.title3, design: .rounded).weight(.semibold))
                        .foregroundColor(Color.PrimaryText)

                    Text("\(connection.accountCount) accounts")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(Color.SubtitleText)
                }

                Spacer()

                BankStatusBadge(status: connection.status)
            }

            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(Color.SubtitleText)

                if let lastSyncAt = connection.lastSyncAt {
                    Text("Last synced \(lastSyncAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(Color.SubtitleText)
                } else {
                    Text("Not synced yet")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(Color.SubtitleText)
                }

                Spacer()
            }
        }
        .padding(16)
        .glassRoundedRect(cornerRadius: 18, tint: Color.SecondaryBackground.opacity(0.4))
    }

    private var emptyTransactions: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 36, weight: .semibold, design: .rounded))
                .foregroundColor(Color.PrimaryText)

            Text("No transactions yet")
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundColor(Color.PrimaryText)

            Text("Sync this bank to see recent activity.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(Color.SubtitleText)
        }
        .padding(24)
        .glassRoundedRect(cornerRadius: 18, tint: Color.SecondaryBackground.opacity(0.35))
    }
}

private struct BankTransactionRow: View {
    let transaction: BankTransaction

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.displayName)
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundColor(Color.PrimaryText)

                HStack(spacing: 8) {
                    Text(transaction.date, style: .date)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(Color.SubtitleText)

                    if transaction.pending {
                        Text("Pending")
                            .font(.system(.caption2, design: .rounded).weight(.semibold))
                            .foregroundColor(Color.AlertRed)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.AlertRed.opacity(0.12), in: Capsule())
                    }
                }
            }

            Spacer()

            Text(formattedAmount)
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundColor(amountColor)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassRoundedRect(cornerRadius: 16, tint: Color.SecondaryBackground.opacity(0.35))
    }

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = transaction.isoCurrencyCode ?? Locale.current.currency?.identifier
        formatter.minimumFractionDigits = Int(transaction.minorUnit)
        formatter.maximumFractionDigits = Int(transaction.minorUnit)
        let value = NSNumber(value: transaction.amountMajor)
        return formatter.string(from: value) ?? "\(transaction.amountMajor)"
    }

    private var amountColor: Color {
        transaction.amountMinor < 0 ? Color.IncomeGreen : Color.PrimaryText
    }
}

private struct PlaidLinkSheet: UIViewControllerRepresentable {
    let linkToken: String
    let onSuccess: (String) -> Void
    let onExit: () -> Void
    let onFailure: (Error) -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        UIViewController()
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        guard context.coordinator.handler == nil else { return }

        var configuration = LinkTokenConfiguration(token: linkToken) { success in
            onSuccess(success.publicToken)
        }
        configuration.onExit = { _ in
            onExit()
        }

        let result = Plaid.create(configuration)
        switch result {
        case let .success(handler):
            context.coordinator.handler = handler
            handler.open(presentUsing: .viewController(uiViewController))
        case let .failure(error):
            onFailure(error)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        var handler: Handler?
    }
}

#Preview {
    BankView()
}
