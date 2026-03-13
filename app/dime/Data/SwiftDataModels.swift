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
    var amount: Double
    var dateCreated: Date
    var green: Bool
    var id: UUID?
    var startDate: Date
    var type: Int16

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
    var dateCreated: Date
    var emoji: String?
    var id: UUID?
    var income: Bool
    var name: String?
    var order: Int64

    var budget: Budget?
    var templates: [TemplateTransaction]
    var transactions: [Transaction]

    init(
        colour: String? = nil,
        dateCreated: Date = Date.now,
        emoji: String? = nil,
        id: UUID? = nil,
        income: Bool = false,
        name: String? = nil,
        order: Int64 = 0,
        budget: Budget? = nil,
        templates: [TemplateTransaction] = [],
        transactions: [Transaction] = []
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
    var amount: Double
    var dateCreated: Date
    var green: Bool
    var startDate: Date
    var type: Int16

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
    var amount: Double
    var id: UUID?
    var income: Bool
    var note: String?
    var order: Int16
    var recurringCoefficient: Int16
    var recurringType: Int16

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
    var amount: Double
    var date: Date
    var day: Date
    var id: UUID?
    var income: Bool
    var month: Date
    var note: String?
    var onceRecurring: Bool
    var recurringCoefficient: Int16
    var recurringType: Int16

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
