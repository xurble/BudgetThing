//
//  SwiftDataModels.swift
//  dime
//
//  Created by Codex on 3/12/26.
//

import Foundation
import SwiftData

@Model
final class Budget {
    var amount: Double = 0
    var dateCreated: Date = Date(timeIntervalSince1970: 0)
    var green: Bool = false
    var id: UUID?
    var startDate: Date = Date(timeIntervalSince1970: 0)
    var type: Int16 = 0

    var category: Category?

    init(
        amount: Double = 0,
        dateCreated: Date = Date.now,
        green: Bool = false,
        id: UUID? = nil,
        startDate: Date = Date.now,
        type: Int16 = 0,
        category: Category? = nil
    ) {
        self.amount = amount
        self.dateCreated = dateCreated
        self.green = green
        self.id = id
        self.startDate = startDate
        self.type = type
        self.category = category
    }
}

@Model
final class Category {
    var colour: String?
    var dateCreated: Date = Date(timeIntervalSince1970: 0)
    var emoji: String?
    var id: UUID?
    var income: Bool = false
    var name: String?
    var order: Int64 = 0

    var budget: Budget?
    var templates: [TemplateTransaction]?
    var transactions: [Transaction]?

    init(
        colour: String? = nil,
        dateCreated: Date = Date.now,
        emoji: String? = nil,
        id: UUID? = nil,
        income: Bool = false,
        name: String? = nil,
        order: Int64 = 0,
        budget: Budget? = nil,
        templates: [TemplateTransaction]? = nil,
        transactions: [Transaction]? = nil
    ) {
        self.colour = colour
        self.dateCreated = dateCreated
        self.emoji = emoji
        self.id = id
        self.income = income
        self.name = name
        self.order = order
        self.budget = budget
        self.templates = templates
        self.transactions = transactions
    }
}

@Model
final class MainBudget {
    var amount: Double = 0
    var dateCreated: Date = Date(timeIntervalSince1970: 0)
    var green: Bool = false
    var startDate: Date = Date(timeIntervalSince1970: 0)
    var type: Int16 = 0

    init(
        amount: Double = 0,
        dateCreated: Date = Date.now,
        green: Bool = false,
        startDate: Date = Date.now,
        type: Int16 = 0
    ) {
        self.amount = amount
        self.dateCreated = dateCreated
        self.green = green
        self.startDate = startDate
        self.type = type
    }
}

@Model
final class TemplateTransaction {
    var amount: Double = 0
    var id: UUID?
    var income: Bool = false
    var note: String?
    var order: Int16 = 0
    var recurringCoefficient: Int16 = 0
    var recurringType: Int16 = 0

    var category: Category?

    init(
        amount: Double = 0,
        id: UUID? = nil,
        income: Bool = false,
        note: String? = nil,
        order: Int16 = 0,
        recurringCoefficient: Int16 = 0,
        recurringType: Int16 = 0,
        category: Category? = nil
    ) {
        self.amount = amount
        self.id = id
        self.income = income
        self.note = note
        self.order = order
        self.recurringCoefficient = recurringCoefficient
        self.recurringType = recurringType
        self.category = category
    }
}

@Model
final class Transaction {
    var amount: Double = 0
    var date: Date = Date(timeIntervalSince1970: 0)
    var day: Date = Date(timeIntervalSince1970: 0)
    var id: UUID?
    var income: Bool = false
    var month: Date = Date(timeIntervalSince1970: 0)
    var note: String?
    var onceRecurring: Bool = false
    var recurringCoefficient: Int16 = 0
    var recurringType: Int16 = 0

    var category: Category?

    init(
        amount: Double = 0,
        date: Date = Date.now,
        day: Date = Date.now,
        id: UUID? = nil,
        income: Bool = false,
        month: Date = Date.now,
        note: String? = nil,
        onceRecurring: Bool = false,
        recurringCoefficient: Int16 = 0,
        recurringType: Int16 = 0,
        category: Category? = nil
    ) {
        self.amount = amount
        self.date = date
        self.day = day
        self.id = id
        self.income = income
        self.month = month
        self.note = note
        self.onceRecurring = onceRecurring
        self.recurringCoefficient = recurringCoefficient
        self.recurringType = recurringType
        self.category = category
    }
}

@Model
final class BankConnection {
    var connectionId: String = ""
    var institutionId: String?
    var institutionName: String?
    var status: String = "active"
    var createdAt: Date = Date(timeIntervalSince1970: 0)
    var updatedAt: Date?
    var lastSyncAt: Date?
    var accountCount: Int = 0
    var nextCursor: String?

    @Relationship(inverse: \BankAccount.connection) var accounts: [BankAccount]?
    @Relationship(inverse: \BankTransaction.connection) var transactions: [BankTransaction]?

    init(
        connectionId: String = "",
        institutionId: String? = nil,
        institutionName: String? = nil,
        status: String = "active",
        createdAt: Date = Date.now,
        updatedAt: Date? = nil,
        lastSyncAt: Date? = nil,
        accountCount: Int = 0,
        nextCursor: String? = nil,
        accounts: [BankAccount]? = nil,
        transactions: [BankTransaction]? = nil
    ) {
        self.connectionId = connectionId
        self.institutionId = institutionId
        self.institutionName = institutionName
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastSyncAt = lastSyncAt
        self.accountCount = accountCount
        self.nextCursor = nextCursor
        self.accounts = accounts
        self.transactions = transactions
    }
}

@Model
final class BankAccount {
    var providerAccountId: String = ""
    var connectionId: String = ""
    var name: String = ""
    var officialName: String?
    var mask: String?
    var type: String?
    var subtype: String?
    var currentBalanceMinor: Int64?
    var availableBalanceMinor: Int64?
    var isoCurrencyCode: String?
    var minorUnit: Int16 = 2

    var connection: BankConnection?
    @Relationship(inverse: \BankTransaction.account) var transactions: [BankTransaction]?

    init(
        providerAccountId: String = "",
        connectionId: String = "",
        name: String = "",
        officialName: String? = nil,
        mask: String? = nil,
        type: String? = nil,
        subtype: String? = nil,
        currentBalanceMinor: Int64? = nil,
        availableBalanceMinor: Int64? = nil,
        isoCurrencyCode: String? = nil,
        minorUnit: Int16 = 2,
        connection: BankConnection? = nil,
        transactions: [BankTransaction]? = nil
    ) {
        self.providerAccountId = providerAccountId
        self.connectionId = connectionId
        self.name = name
        self.officialName = officialName
        self.mask = mask
        self.type = type
        self.subtype = subtype
        self.currentBalanceMinor = currentBalanceMinor
        self.availableBalanceMinor = availableBalanceMinor
        self.isoCurrencyCode = isoCurrencyCode
        self.minorUnit = minorUnit
        self.connection = connection
        self.transactions = transactions
    }
}

@Model
final class BankTransaction {
    var providerTransactionId: String = ""
    var providerAccountId: String = ""
    var connectionId: String = ""
    var amountMinor: Int64 = 0
    var minorUnit: Int16 = 2
    var isoCurrencyCode: String?
    var date: Date = Date(timeIntervalSince1970: 0)
    var authorizedDate: Date?
    var name: String = ""
    var merchantName: String?
    var paymentChannel: String?
    var pending: Bool = false
    var personalFinanceCategoryPrimary: String?
    var rawJSON: String?
    var removedAt: Date?

    var connection: BankConnection?
    var account: BankAccount?

    init(
        providerTransactionId: String = "",
        providerAccountId: String = "",
        connectionId: String = "",
        amountMinor: Int64 = 0,
        minorUnit: Int16 = 2,
        isoCurrencyCode: String? = nil,
        date: Date = Date.now,
        authorizedDate: Date? = nil,
        name: String = "",
        merchantName: String? = nil,
        paymentChannel: String? = nil,
        pending: Bool = false,
        personalFinanceCategoryPrimary: String? = nil,
        rawJSON: String? = nil,
        removedAt: Date? = nil,
        connection: BankConnection? = nil,
        account: BankAccount? = nil
    ) {
        self.providerTransactionId = providerTransactionId
        self.providerAccountId = providerAccountId
        self.connectionId = connectionId
        self.amountMinor = amountMinor
        self.minorUnit = minorUnit
        self.isoCurrencyCode = isoCurrencyCode
        self.date = date
        self.authorizedDate = authorizedDate
        self.name = name
        self.merchantName = merchantName
        self.paymentChannel = paymentChannel
        self.pending = pending
        self.personalFinanceCategoryPrimary = personalFinanceCategoryPrimary
        self.rawJSON = rawJSON
        self.removedAt = removedAt
        self.connection = connection
        self.account = account
    }
}
