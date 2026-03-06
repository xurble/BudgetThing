//
//  UnlockManager.swift
//  dime
//
//  Created by Rafael Soh on 15/9/22.
//

import Foundation
import StoreKit

@MainActor
final class UnlockManager: ObservableObject {
    typealias StoreTransaction = StoreKit.Transaction
    typealias StoreVerificationResult = StoreKit.VerificationResult<StoreTransaction>

    enum RequestState {
        case loading
        case loaded
        case failed
    }

    @Published var requestState = RequestState.loading
    @Published var purchaseCount: Int
    @Published var failedTransaction = false
    @Published var loadedProducts: [Product] = []

    private let dataController: DataController
    private let productIDs = [
        "farm.poplar.budgetthing.smalltip",
        "farm.poplar.budgetthing.mediumtip",
        "farm.poplar.budgetthing.largetip"
    ]
    private var updatesTask: Task<Void, Never>?
    private var unfinishedTask: Task<Void, Never>?
    private var productTask: Task<Void, Never>?
    private var processedTransactionIDs = Set<StoreTransaction.ID>()

    var canMakePayments: Bool {
        AppStore.canMakePayments
    }

    init(dataController: DataController) {
        self.dataController = dataController
        purchaseCount = dataController.tipCounter

        productTask = Task { [weak self] in
            await self?.loadProducts()
        }

        unfinishedTask = Task { [weak self] in
            await self?.observeUnfinishedTransactions()
        }

        updatesTask = Task { [weak self] in
            await self?.observeTransactionUpdates()
        }
    }

    deinit {
        updatesTask?.cancel()
        unfinishedTask?.cancel()
        productTask?.cancel()
    }

    func buy(product: Product) {
        Task { [weak self] in
            await self?.purchase(product)
        }
    }

    func restore() {
        Task { [weak self] in
            do {
                try await AppStore.sync()
            } catch {
                self?.failedTransaction = true
                self?.revertBool()
            }
        }
    }

    func revertBool() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            failedTransaction = false
        }
    }

    private func loadProducts() async {
        requestState = .loading
        do {
            let products = try await Product.products(for: productIDs)
            guard !products.isEmpty else {
                requestState = .failed
                return
            }

            loadedProducts = products
            requestState = .loaded
        } catch {
            requestState = .failed
        }
    }

    private func purchase(_ product: Product) async {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verificationResult):
                await handle(verificationResult)
            case .userCancelled:
                break
            case .pending:
                break
            @unknown default:
                break
            }
        } catch {
            failedTransaction = true
            revertBool()
        }
    }

    private func observeTransactionUpdates() async {
        for await verificationResult in StoreTransaction.updates {
            await handle(verificationResult)
        }
    }

    private func observeUnfinishedTransactions() async {
        for await verificationResult in StoreTransaction.unfinished {
            await handle(verificationResult)
        }
    }

    private func handle(_ verificationResult: StoreVerificationResult) async {
        guard case .verified(let transaction) = verificationResult else {
            return
        }

        if !processedTransactionIDs.insert(transaction.id).inserted {
            await transaction.finish()
            return
        }

        if productIDs.contains(transaction.productID) {
            purchaseCount += 1
            dataController.tipCounter = purchaseCount
        }

        await transaction.finish()
    }
}
