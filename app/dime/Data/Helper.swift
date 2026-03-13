//
//  Helper.swift
//  dime
//
//  Created by Rafael Soh on 13/8/22.
//

import Foundation

extension Transaction {
    var wrappedAmount: Double {
        amount
    }

    var wrappedDate: Date {
        date
    }

    var wrappedNote: String {
        note ?? ""
    }

    var wrappedCategoryName: String {
        category?.wrappedName ?? ""
    }

    var wrappedColour: String {
        category?.wrappedColour ?? ""
    }

    var nextTransactionDate: Date {
        if recurringType == 1 {
            return Calendar.current.date(byAdding: .day, value: Int(recurringCoefficient), to: day)!
        } else if recurringType == 2 {
            return Calendar.current.date(byAdding: .day, value: Int(recurringCoefficient * 7), to: day)!
        } else if recurringType == 3 {
            return Calendar.current.date(byAdding: .month, value: Int(recurringCoefficient), to: day)!
        }

        return date
    }
}

extension TemplateTransaction {
    var wrappedAmount: Double {
        amount
    }

    var wrappedNote: String {
        note ?? ""
    }

    var wrappedEmoji: String {
        category?.wrappedEmoji ?? ""
    }

    var wrappedColour: String {
        category?.wrappedColour ?? ""
    }
}

extension Category {
    var wrappedColour: String {
        colour ?? "#FFFFFF"
    }

    var wrappedEmoji: String {
        emoji ?? "😄️"
    }

    var wrappedName: String {
        name ?? ""
    }

    var wrappedDate: Date {
        dateCreated
    }

    var fullName: String {
        wrappedEmoji + "  " + wrappedName
    }

    var allTransactions: [Transaction] {
        (transactions ?? []).sorted { $0.wrappedDate < $1.wrappedDate }
    }

    var transactionCount: Int {
        transactions?.count ?? 0
    }
}

extension Budget {
    var wrappedColour: String {
        category?.wrappedColour ?? "#FFFFFF"
    }

    var wrappedName: String {
        category?.wrappedName ?? ""
    }

    var wrappedEmoji: String {
        category?.wrappedEmoji ?? ""
    }

    var fullName: String {
        return wrappedEmoji + " " + wrappedName
    }

    var wrappedDate: Date {
        return startDate
    }

    var endDate: Date {
        if type == 1 {
            return Calendar.current.date(byAdding: .day, value: 1, to: startDate)!
        } else if type == 2 {
            return Calendar.current.date(byAdding: .day, value: 7, to: startDate)!
        } else if type == 3 {
            return Calendar.current.date(byAdding: .month, value: 1, to: startDate)!
        } else if type == 4 {
            return Calendar.current.date(byAdding: .year, value: 1, to: startDate)!
        }
        return startDate
    }
}

extension MainBudget {
    var wrappedDate: Date {
        return startDate
    }

    var endDate: Date {
        if type == 1 {
            return Calendar.current.date(byAdding: .day, value: 1, to: startDate)!
        } else if type == 2 {
            return Calendar.current.date(byAdding: .day, value: 7, to: startDate)!
        } else if type == 3 {
            return Calendar.current.date(byAdding: .month, value: 1, to: startDate)!
        } else if type == 4 {
            return Calendar.current.date(byAdding: .year, value: 1, to: startDate)!
        }

        return startDate
    }
}
