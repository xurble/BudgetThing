//
//  UnlockManager.swift
//  dime
//
//  Created by Rafael Soh on 15/9/22.
//

import Foundation
import StoreKit

@MainActor
class UnlockManager: NSObject, ObservableObject, @preconcurrency SKPaymentTransactionObserver, @preconcurrency SKProductsRequestDelegate {
    enum RequestState {
        case loading
        case loaded
        case failed
    }

    var canMakePayments: Bool {
        SKPaymentQueue.canMakePayments()
    }

    private enum StoreError: Error {
        case invalidIdentifiers, missingProduct
    }

    @Published var requestState = RequestState.loading
    @Published var purchaseCount: Int
    @Published var failedTransaction = false

    private let dataController: DataController
    private let request: SKProductsRequest

    var loadedProducts = [SKProduct]()

    nonisolated func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        Task { @MainActor in
            for transaction in transactions {
                switch transaction.transactionState {
                case .purchased, .restored:
                    purchaseCount += 1
                    dataController.tipCounter = purchaseCount
                    queue.finishTransaction(transaction)
                case .failed:
                    failedTransaction = true
                    queue.finishTransaction(transaction)
                    revertBool()
                default:
                    break
                }
            }
        }
    }

    nonisolated func productsRequest(_: SKProductsRequest, didReceive response: SKProductsResponse) {
        Task { @MainActor in
            // Store the returned products for later, if we need them.
            loadedProducts = response.products

            guard !loadedProducts.isEmpty else {
                requestState = .failed
                return
            }

            if response.invalidProductIdentifiers.isEmpty == false {
                print("ALERT: Received invalid product identifiers: \(response.invalidProductIdentifiers)")
                requestState = .failed
                return
            }

            requestState = .loaded
        }
    }

    func buy(product: SKProduct) {
        let payment = SKPayment(product: product)
        SKPaymentQueue.default().add(payment)
    }

    func revertBool() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            failedTransaction = false
        }
    }

    func restore() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }

    init(dataController: DataController) {
        // Store the data controller we were sent.
        self.dataController = dataController

        // Prepare to look for our unlock product.
        let productIDs = Set(["farm.poplar.budgetthing.smalltip", "farm.poplar.budgetthing.mediumtip", "farm.poplar.budgetthing.largetip"])
        request = SKProductsRequest(productIdentifiers: productIDs)

        // This is required because we inherit from NSObject.
        purchaseCount = dataController.tipCounter

        super.init()

        // Start watching the payment queue.
        SKPaymentQueue.default().add(self)

        // Set ourselves up to be notified when the product request completes.
        request.delegate = self

        // Start the request
        request.start()
    }

    deinit {
        SKPaymentQueue.default().remove(self)
    }
}
