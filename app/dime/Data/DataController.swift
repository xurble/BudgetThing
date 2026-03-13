//
//  DataController.swift
//  Bonsai
//
//  Created by Rafael Soh on 3/6/22.
//

import Foundation
import SwiftData
import SwiftUI
import WidgetKit

enum CustomError: Swift.Error, CustomLocalizedStringResourceConvertible {
    case notFound,
         coreDataSave,
         unknownId(id: String),
         unknownError(message: String)

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case let .unknownError(message): return "An unknown error occurred: \(message)"
        case let .unknownId(id): return "No category with an ID matching: \(id)"
        case .notFound: return "Category not found"
        case .coreDataSave: return "Couldn't save to CoreData"
        }
    }
}

class DataController: ObservableObject, @unchecked Sendable {
    static let shared = DataController()

    let modelContainer: ModelContainer
    let mainContext: ModelContext
    let storeURL: URL?
    let cloudKitEnabled: Bool
    let cloudKitDatabase: ModelConfiguration.CloudKitDatabase

    init() {
        let groupID = "group.farm.poplar.budgetthing"
        let baseURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: groupID)
        let storeURL = baseURL?.appendingPathComponent("SwiftData.sqlite")

        let cloudKitEnabled = UserDefaults(suiteName: groupID)?.bool(forKey: "icloud_sync") ?? NSUbiquitousKeyValueStore.default.bool(forKey: "icloud_sync")
        let cloudKitDatabase: ModelConfiguration.CloudKitDatabase = cloudKitEnabled
            ? .private("iCloud.farm.poplar.BudgetThingData")
            : .none

        if let baseURL {
            Self.removeLegacyStoreIfNeeded(at: baseURL)
        }

        let container: ModelContainer

        do {
            if let storeURL {
                let config = ModelConfiguration(
                    "MainModel",
                    url: storeURL,
                    allowsSave: true,
                    cloudKitDatabase: cloudKitDatabase
                )
                container = try ModelContainer(
                    for: Budget.self,
                    Category.self,
                    MainBudget.self,
                    TemplateTransaction.self,
                    Transaction.self,
                    configurations: config
                )
            } else {
                let config = ModelConfiguration(cloudKitDatabase: cloudKitDatabase)
                container = try ModelContainer(
                    for: Budget.self,
                    Category.self,
                    MainBudget.self,
                    TemplateTransaction.self,
                    Transaction.self,
                    configurations: config
                )
            }
        } catch {
            fatalError("Unresolved error \(error.localizedDescription)")
        }

        modelContainer = container
        mainContext = ModelContext(container)
        self.storeURL = storeURL
        self.cloudKitEnabled = cloudKitEnabled
        self.cloudKitDatabase = cloudKitDatabase
    }

    private static func removeLegacyStoreIfNeeded(at baseURL: URL) {
        let legacyNames = [
            "Main.sqlite",
            "Main.sqlite-shm",
            "Main.sqlite-wal"
        ]

        for name in legacyNames {
            let url = baseURL.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: url.path) {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    // internal variables

    var tipCounter: Int {
        get {
            UserDefaults.standard.integer(forKey: "tipCounter")
        }

        set {
            UserDefaults.standard.set(newValue, forKey: "tipCounter")
        }
    }

    var addedTransaction: Bool {
        get {
            UserDefaults(suiteName: "group.farm.poplar.budgetthing")!.bool(forKey: "newTransactionAdded")
        }

        set {
            UserDefaults(suiteName: "group.farm.poplar.budgetthing")!.set(newValue, forKey: "newTransactionAdded")
        }
    }

    // adding or deleting

    func deleteAll() {
        do {
            try mainContext.delete(model: Transaction.self)
            try mainContext.delete(model: Category.self)
            try mainContext.delete(model: Budget.self)
            try mainContext.delete(model: MainBudget.self)
            try mainContext.save()
        } catch {
            print("Failed to delete all data: \(error)")
        }
    }

    func save() {
        save(context: mainContext)
    }

    func save(context: ModelContext) {
        if context.hasChanges {
            try? context.save()
            DispatchQueue.main.async {
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }

    func updateRecurringTransaction(
        transaction: Transaction,
        context: ModelContext? = nil,
        shouldSave: Bool = true
    ) {
        let context = context ?? mainContext

        if transaction.nextTransactionDate < Calendar.current.startOfDay(for: Date.now) {
            var holdingDate = transaction.nextTransactionDate

            while holdingDate <= Calendar.current.startOfDay(for: Date.now) {
                let newTransaction = Transaction()
                newTransaction.note = transaction.wrappedNote
                newTransaction.category = transaction.category
                newTransaction.amount = transaction.wrappedAmount
                newTransaction.date = holdingDate
                newTransaction.id = UUID()
                newTransaction.income = transaction.income
                newTransaction.day = holdingDate

                let calendar = Calendar(identifier: .gregorian)

                let dateComponents = calendar.dateComponents([.month, .year], from: holdingDate)

                newTransaction.month = calendar.date(from: dateComponents)!

                newTransaction.onceRecurring = true

                var newDate: Date?

                if transaction.recurringType == 1 {
                    newDate = Calendar.current.date(byAdding: .day, value: Int(transaction.recurringCoefficient), to: holdingDate)!
                } else if transaction.recurringType == 2 {
                    newDate = Calendar.current.date(byAdding: .day, value: Int(transaction.recurringCoefficient * 7), to: holdingDate)!
                } else if transaction.recurringType == 3 {
                    newDate = Calendar.current.date(byAdding: .month, value: Int(transaction.recurringCoefficient), to: holdingDate)!
                }

                if newDate! > Calendar.current.startOfDay(for: Date.now) {
                    newTransaction.recurringType = transaction.recurringType
                    newTransaction.recurringCoefficient = transaction.recurringCoefficient
                } else {
                    newTransaction.recurringType = 0
                }

                context.insert(newTransaction)

                holdingDate = newDate!
            }

            transaction.recurringType = 0

            if shouldSave {
                save(context: context)
            }

        } else if Calendar.current.isDateInToday(transaction.nextTransactionDate) {
            let newTransaction = Transaction()
            newTransaction.note = transaction.wrappedNote
            newTransaction.category = transaction.category
            newTransaction.amount = transaction.wrappedAmount
            newTransaction.date = transaction.nextTransactionDate
            newTransaction.id = UUID()
            newTransaction.income = transaction.income
            newTransaction.day = transaction.nextTransactionDate

            let calendar = Calendar(identifier: .gregorian)

            let dateComponents = calendar.dateComponents([.month, .year], from: transaction.nextTransactionDate)

            newTransaction.month = calendar.date(from: dateComponents)!

            newTransaction.onceRecurring = true
            newTransaction.recurringType = transaction.recurringType
            newTransaction.recurringCoefficient = transaction.recurringCoefficient

            transaction.recurringType = 0

            context.insert(newTransaction)

            if shouldSave {
                save(context: context)
            }
        }
    }

    func updateRecurringTransactions() {
        let recurringTransactions = results(for: fetchDescriptorForRecurringTransactions())

        recurringTransactions.forEach { transaction in
            updateRecurringTransaction(transaction: transaction)
        }
    }

    func updateRecurringTransactionsInBackground() {
        Task(priority: .utility) {
            let context = ModelContext(modelContainer)
            let descriptor = fetchDescriptorForRecurringTransactions()

            do {
                let recurringTransactions = try context.fetch(descriptor)
                recurringTransactions.forEach { transaction in
                    updateRecurringTransaction(
                        transaction: transaction,
                        context: context,
                        shouldSave: false
                    )
                }

                save(context: context)
            } catch {
                print("Failed to update recurring transactions: \(error)")
            }
        }
    }

    func updateBudgetDates() {
        let budgets = results(for: fetchDescriptorForBudgets())
        let mainBudget = results(for: fetchDescriptorForMainBudget())

        budgets.forEach { budget in
            while budget.endDate <= Date.now {
                budget.startDate = budget.endDate
            }
        }

        mainBudget.forEach { budget in
            while budget.endDate <= Date.now {
                budget.startDate = budget.endDate
            }
        }

        save()
    }

    func newTransaction(note: String, category: Category?, income: Bool, amount: Double, date: Date, repeatType: Int, repeatCoefficient: Int, delay _: Bool) -> Transaction {
        let transaction = Transaction()

        if note.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            transaction.note = category?.wrappedName ?? ""
        } else {
            transaction.note = note.trimmingCharacters(in: .whitespaces)
        }

        transaction.income = income

        if let unwrappedCategory = category {
            transaction.category = unwrappedCategory
        }

        transaction.amount = amount
        transaction.date = date
        transaction.id = UUID()

        let calendar = Calendar(identifier: .gregorian)

        transaction.day = calendar.date(bySettingHour: 0, minute: 0, second: 0, of: date) ?? Date.now

        let dateComponents = calendar.dateComponents([.month, .year], from: date)

        transaction.month = calendar.date(from: dateComponents) ?? Date.now

        if repeatType > 0 {
            transaction.onceRecurring = true
            transaction.recurringType = Int16(repeatType)
            transaction.recurringCoefficient = Int16(repeatCoefficient)
            updateRecurringTransaction(transaction: transaction)
        }

        mainContext.insert(transaction)
        save()

        return transaction
    }

    func newTemplateTransaction(order: Int) {
        if let match = getTemplateTransaction(order: order) {
            if let unwrappedCategory = match.category {
                _ = newTransaction(note: match.note ?? "", category: unwrappedCategory, income: match.income, amount: match.amount, date: Date.now, repeatType: Int(match.recurringType), repeatCoefficient: Int(match.recurringCoefficient), delay: false)

                addedTransaction = true
            }
        }
    }

    // fetching

    func fetchDescriptorForRecurringTransactions() -> FetchDescriptor<Transaction> {
        let predicate = #Predicate<Transaction> { $0.recurringType > 0 }
        return FetchDescriptor(predicate: predicate)
    }

    func getTemplateTransaction(order: Int) -> TemplateTransaction? {
        let orderValue = Int16(order)
        let predicate = #Predicate<TemplateTransaction> { $0.order == orderValue }
        let descriptor = FetchDescriptor(predicate: predicate)
        let results = results(for: descriptor)

        if results.count > 1 {
            let output = results.first

            for i in 1 ..< results.count {
                mainContext.delete(results[i])
            }

            save()

            return output
        } else {
            return results.first
        }
    }

    func getAllTemplateTransactions() -> [TemplateTransaction] {
        let descriptor = FetchDescriptor<TemplateTransaction>()
        return results(for: descriptor)
    }

    func fetchDescriptorForRecentTransactions(type: TimePeriod) -> FetchDescriptor<Transaction> {
        var descriptor = FetchDescriptor<Transaction>()

        var calendar = Calendar(identifier: .gregorian)

        calendar.firstWeekday = UserDefaults(suiteName: "group.farm.poplar.budgetthing")!.integer(forKey: "firstWeekday")
        calendar.minimumDaysInFirstWeek = 4

        switch type {
        case .unknown:
            return descriptor
        case .day:
            let today = calendar.startOfDay(for: Date.now)
            let nextDay = calendar.date(byAdding: .day, value: 1, to: today)!
            let predicate = #Predicate<Transaction> {
                $0.date >= today && $0.date < nextDay
            }
            descriptor.predicate = predicate
            descriptor.sortBy = [SortDescriptor(\.date, order: .reverse)]
            return descriptor
        case .week:
            let dateComponents = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: Date.now)

            let thisWeek = calendar.date(from: dateComponents)!
            let nextWeek = calendar.date(byAdding: .day, value: 7, to: thisWeek)!
            let predicate = #Predicate<Transaction> {
                $0.date >= thisWeek && $0.date < nextWeek
            }
            descriptor.predicate = predicate
            descriptor.sortBy = [SortDescriptor(\.date, order: .reverse)]
            return descriptor
        case .month:
            let dateComponents = calendar.dateComponents([.month, .year], from: Date.now)

            let thisMonth = calendar.date(from: dateComponents)!
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: thisMonth)!
            let predicate = #Predicate<Transaction> {
                $0.date >= thisMonth && $0.date < nextMonth
            }
            descriptor.predicate = predicate
            descriptor.sortBy = [SortDescriptor(\.date, order: .reverse)]
            return descriptor
        case .year:
            let dateComponents = calendar.dateComponents([.year], from: Date.now)

            let thisYear = calendar.date(from: dateComponents)!
            let nextYear = calendar.date(byAdding: .year, value: 1, to: thisYear)!
            let predicate = #Predicate<Transaction> {
                $0.date >= thisYear && $0.date < nextYear
            }
            descriptor.predicate = predicate
            descriptor.sortBy = [SortDescriptor(\.date, order: .reverse)]
            return descriptor
        }
    }

    func fetchDescriptorForExport() -> FetchDescriptor<Transaction> {
        var descriptor = FetchDescriptor<Transaction>()
        descriptor.sortBy = [SortDescriptor(\.date, order: .reverse)]
        return descriptor
    }

    func fetchDescriptorForCategoriesMigration(income: Bool? = nil) -> FetchDescriptor<Category> {
        var descriptor = FetchDescriptor<Category>()
        descriptor.sortBy = [SortDescriptor(\.dateCreated)]

        if let unwrappedIncome = income {
            descriptor.predicate = #Predicate<Category> { $0.income == unwrappedIncome }
        }

        return descriptor
    }

    func fetchDescriptorForCategories(income: Bool) -> FetchDescriptor<Category> {
        var descriptor = FetchDescriptor<Category>()
        descriptor.sortBy = [SortDescriptor(\.order)]
        descriptor.predicate = #Predicate<Category> { $0.income == income }
        return descriptor
    }

    func getAllCategories(income: Bool) -> [Category] {
        let descriptor = fetchDescriptorForCategories(income: income)
        return results(for: descriptor)
    }

    func getSuggestedNotes(searchQuery: String, category: Category?, income: Bool) -> [Transaction] {
        let trimmedQuery = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return []
        }
        var descriptor = FetchDescriptor<Transaction>()
        descriptor.sortBy = [SortDescriptor(\.date, order: .reverse)]
        descriptor.predicate = #Predicate<Transaction> { $0.income == income }

        let fetchedTransactions = results(for: descriptor)
        let filteredByCategory: [Transaction]

        if let unwrappedCategory = category {
            let categoryId = unwrappedCategory.id
            filteredByCategory = fetchedTransactions.filter { transaction in
                transaction.category?.id == categoryId
            }
        } else {
            filteredByCategory = fetchedTransactions
        }

        let transactions = filteredByCategory.filter { transaction in
            let note = transaction.wrappedNote
            return note.localizedCaseInsensitiveContains(trimmedQuery)
        }

        var seen = [Transaction]()
        let filtered = transactions.filter { entity -> Bool in
            if seen.contains(where: { $0.wrappedNote == entity.wrappedNote }) {
                return false
            } else {
                seen.append(entity)
                return true
            }
        }

        return filtered
//
//        let notes = transactions.map { $0.wrappedNote }
//
//        return Array(Set(notes))
    }

    func findCategory(withId id: UUID) throws -> Category {
        let predicate = #Predicate<Category> { $0.id == id }
        var descriptor = FetchDescriptor<Category>(predicate: predicate)
        descriptor.fetchLimit = 1
        let results = (try? mainContext.fetch(descriptor)) ?? []

        guard let foundCategory = results.first else {
            throw CustomError.notFound
        }

        return foundCategory
    }

    func getAllBudgets() -> [Budget] {
        var descriptor = FetchDescriptor<Budget>()
        descriptor.sortBy = [SortDescriptor(\.dateCreated)]
        return results(for: descriptor)
    }

    func findBudget(withId id: UUID) throws -> Budget {
        let predicate = #Predicate<Budget> { $0.id == id }
        var descriptor = FetchDescriptor<Budget>(predicate: predicate)
        descriptor.fetchLimit = 1
        let results = (try? mainContext.fetch(descriptor)) ?? []

        guard let foundBudget = results.first else {
            throw CustomError.notFound
        }

        return foundBudget
    }

    func categoryCheck(name: String, emoji: String, income: Bool) -> (error: CategoryError, order: Int64) {
        if name.trimmingCharacters(in: .whitespacesAndNewlines) == "" && emoji == "" {
            return (CategoryError.incomplete, 0)
        } else if name.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            return (CategoryError.missingName, 0)
        } else if emoji == "" {
            return (CategoryError.missingEmoji, 0)
        }

        if income {
            let descriptor = fetchDescriptorForCategories(income: true)
            let incomeCategories = results(for: descriptor)

            var emojiArray = [String]()
            var nameArray = [String]()

            incomeCategories.forEach { category in
                emojiArray.append(category.wrappedEmoji)
                nameArray.append(category.wrappedName)
            }

            if emojiArray.contains(emoji) && nameArray.contains(name) {
                return (CategoryError.duplicate, 0)
            } else if emojiArray.contains(emoji) {
                return (CategoryError.duplicateEmoji, 0)
            } else if nameArray.contains(name) {
                return (CategoryError.duplicateName, 0)
            } else {
                let newItemOrder = (incomeCategories.last?.order ?? 0) + 1
                return (CategoryError.none, newItemOrder)
            }
        } else {
            let descriptor = fetchDescriptorForCategories(income: false)
            let expenseCategories = results(for: descriptor)

            var emojiArray = [String]()
            var nameArray = [String]()

            expenseCategories.forEach { category in
                emojiArray.append(category.wrappedEmoji)
                nameArray.append(category.wrappedName)
            }

            if emojiArray.contains(emoji) && nameArray.contains(name) {
                return (CategoryError.duplicate, 0)
            } else if emojiArray.contains(emoji) {
                return (CategoryError.duplicateEmoji, 0)
            } else if nameArray.contains(name) {
                return (CategoryError.duplicateName, 0)
            } else {
                let newItemOrder = (expenseCategories.last?.order ?? 0) + 1
                return (CategoryError.none, newItemOrder)
            }
        }
    }

    func categoryCheckEdit(name: String, emoji: String, toEdit: Category) -> (error: CategoryError, order: Int64) {
        if name.trimmingCharacters(in: .whitespacesAndNewlines) == "" && emoji == "" {
            return (CategoryError.incomplete, 0)
        } else if name.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            return (CategoryError.missingName, 0)
        } else if emoji == "" {
            return (CategoryError.missingEmoji, 0)
        }

        if toEdit.income {
            let descriptor = fetchDescriptorForCategories(income: true)
            var incomeCategories = results(for: descriptor)

            if let position = incomeCategories.firstIndex(of: toEdit) {
                incomeCategories.remove(at: position)
            }

            var emojiArray = [String]()
            var nameArray = [String]()

            incomeCategories.forEach { category in
                emojiArray.append(category.wrappedEmoji)
                nameArray.append(category.wrappedName)
            }

            if emojiArray.contains(emoji) && nameArray.contains(name) {
                return (CategoryError.duplicate, 0)
            } else if emojiArray.contains(emoji) {
                return (CategoryError.duplicateEmoji, 0)
            } else if nameArray.contains(name) {
                return (CategoryError.duplicateName, 0)
            } else {
                let newItemOrder = (incomeCategories.last?.order ?? 0) + 1
                return (CategoryError.none, newItemOrder)
            }
        } else {
            let descriptor = fetchDescriptorForCategories(income: false)
            var expenseCategories = results(for: descriptor)

            if let position = expenseCategories.firstIndex(of: toEdit) {
                expenseCategories.remove(at: position)
            }

            var emojiArray = [String]()
            var nameArray = [String]()

            expenseCategories.forEach { category in
                emojiArray.append(category.wrappedEmoji)
                nameArray.append(category.wrappedName)
            }

            if emojiArray.contains(emoji) && nameArray.contains(name) {
                return (CategoryError.duplicate, 0)
            } else if emojiArray.contains(emoji) {
                return (CategoryError.duplicateEmoji, 0)
            } else if nameArray.contains(name) {
                return (CategoryError.duplicateName, 0)
            } else {
                let newItemOrder = (expenseCategories.last?.order ?? 0) + 1
                return (CategoryError.none, newItemOrder)
            }
        }
    }

    func fetchDescriptorForBudgets() -> FetchDescriptor<Budget> {
        FetchDescriptor<Budget>()
    }

    func fetchDescriptorForMainBudget() -> FetchDescriptor<MainBudget> {
        FetchDescriptor<MainBudget>()
    }

    func fetchDescriptorForLogView(type: Int, optionalIncome: Bool?, categoryFilters: [Category] = []) -> FetchDescriptor<Transaction> {
        var descriptor = FetchDescriptor<Transaction>()

        var calendar = Calendar(identifier: .gregorian)

        calendar.firstWeekday = UserDefaults(suiteName: "group.farm.poplar.budgetthing")!.integer(forKey: "firstWeekday")
        calendar.minimumDaysInFirstWeek = 4

        let now = Date.now

        // all time
        if type == 5 {
            if let income = optionalIncome {
                descriptor.predicate = #Predicate<Transaction> {
                    $0.income == income && $0.date <= now
                }
            } else {
                descriptor.predicate = #Predicate<Transaction> { $0.date <= now }
            }

            return descriptor
        }

        let startDate: Date

        if type == 1 {
            let today = calendar.startOfDay(for: now)
            startDate = today
        } else if type == 2 {
            let dateComponents = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: now)
            let thisWeek = calendar.date(from: dateComponents)!
            startDate = thisWeek
        } else if type == 3 {
            let startOfMonth = UserDefaults(suiteName: "group.farm.poplar.budgetthing")!.integer(forKey: "firstDayOfMonth")

            let thisMonth = getStartOfMonth(startDay: startOfMonth)
            startDate = thisMonth
        } else {
            let dateComponents = calendar.dateComponents([.year], from: now)
            let thisYear = calendar.date(from: dateComponents)!
            startDate = thisYear
        }

        if let income = optionalIncome {
            descriptor.predicate = #Predicate<Transaction> {
                $0.date >= startDate && $0.date <= now && $0.income == income
            }
        } else {
            descriptor.predicate = #Predicate<Transaction> {
                $0.date >= startDate && $0.date <= now
            }
        }

        return descriptor
    }

    func getShortcutInsights(type: Int, timeframe: Int, optionalIncome: Bool?, categories: [Category]) -> Double {
        let descriptor = fetchDescriptorForLogView(type: timeframe, optionalIncome: optionalIncome, categoryFilters: categories)
        let resultsTransactions = results(for: descriptor)
        let allTransactions: [Transaction]

        if categories.isEmpty {
            allTransactions = resultsTransactions
        } else {
            let categoryIds = Set(categories.compactMap { $0.id })
            allTransactions = resultsTransactions.filter { transaction in
                guard let categoryId = transaction.category?.id else {
                    return false
                }
                return categoryIds.contains(categoryId)
            }
        }

        if type == 1 {
            var total = 0.0

            allTransactions.forEach { transaction in
                if transaction.income {
                    total += transaction.amount
                } else {
                    total -= transaction.amount
                }
            }

            return total
        } else {
            var total = 0.0

            allTransactions.forEach { transaction in
                total += transaction.amount
            }

            return total
        }
    }

    func getLogViewTotalSpent(type: Int) -> Double {
        let descriptor = fetchDescriptorForLogView(type: type, optionalIncome: false)
        let allTransactions = results(for: descriptor)

        var total = 0.0

        allTransactions.forEach { transaction in
            total += transaction.amount
        }

        return total
    }

    func getLogViewTotalIncome(type: Int) -> Double {
        let descriptor = fetchDescriptorForLogView(type: type, optionalIncome: true)
        let allTransactions = results(for: descriptor)

        var total = 0.0

        allTransactions.forEach { transaction in
            total += transaction.amount
        }

        return total
    }

    func getLogViewTotalNet(type: Int) -> (value: Double, positive: Bool) {
        let descriptor = fetchDescriptorForLogView(type: type, optionalIncome: nil)
        let allTransactions = results(for: descriptor)

        var total = 0.0

        allTransactions.forEach { transaction in
            if transaction.income {
                total += transaction.amount
            } else {
                total -= transaction.amount
            }
        }

        if total >= 0 {
            return (total, true)
        } else {
            return (abs(total), false)
        }
    }

    func getLineGraphDataNet(type: Int) -> [LineGraphDataPoint] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date.now)

        let descriptor = fetchDescriptorForLineGraph(optionalIncome: nil)
        let transactions = results(for: descriptor)

        var holdingDataPoints = [LineGraphDataPoint]()
        var totalForDay = 0.0

        if type < 3 {
            let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: today)!
            var changingDate = Calendar.current.date(byAdding: .second, value: 86399, to: lastWeek)!

            for transaction in transactions {
                if transaction.wrappedDate < changingDate {
                    if transaction.income {
                        totalForDay += transaction.amount
                    } else {
                        totalForDay -= transaction.amount
                    }
                } else {
                    let newData = LineGraphDataPoint(date: changingDate, amount: totalForDay)
                    holdingDataPoints.append(newData)
                    changingDate = Calendar.current.date(byAdding: .day, value: 1, to: changingDate)!

                    while transaction.wrappedDate > changingDate {
                        let anotherNewData = LineGraphDataPoint(date: changingDate, amount: totalForDay)
                        holdingDataPoints.append(anotherNewData)
                        changingDate = Calendar.current.date(byAdding: .day, value: 1, to: changingDate)!
                    }

                    if transaction.income {
                        totalForDay += transaction.amount
                    } else {
                        totalForDay -= transaction.amount
                    }
                }
            }

            let newData = LineGraphDataPoint(date: changingDate, amount: totalForDay)
            holdingDataPoints.append(newData)

            if changingDate < today {
                changingDate = Calendar.current.date(byAdding: .day, value: 1, to: changingDate)!

                while changingDate < today {
                    let anotherNewData = LineGraphDataPoint(date: changingDate, amount: totalForDay)
                    holdingDataPoints.append(anotherNewData)
                    changingDate = Calendar.current.date(byAdding: .day, value: 1, to: changingDate)!
                }

                let finalDate = LineGraphDataPoint(date: today, amount: totalForDay)
                holdingDataPoints.append(finalDate)
            }
        } else if type == 3 {
            let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: today)!
            var changingDate = Calendar.current.date(byAdding: .second, value: 86399, to: lastMonth)!

            for transaction in transactions {
                if transaction.wrappedDate < changingDate {
                    if transaction.income {
                        totalForDay += transaction.amount
                    } else {
                        totalForDay -= transaction.amount
                    }
                } else {
                    let newData = LineGraphDataPoint(date: changingDate, amount: totalForDay)
                    holdingDataPoints.append(newData)
                    changingDate = Calendar.current.date(byAdding: .day, value: 1, to: changingDate)!

                    while transaction.wrappedDate > changingDate {
                        let anotherNewData = LineGraphDataPoint(date: changingDate, amount: totalForDay)
                        holdingDataPoints.append(anotherNewData)
                        changingDate = Calendar.current.date(byAdding: .day, value: 1, to: changingDate)!
                    }

                    if transaction.income {
                        totalForDay += transaction.amount
                    } else {
                        totalForDay -= transaction.amount
                    }
                }
            }

            let newData = LineGraphDataPoint(date: changingDate, amount: totalForDay)
            holdingDataPoints.append(newData)

            if changingDate < today {
                changingDate = Calendar.current.date(byAdding: .day, value: 1, to: changingDate)!

                while changingDate < today {
                    let anotherNewData = LineGraphDataPoint(date: changingDate, amount: totalForDay)
                    holdingDataPoints.append(anotherNewData)
                    changingDate = Calendar.current.date(byAdding: .day, value: 1, to: changingDate)!
                }

                let finalDate = LineGraphDataPoint(date: today, amount: totalForDay)
                holdingDataPoints.append(finalDate)
            }
        } else if type == 4 {
            let dateComponents = calendar.dateComponents([.month, .year], from: Date.now)
            let thisMonth = calendar.date(from: dateComponents)!
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: thisMonth)!
            var changingDate = calendar.date(byAdding: .year, value: -1, to: nextMonth)!

            for transaction in transactions {
                if transaction.wrappedDate < changingDate {
                    if transaction.income {
                        totalForDay += transaction.amount
                    } else {
                        totalForDay -= transaction.amount
                    }
                } else {
                    let dataDate = calendar.date(byAdding: .day, value: -1, to: changingDate)!
                    let newData = LineGraphDataPoint(date: dataDate, amount: totalForDay)
                    holdingDataPoints.append(newData)
                    changingDate = Calendar.current.date(byAdding: .month, value: 1, to: changingDate)!

                    while transaction.wrappedDate > changingDate {
                        let newDataDate = calendar.date(byAdding: .day, value: -1, to: changingDate)!
                        let anotherNewData = LineGraphDataPoint(date: newDataDate, amount: totalForDay)
                        holdingDataPoints.append(anotherNewData)
                        changingDate = Calendar.current.date(byAdding: .month, value: 1, to: changingDate)!
                    }

                    if transaction.income {
                        totalForDay += transaction.amount
                    } else {
                        totalForDay -= transaction.amount
                    }
                }
            }

            let dataDate = calendar.date(byAdding: .day, value: -1, to: changingDate)!
            let newData = LineGraphDataPoint(date: dataDate, amount: totalForDay)
            holdingDataPoints.append(newData)

            if changingDate < nextMonth {
                changingDate = Calendar.current.date(byAdding: .month, value: 1, to: changingDate)!

                while changingDate < nextMonth {
                    let anotherDataDate = calendar.date(byAdding: .day, value: -1, to: changingDate)!
                    let anotherNewData = LineGraphDataPoint(date: anotherDataDate, amount: totalForDay)
                    holdingDataPoints.append(anotherNewData)
                    changingDate = Calendar.current.date(byAdding: .month, value: 1, to: changingDate)!
                }

                let finalDate = LineGraphDataPoint(date: today, amount: totalForDay)
                holdingDataPoints.append(finalDate)
            }
        }

        return holdingDataPoints
    }

    func getLineGraphData(income: Bool, type: Int) -> [LineGraphDataPoint] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date.now)

        let descriptor = fetchDescriptorForLineGraph(optionalIncome: income)
        let transactions = results(for: descriptor)

        var holdingDataPoints = [LineGraphDataPoint]()
        var totalForDay = 0.0

        if type < 3 {
            let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: today)!
            var changingDate = Calendar.current.date(byAdding: .second, value: 86399, to: lastWeek)!

            for transaction in transactions {
                if transaction.wrappedDate > lastWeek {
                    if transaction.wrappedDate < changingDate {
                        totalForDay += transaction.wrappedAmount
                    } else {
                        let newData = LineGraphDataPoint(date: changingDate, amount: totalForDay)
                        holdingDataPoints.append(newData)
                        changingDate = Calendar.current.date(byAdding: .day, value: 1, to: changingDate)!
                        totalForDay = 0

                        while transaction.wrappedDate > changingDate {
                            let anotherNewData = LineGraphDataPoint(date: changingDate, amount: 0)
                            holdingDataPoints.append(anotherNewData)
                            changingDate = Calendar.current.date(byAdding: .day, value: 1, to: changingDate)!
                        }

                        totalForDay += transaction.wrappedAmount
                    }
                }
            }

            let newData = LineGraphDataPoint(date: changingDate, amount: totalForDay)
            holdingDataPoints.append(newData)
            totalForDay = 0

            if changingDate < today {
                changingDate = Calendar.current.date(byAdding: .day, value: 1, to: changingDate)!

                while changingDate < today {
                    let anotherNewData = LineGraphDataPoint(date: changingDate, amount: 0)
                    holdingDataPoints.append(anotherNewData)
                    changingDate = Calendar.current.date(byAdding: .day, value: 1, to: changingDate)!
                }

                let finalDate = LineGraphDataPoint(date: today, amount: totalForDay)
                holdingDataPoints.append(finalDate)
            }
        } else if type == 3 {
            let lastMonth = Calendar.current.date(byAdding: .month, value: -1, to: today)!
            var changingDate = Calendar.current.date(byAdding: .second, value: 86399, to: lastMonth)!

            for transaction in transactions {
                if transaction.wrappedDate > lastMonth {
                    if transaction.wrappedDate < changingDate {
                        totalForDay += transaction.wrappedAmount
                    } else {
                        let newData = LineGraphDataPoint(date: changingDate, amount: totalForDay)
                        holdingDataPoints.append(newData)
                        changingDate = Calendar.current.date(byAdding: .day, value: 1, to: changingDate)!
                        totalForDay = 0

                        while transaction.wrappedDate > changingDate {
                            let anotherNewData = LineGraphDataPoint(date: changingDate, amount: 0)
                            holdingDataPoints.append(anotherNewData)
                            changingDate = Calendar.current.date(byAdding: .day, value: 1, to: changingDate)!
                        }

                        totalForDay += transaction.wrappedAmount
                    }
                }
            }

            let newData = LineGraphDataPoint(date: changingDate, amount: totalForDay)
            holdingDataPoints.append(newData)

            if changingDate < today {
                changingDate = Calendar.current.date(byAdding: .day, value: 1, to: changingDate)!

                while changingDate < today {
                    let anotherNewData = LineGraphDataPoint(date: changingDate, amount: 0)
                    holdingDataPoints.append(anotherNewData)
                    changingDate = Calendar.current.date(byAdding: .day, value: 1, to: changingDate)!
                }

                let finalDate = LineGraphDataPoint(date: today, amount: 0)
                holdingDataPoints.append(finalDate)
            }
        } else if type == 4 {
            let dateComponents = calendar.dateComponents([.month, .year], from: Date.now)
            let thisMonth = calendar.date(from: dateComponents)!
            let thisMonthLastYear = calendar.date(byAdding: .year, value: -1, to: thisMonth)!
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: thisMonth)!
            var changingDate = calendar.date(byAdding: .year, value: -1, to: nextMonth)!

            for transaction in transactions {
                if transaction.wrappedDate > thisMonthLastYear {
                    if transaction.wrappedDate < changingDate {
                        totalForDay += transaction.wrappedAmount
                    } else {
                        let dataDate = calendar.date(byAdding: .day, value: -1, to: changingDate)!
                        let newData = LineGraphDataPoint(date: dataDate, amount: totalForDay)
                        holdingDataPoints.append(newData)
                        changingDate = Calendar.current.date(byAdding: .month, value: 1, to: changingDate)!
                        totalForDay = 0

                        while transaction.wrappedDate > changingDate {
                            let newDataDate = calendar.date(byAdding: .day, value: -1, to: changingDate)!
                            let anotherNewData = LineGraphDataPoint(date: newDataDate, amount: 0)
                            holdingDataPoints.append(anotherNewData)
                            changingDate = Calendar.current.date(byAdding: .month, value: 1, to: changingDate)!
                        }

                        totalForDay += transaction.wrappedAmount
                    }
                }
            }

            let dataDate = calendar.date(byAdding: .day, value: -1, to: changingDate)!
            let newData = LineGraphDataPoint(date: dataDate, amount: totalForDay)
            holdingDataPoints.append(newData)

            if changingDate < nextMonth {
                changingDate = Calendar.current.date(byAdding: .month, value: 1, to: changingDate)!

                while changingDate < nextMonth {
                    let anotherDataDate = calendar.date(byAdding: .day, value: -1, to: changingDate)!
                    let anotherNewData = LineGraphDataPoint(date: anotherDataDate, amount: 0)
                    holdingDataPoints.append(anotherNewData)
                    changingDate = Calendar.current.date(byAdding: .month, value: 1, to: changingDate)!
                }

                let finalDate = LineGraphDataPoint(date: today, amount: 0)
                holdingDataPoints.append(finalDate)
            }
        }

        return holdingDataPoints
    }

    func getBudgetLeftover(budget: Budget? = nil, overallBudget: MainBudget? = nil) -> Double {
        let descriptor: FetchDescriptor<Transaction>
        let budgetAmount: Double

        if let unwrappedOverallBudget = overallBudget {
            descriptor = fetchDescriptorForMainBudgetTransactions(budget: unwrappedOverallBudget)
            budgetAmount = unwrappedOverallBudget.amount
        } else if let unwrappedBudget = budget {
            descriptor = fetchDescriptorForBudgetTransactions(budget: unwrappedBudget)
            budgetAmount = unwrappedBudget.amount
        } else {
            descriptor = FetchDescriptor<Transaction>()
            budgetAmount = 0
        }

        let transactions = results(for: descriptor)
        let filteredTransactions: [Transaction]

        if let categoryId = budget?.category?.id {
            filteredTransactions = transactions.filter { $0.category?.id == categoryId }
        } else {
            filteredTransactions = transactions
        }

        var totalSpent = 0.0

        filteredTransactions.forEach { transaction in
            totalSpent += transaction.wrappedAmount
        }

        return budgetAmount - totalSpent
    }

    func fetchDescriptorForMainBudgetTransactions(budget: MainBudget) -> FetchDescriptor<Transaction> {
        let startDate = budget.startDate
        let now = Date.now
        let predicate = #Predicate<Transaction> {
            $0.date >= startDate && $0.date <= now && $0.income == false
        }
        return FetchDescriptor(predicate: predicate)
    }

    func fetchDescriptorForBudgetTransactions(budget: Budget) -> FetchDescriptor<Transaction> {
        let startDate = budget.startDate
        let now = Date.now
        let predicate = #Predicate<Transaction> {
            $0.date >= startDate &&
            $0.date <= now &&
            $0.income == false
        }
        return FetchDescriptor(predicate: predicate)
    }

    func fetchDescriptorForLineGraph(optionalIncome: Bool?) -> FetchDescriptor<Transaction> {
        var descriptor = FetchDescriptor<Transaction>()
        descriptor.sortBy = [SortDescriptor(\.date)]

        if let income = optionalIncome {
            descriptor.predicate = #Predicate<Transaction> { $0.income == income }
        }

        return descriptor
    }

    func fetchDescriptorForLogViewCategoryFilter(income: Bool) -> FetchDescriptor<Transaction> {
        let predicate = #Predicate<Transaction> { $0.income == income }
        return FetchDescriptor(predicate: predicate)
    }

    func getInsights(type: Int, date: Date, income: Bool) -> (amount: Double, maximum: Double, average: Double, numberOfDays: Int, dates: [Date], dateDictionary: [Date: Double]) {
        let descriptor = fetchDescriptorForInsights(type: type, date: date, income: income)
        let currentTransactions = results(for: descriptor)

        var iterativeDate = date

        if type == 1 {
            // tracking dates
            var dates = [Date]()
            var nextDate = date

            // calendar initialization
            var calendar = Calendar(identifier: .gregorian)

            calendar.firstWeekday = UserDefaults(suiteName: "group.farm.poplar.budgetthing")!.integer(forKey: "firstWeekday")
            calendar.minimumDaysInFirstWeek = 4

            var dictionary = [Date: Double]()
            var totalForWeek = 0.0
            var maximum = 0.0
            var numberOfDays = 0
            var weekAverage = 0.0

            for _ in 1 ... 7 {
                nextDate = calendar.date(byAdding: .day, value: 1, to: iterativeDate)!

                let holding = currentTransactions.filter {
                    $0.wrappedDate >= iterativeDate && $0.wrappedDate < nextDate
                }

                var total = 0.0

                holding.forEach { transaction in
                    total += transaction.wrappedAmount
                }

                totalForWeek += total

                dictionary[iterativeDate] = total

                if total > maximum {
                    maximum = total
                }

                if total != 0 {
                    numberOfDays += 1
                }

                dates.append(iterativeDate)
                iterativeDate = nextDate
            }

            let dateComponents = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: Date.now)

            let currentWeek = calendar.date(from: dateComponents)!

            if currentWeek == date {
//                let fromDate = Calendar.current.startOfDay(for: currentWeek)
//                let toDate = Calendar.current.startOfDay(for: Date.now)
                let numberOfDays = Calendar.current.dateComponents([.day], from: currentWeek, to: Date.now)

                weekAverage = totalForWeek / Double((numberOfDays.day! + 1))
            } else {
                weekAverage = totalForWeek / 7
            }

            return (totalForWeek, maximum, weekAverage, numberOfDays, dates, dictionary)
        } else if type == 2 {
            // tracking dates
            var dates = [Date]()
            var nextDate = date

            let calendar = Calendar(identifier: .gregorian)
            let range = calendar.range(of: .day, in: .month, for: iterativeDate)!

            var dictionary = [Date: Double]()
            var totalForMonth = 0.0
            var maximum = 0.0
            var numberOfDays = 0
            var monthAverage = 0.0

            for _ in 1 ... range.count {
                nextDate = calendar.date(byAdding: .day, value: 1, to: iterativeDate)!

                let holding = currentTransactions.filter {
                    $0.wrappedDate >= iterativeDate && $0.wrappedDate < nextDate
                }

                var total = 0.0

                holding.forEach { transaction in
                    total += transaction.wrappedAmount
                }

                totalForMonth += total

                dictionary[iterativeDate] = total

                if total > maximum {
                    maximum = total
                }

                if total != 0 {
                    numberOfDays += 1
                }

                dates.append(iterativeDate)
                iterativeDate = nextDate
            }

            let next = calendar.date(byAdding: .month, value: 1, to: date) ?? Date.now

            if next > Date.now {
                let numDays = Calendar.current.dateComponents([.day], from: date, to: Date.now)

                monthAverage = totalForMonth / Double((numDays.day! + 1))
            } else {
                monthAverage = totalForMonth / Double(range.count)
            }

            return (totalForMonth, maximum, monthAverage, numberOfDays, dates, dictionary)
        } else if type == 3 {
            // trackin dates
            var dates = [Date]()
            var nextDate = date

            let calendar = Calendar(identifier: .gregorian)

            var dictionary = [Date: Double]()
            var totalForYear = 0.0
            var maximum = 0.0
            var numberOfDays = 0
            var monthAverage = 0.0

            for _ in 1 ... 12 {
                nextDate = calendar.date(byAdding: .month, value: 1, to: iterativeDate)!

                let holding = currentTransactions.filter {
                    $0.wrappedDate >= iterativeDate && $0.wrappedDate < nextDate
                }

                var total = 0.0

                holding.forEach { transaction in
                    total += transaction.wrappedAmount
                }

                totalForYear += total

                dictionary[iterativeDate] = total

                if total > maximum {
                    maximum = total
                }

                if total != 0 {
                    numberOfDays += 1
                }

                dates.append(iterativeDate)
                iterativeDate = nextDate
            }

            let dateComponents = calendar.dateComponents([.year], from: Date.now)

            let currentYear = calendar.date(from: dateComponents)!

            if currentYear == date {
                let fromDate = Calendar.current.startOfDay(for: currentYear)
                let toDate = Calendar.current.startOfDay(for: Date.now)
                let numDays = Calendar.current.dateComponents([.month], from: fromDate, to: toDate)

                monthAverage = totalForYear / Double((numDays.month! + 1))
            } else {
                monthAverage = totalForYear / 12
            }

            return (totalForYear, maximum, monthAverage, numberOfDays, dates, dictionary)
        } else {
            return (0, 0, 0, 0, [Date](), [Date: Double]())
        }
    }

    func fetchDescriptorForInsights(type: Int, date: Date, income: Bool? = nil) -> FetchDescriptor<Transaction> {
        var descriptor = FetchDescriptor<Transaction>()

        var calendar = Calendar(identifier: .gregorian)

        calendar.firstWeekday = UserDefaults(suiteName: "group.farm.poplar.budgetthing")!.integer(forKey: "firstWeekday")
        calendar.minimumDaysInFirstWeek = 4

        let startDate = date
        let endDate: Date

        if type == 1 {
            if calendar.isDate(date, equalTo: Date.now, toGranularity: .weekOfYear) {
                endDate = Date.now
            } else {
                let next = calendar.date(byAdding: .day, value: 7, to: date) ?? Date.now
                endDate = next
            }
        } else if type == 2 {
            let next = calendar.date(byAdding: .month, value: 1, to: date) ?? Date.now

//            let endOfPeriod = calendar.date(byAdding: .day, value: -1, to: next) ?? Date.now
//
            if next > Date.now {
                endDate = Date.now
            } else {
                endDate = next
            }
//
//            if calendar.isDate(date, equalTo: Date.now, toGranularity: .month) {
//                endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), Date.now as CVarArg)
//            } else {
//
//                endPredicate = NSPredicate(format: "%K < %@", #keyPath(Transaction.date), next as CVarArg)
//            }
        } else {
            if calendar.isDate(date, equalTo: Date.now, toGranularity: .year) {
                endDate = Date.now
            } else {
                let next = calendar.date(byAdding: .year, value: 1, to: date) ?? Date.now
                endDate = next
            }
        }

        if let unwrappedIncome = income {
            descriptor.predicate = #Predicate<Transaction> {
                $0.date >= startDate && $0.date < endDate && $0.income == unwrappedIncome
            }
        } else {
            descriptor.predicate = #Predicate<Transaction> {
                $0.date >= startDate && $0.date < endDate
            }
        }
        return descriptor
    }

    func getInsightsSummary(type: Int, date: Date) -> (spent: Double, income: Double, net: Double, positive: Bool, average: Double) {
        let descriptor = fetchDescriptorForInsights(type: type, date: date)
        let currentTransactions = results(for: descriptor)

        var holdingSpent = 0.0
        var holdingIncome = 0.0

        currentTransactions.forEach { transaction in
            if transaction.income {
                holdingIncome += transaction.amount
            } else {
                holdingSpent += transaction.amount
            }
        }

        let net = holdingIncome - holdingSpent
        let absoluteNet: Double
        let positive: Bool

        if net < 0 {
            absoluteNet = abs(net)
            positive = false
        } else {
            absoluteNet = net
            positive = true
        }

        let calendar = Calendar.current

        if type == 1 {
            if calendar.isDate(date, equalTo: Date.now, toGranularity: .weekOfYear) {
                let numberOfDays = Calendar.current.dateComponents([.day], from: date, to: Date.now)

                return (holdingSpent, holdingIncome, absoluteNet, positive, abs(net) / Double(numberOfDays.day! + 1))
            } else {
                return (holdingSpent, holdingIncome, absoluteNet, positive, abs(net) / 7)
            }
        } else if type == 2 {
            let next = calendar.date(byAdding: .month, value: 1, to: date) ?? Date.now

            if next > Date.now {
                let numDays = Calendar.current.dateComponents([.day], from: date, to: Date.now)

                return (holdingSpent, holdingIncome, absoluteNet, positive, abs(net) / Double(numDays.day! + 1))
            } else {
                let numDays = Calendar.current.dateComponents([.day], from: date, to: next)

                return (holdingSpent, holdingIncome, absoluteNet, positive, abs(net) / Double(numDays.day! + 1))
            }
//            if calendar.isDate(date, equalTo: Date.now, toGranularity: .month) {
//                let numDays = Calendar.current.dateComponents([.day], from: date, to: Date.now)
//
//                return (holdingSpent, holdingIncome, absoluteNet, positive, abs(net) / Double(numDays.day! + 1))
//            } else {
//
//                let range = calendar.range(of: .day, in: .month, for: date)!
//                let numDays = range.count
//
//                return (holdingSpent, holdingIncome, absoluteNet, positive, abs(net) / Double(numDays))
//            }
        } else {
            if calendar.isDate(date, equalTo: Date.now, toGranularity: .year) {
                let numDays = Calendar.current.dateComponents([.month], from: date, to: Date.now)

                return (holdingSpent, holdingIncome, absoluteNet, positive, abs(net) / Double(numDays.month! + 1))
            } else {
                return (holdingSpent, holdingIncome, absoluteNet, positive, abs(net) / 12)
            }
        }
    }

    func fetchDescriptorForWidgetInsights(type: InsightsTimePeriod, income: Bool) -> (descriptor: FetchDescriptor<Transaction>, date: Date) {
        var descriptor = FetchDescriptor<Transaction>()

        var calendar = Calendar(identifier: .gregorian)

        calendar.firstWeekday = UserDefaults(suiteName: "group.farm.poplar.budgetthing")!.integer(forKey: "firstWeekday")
        calendar.minimumDaysInFirstWeek = 4

        let now = Date.now
        let startDate: Date
        let endDate = now

        switch type {
        case .unknown:
            startDate = now
            descriptor.predicate = #Predicate<Transaction> { $0.date < now && $0.income == income }
        case .week:
            let dateComponents = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: now)

            startDate = calendar.date(from: dateComponents)!
            descriptor.predicate = #Predicate<Transaction> {
                $0.date >= startDate && $0.date < endDate && $0.income == income
            }
        case .month:
            let startOfMonth = UserDefaults(suiteName: "group.farm.poplar.budgetthing")!.integer(forKey: "firstDayOfMonth")

            startDate = getStartOfMonth(startDay: startOfMonth)
            descriptor.predicate = #Predicate<Transaction> {
                $0.date >= startDate && $0.date < endDate && $0.income == income
            }
        case .year:
            let dateComponents = calendar.dateComponents([.year], from: now)

            startDate = calendar.date(from: dateComponents)!
            descriptor.predicate = #Predicate<Transaction> {
                $0.date >= startDate && $0.date < endDate && $0.income == income
            }
        }

        if type != .unknown {
            descriptor.sortBy = [SortDescriptor(\.date, order: .reverse)]
        }

        return (descriptor, startDate)
    }

    func fetchDescriptorForRecentTransactionsWithCount(type: TimePeriod, count: Int) -> FetchDescriptor<Transaction> {
        var descriptor = FetchDescriptor<Transaction>()

        var calendar = Calendar(identifier: .gregorian)

        calendar.firstWeekday = UserDefaults(suiteName: "group.farm.poplar.budgetthing")!.integer(forKey: "firstWeekday")
        calendar.minimumDaysInFirstWeek = 4

        let now = Date.now

        switch type {
        case .unknown:
            return descriptor
        case .day:
            let today = calendar.startOfDay(for: now)
            descriptor.predicate = #Predicate<Transaction> { $0.date >= today && $0.date < now }
            descriptor.sortBy = [SortDescriptor(\.date, order: .reverse)]
            descriptor.fetchLimit = count
            return descriptor
        case .week:
            let dateComponents = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: now)

            let thisWeek = calendar.date(from: dateComponents)!
            descriptor.predicate = #Predicate<Transaction> { $0.date >= thisWeek && $0.date < now }
            descriptor.sortBy = [SortDescriptor(\.date, order: .reverse)]
            descriptor.fetchLimit = count
            return descriptor
        case .month:
            let dateComponents = calendar.dateComponents([.month, .year], from: now)

            let thisMonth = calendar.date(from: dateComponents)!
            descriptor.predicate = #Predicate<Transaction> { $0.date >= thisMonth && $0.date < now }
            descriptor.sortBy = [SortDescriptor(\.date, order: .reverse)]
            descriptor.fetchLimit = count
            return descriptor
        case .year:
            let dateComponents = calendar.dateComponents([.year], from: now)

            let thisYear = calendar.date(from: dateComponents)!
            descriptor.predicate = #Predicate<Transaction> { $0.date >= thisYear && $0.date < now }
            descriptor.sortBy = [SortDescriptor(\.date, order: .reverse)]
            descriptor.fetchLimit = count
            return descriptor
        }
    }

    func fetchRequestForMainBudgetWidget() -> (found: Bool, totalSpent: Double, budgetAmount: Double, percentage: Double, type: Int, startDate: Date) {
        let holding = results(for: fetchDescriptorForMainBudget())

        if let budget = holding.first {
            let descriptor = fetchDescriptorForMainBudgetTransactions(budget: budget)
//
            let transactions = results(for: descriptor)

            var holdingTotal = 0.0
            transactions.forEach { transaction in
                holdingTotal += transaction.wrappedAmount
            }

            let percentageOfDays: Double

            let calendar = Calendar.current

            if budget.type == 1 {
                let components = calendar.dateComponents([.minute], from: budget.startDate, to: Date.now)
                percentageOfDays = Double(components.minute ?? 0) / 1440
            } else {
                let components1 = calendar.dateComponents([.day], from: budget.startDate, to: budget.endDate)
                let numberOfDays = components1.day ?? 0

                let components2 = calendar.dateComponents([.day], from: budget.startDate, to: Date.now)
                let numberOfDaysPast = components2.day ?? 0

                percentageOfDays = numberOfDays == 0 ? 0 : Double(numberOfDaysPast) / Double(numberOfDays)
            }

            return (true, holdingTotal, budget.amount, percentageOfDays, Int(budget.type), budget.startDate)

        } else {
            return (false, 0, 0, 0, 0, Date.now)
        }
    }

    func results<T: PersistentModel>(for descriptor: FetchDescriptor<T>, context: ModelContext? = nil) -> [T] {
        let context = context ?? mainContext
        return (try? context.fetch(descriptor)) ?? []
    }
}

struct LineGraphDataPoint: Equatable {
    let date: Date
    let amount: Double

    var dateString: String {
        let dateFormatter = DateFormatter()

        dateFormatter.dateFormat = "d MMM"

        return dateFormatter.string(from: date)
    }

    var monthString: String {
        let dateFormatter = DateFormatter()

        dateFormatter.dateFormat = "MMM yy"

        return dateFormatter.string(from: date)
    }

    var amountString: String {
        if abs(amount) < 1000 {
            return String(format: "%.2f", amount)
        } else {
            return String(format: "%.0f", amount)
        }
    }
}

func getStartOfMonth(startDay: Int) -> Date {
    let calendar = Calendar.current

    guard startDay > 0 && startDay <= calendar.maximumRange(of: .day)!.upperBound else {
        let dateComponents = calendar.dateComponents([.month, .year], from: Date.now)
        return calendar.date(from: dateComponents) ?? Date.now
    }

    let today = calendar.startOfDay(for: Date.now)
    let currentDay = calendar.component(.day, from: today)

    var startComponents = DateComponents()
    startComponents.month = currentDay >= startDay ? 0 : -1

    startComponents.day = startDay - currentDay

    return calendar.date(byAdding: startComponents, to: today) ?? Date.now
}

func calculateStartOfMonthPeriod(earliestDate: Date, startOfMonthDay: Int) -> Date {
    var components = Calendar.current.dateComponents([.year, .month, .day], from: earliestDate)
    components.day = startOfMonthDay

    let startOfMonth = Calendar.current.date(from: components) ?? Date.now
    return (earliestDate < startOfMonth) ? (Calendar.current.date(byAdding: .month, value: -1, to: startOfMonth) ?? Date.now) : startOfMonth
}
