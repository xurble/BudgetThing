//
//  ShortcutsEntities.swift
//  dime
//
//  Created by Rafael Soh on 1/8/23.
//

import AppIntents
import CoreData
import Foundation

// @available(iOS 16, *)
// struct IncomeCategoryEntity: AppEntity, Identifiable {
//    static var typeDisplayRepresentation: TypeDisplayRepresentation = TypeDisplayRepresentation(name: "Income Category")
//    static let defaultQuery: IncomeCategoryQuery = IncomeCategoryQuery()
//
//
//    var id: UUID
//
//    @Property(title: "Name")
//    var name: String
//
//    @Property(title: "Emoji")
//    var emoji: String
//
//    var displayRepresentation: DisplayRepresentation {
//        DisplayRepresentation(title: "\(emoji)  \(name)")
//    }
//
//    init(id: UUID, name: String, emoji: String) {
//        self.id = id
//        self.name = name
//        self.emoji = emoji
//    }
//
// }
//
// @available(iOS 16, *)
// struct IncomeCategoryQuery: EntityQuery {
//    func entities(for identifiers: [IncomeCategoryEntity.ID]) async throws -> [IncomeCategoryEntity] {
//        let dataController = DataController()
//        return identifiers.compactMap { identifier in
//            if let match = try? dataController.findCategory(withId: identifier) {
//                if let id = match.id {
//                    return IncomeCategoryEntity(id: id, name: match.wrappedName, emoji: match.wrappedEmoji)
//                } else {
//                    return nil
//                }
//            } else {
//                return nil
//            }
//        }
//    }
//
//    func suggestedEntities() async throws -> [IncomeCategoryEntity] {
//        let dataController = DataController()
//        let categories = dataController.getAllCategories(income: true)
//        return categories.compactMap { category in
//            if let id = category.id {
//                return IncomeCategoryEntity(id: id, name: category.wrappedName, emoji: category.wrappedEmoji)
//            } else {
//                return nil
//            }
//        }
//    }
// }
//
// @available(iOS 16, *)
// struct ExpenseCategoryEntity: AppEntity, Identifiable {
//    static var typeDisplayRepresentation: TypeDisplayRepresentation = TypeDisplayRepresentation(name: "Expense Category")
//    static let defaultQuery: ExpenseCategoryQuery = ExpenseCategoryQuery()
//
//
//    var id: UUID
//
//    @Property(title: "Name")
//    var name: String
//
//    @Property(title: "Emoji")
//    var emoji: String
//
//    var displayRepresentation: DisplayRepresentation {
//        DisplayRepresentation(title: "\(emoji)  \(name)")
//    }
//
//    init(id: UUID, name: String, emoji: String) {
//        self.id = id
//        self.name = name
//        self.emoji = emoji
//    }
//
// }
//
// @available(iOS 16, *)
// struct ExpenseCategoryQuery: EntityQuery {
//    func entities(for identifiers: [ExpenseCategoryEntity.ID]) async throws -> [ExpenseCategoryEntity] {
//        let dataController = DataController()
//        return identifiers.compactMap { identifier in
//            if let match = try? dataController.findCategory(withId: identifier) {
//                if let id = match.id {
//                    return ExpenseCategoryEntity(id: id, name: match.wrappedName, emoji: match.wrappedEmoji)
//                } else {
//                    return nil
//                }
//            } else {
//                return nil
//            }
//        }
//    }
//
//    func suggestedEntities() async throws -> [ExpenseCategoryEntity] {
//        let dataController = DataController()
//        let categories = dataController.getAllCategories(income: true)
//        return categories.compactMap { category in
//            if let id = category.id {
//                return ExpenseCategoryEntity(id: id, name: category.wrappedName, emoji: category.wrappedEmoji)
//            } else {
//                return nil
//            }
//        }
//    }
// }

@available(iOS 16, *)
struct IncomeCategoryEntity: AppEntity, Identifiable {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = .init(name: "Category")
    typealias DefaultQueryType = IncomeCategoryQuery
    static let defaultQuery: IncomeCategoryQuery = .init()

    var id: UUID

    @Property(title: "Name")
    var name: String

    @Property(title: "Emoji")
    var emoji: String

    @Property(title: "Income")
    var income: Bool

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(emoji) \(name)")
    }

    init(id: UUID, name: String, emoji: String, income: Bool) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.income = income
    }
}

@available(iOS 16, *)
struct IncomeCategoryQuery: EntityStringQuery {
    func entities(matching query: String) async throws -> [IncomeCategoryEntity] {
        return await MainActor.run {
            DataController.shared.getAllCategories(income: true).filter {
                $0.wrappedName.localizedCaseInsensitiveContains(query) || $0.wrappedEmoji.localizedCaseInsensitiveContains(query)
            }.compactMap { category in
                if let id = category.id {
                    return IncomeCategoryEntity(id: id, name: category.wrappedName, emoji: category.wrappedEmoji, income: category.income)
                } else {
                    return nil
                }
            }
        }
    }

    func entities(for identifiers: [IncomeCategoryEntity.ID]) async throws -> [IncomeCategoryEntity] {
        return await MainActor.run {
            var results: [IncomeCategoryEntity] = []

            for identifier in identifiers {
                if let match = try? DataController.shared.findCategory(withId: identifier),
                   let id = match.id {
                    results.append(IncomeCategoryEntity(id: id, name: match.wrappedName, emoji: match.wrappedEmoji, income: match.income))
                }
            }

            return results
        }
    }

    func suggestedEntities() async throws -> [IncomeCategoryEntity] {
        return await MainActor.run {
            DataController.shared.getAllCategories(income: true).compactMap { category in
                if let id = category.id {
                    return IncomeCategoryEntity(id: id, name: category.wrappedName, emoji: category.wrappedEmoji, income: category.income)
                } else {
                    return nil
                }
            }
        }
    }
}

@available(iOS 16, *)
struct ExpenseCategoryEntity: AppEntity, Identifiable {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = .init(name: "Category")
    typealias DefaultQueryType = ExpenseCategoryQuery
    static let defaultQuery: ExpenseCategoryQuery = .init()

    var id: UUID

    @Property(title: "Name")
    var name: String

    @Property(title: "Emoji")
    var emoji: String

    @Property(title: "Income")
    var income: Bool

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(emoji) \(name)")
    }

    init(id: UUID, name: String, emoji: String, income: Bool) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.income = income
    }
}

@available(iOS 16, *)
struct ExpenseCategoryQuery: EntityStringQuery {
    func entities(matching query: String) async throws -> [ExpenseCategoryEntity] {
        return await MainActor.run {
            DataController.shared.getAllCategories(income: false).filter {
                $0.wrappedName.localizedCaseInsensitiveContains(query) || $0.wrappedEmoji.localizedCaseInsensitiveContains(query)
            }.compactMap { category in
                if let id = category.id {
                    return ExpenseCategoryEntity(id: id, name: category.wrappedName, emoji: category.wrappedEmoji, income: category.income)
                } else {
                    return nil
                }
            }
        }
    }

    func entities(for identifiers: [ExpenseCategoryEntity.ID]) async throws -> [ExpenseCategoryEntity] {
        return await MainActor.run {
            var results: [ExpenseCategoryEntity] = []

            for identifier in identifiers {
                if let match = try? DataController.shared.findCategory(withId: identifier),
                   let id = match.id {
                    results.append(ExpenseCategoryEntity(id: id, name: match.wrappedName, emoji: match.wrappedEmoji, income: match.income))
                }
            }

            return results
        }
    }

    func suggestedEntities() async throws -> [ExpenseCategoryEntity] {
        return await MainActor.run {
            DataController.shared.getAllCategories(income: false).compactMap { category in
                if let id = category.id {
                    return ExpenseCategoryEntity(id: id, name: category.wrappedName, emoji: category.wrappedEmoji, income: category.income)
                } else {
                    return nil
                }
            }
        }
    }
}

@available(iOS 16, *)
struct BudgetEntity: AppEntity, Identifiable {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = .init(name: "Budget")
    typealias DefaultQueryType = BudgetQuery
    static let defaultQuery: BudgetQuery = .init()

    var id: UUID

    @Property(title: "Name")
    var name: String

    @Property(title: "Emoji")
    var emoji: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(emoji) \(name)")
    }

    init(id: UUID, name: String, emoji: String) {
        self.id = id
        self.name = name
        self.emoji = emoji
    }
}

@available(iOS 16, *)
struct BudgetQuery: EntityStringQuery {
    func entities(matching query: String) async throws -> [BudgetEntity] {
        return await MainActor.run {
            DataController.shared.getAllBudgets().filter {
                $0.wrappedName.localizedCaseInsensitiveContains(query) || $0.wrappedEmoji.localizedCaseInsensitiveContains(query)
            }.compactMap { budget in
                if let id = budget.id {
                    return BudgetEntity(id: id, name: budget.wrappedName, emoji: budget.wrappedEmoji)
                } else {
                    return nil
                }
            }
        }
    }

    func entities(for identifiers: [BudgetEntity.ID]) async throws -> [BudgetEntity] {
        return await MainActor.run {
            var results: [BudgetEntity] = []

            for identifier in identifiers {
                if let match = try? DataController.shared.findBudget(withId: identifier),
                   let id = match.id {
                    results.append(BudgetEntity(id: id, name: match.wrappedName, emoji: match.wrappedEmoji))
                }
            }

            return results
        }
    }

    func suggestedEntities() async throws -> [BudgetEntity] {
        return await MainActor.run {
            DataController.shared.getAllBudgets().compactMap { budget in
                if let id = budget.id {
                    return BudgetEntity(id: id, name: budget.wrappedName, emoji: budget.wrappedEmoji)
                } else {
                    return nil
                }
            }
        }
    }
}

// @available(iOS 16, *)
// struct CategoryEntity: AppEntity, Identifiable, Hashable, Equatable {
//    static var typeDisplayRepresentation: TypeDisplayRepresentation = TypeDisplayRepresentation(name: "Category")
//    typealias DefaultQueryType = CategoryQuery
//    static let defaultQuery: CategoryQuery = CategoryQuery()
//
//    var id: UUID
//
//    @Property(title: "Name")
//    var name: String
//
//    @Property(title: "Emoji")
//    var emoji: String
//
//    @Property(title: "Income")
//    var income: Bool
//
//    var displayRepresentation: DisplayRepresentation {
//        DisplayRepresentation(title: "\(emoji) \(name)")
//    }
//
//    init(id: UUID, name: String, emoji: String, income: Bool) {
//        self.id = id
//        self.name = name
//        self.emoji = emoji
//        self.income = income
//    }
//
// }
//
// @available(iOS 16, *)
// extension CategoryEntity {
//
//    // Hashable conformance
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(id)
//    }
//
//    // Equtable conformance
//    static func ==(lhs: CategoryEntity, rhs: CategoryEntity) -> Bool {
//        return lhs.id == rhs.id
//    }
//
// }
//
// @available(iOS 16, *)
// struct CategoryQuery: EntityPropertyQuery {
//    init() {
//        self.expense = false
//    }
//
//    init(expense: Bool) {
//        self.expense = expense
//    }
//
//    var expense: Bool
//
//    func entities(matching query: String) async throws -> [CategoryEntity] {
//        let dataController = DataController()
//        let categories = dataController.getAllCategories().filter {
//            ($0.wrappedName.localizedCaseInsensitiveContains(query) || $0.wrappedEmoji.localizedCaseInsensitiveContains(query))
//        }
//
//        return categories.compactMap { category in
//            if let id = category.id {
//                return CategoryEntity(id: id, name: category.wrappedName, emoji: category.wrappedEmoji, income: category.income)
//            } else {
//                return nil
//            }
//        }
//    }
//
//    func entities(for identifiers: [CategoryEntity.ID]) async throws -> [CategoryEntity] {
//        let dataController = DataController()
//        return identifiers.compactMap { identifier in
//            if let match = try? dataController.findCategory(withId: identifier) {
//                if let id = match.id {
//                    return CategoryEntity(id: id, name: match.wrappedName, emoji: match.wrappedEmoji, income: match.income)
//                } else {
//                    return nil
//                }
//            } else {
//                return nil
//            }
//        }
//    }
//
//    func suggestedEntities() async throws -> [CategoryEntity] {
//        let dataController = DataController()
//        let categories = dataController.getAllCategories()
//        return categories.compactMap { category in
//            if category.income == expense {
//                if let id = category.id {
//                    return CategoryEntity(id: id, name: category.wrappedName, emoji: category.wrappedEmoji, income: category.income)
//                } else {
//                    return nil
//                }
//            } else {
//                return nil
//            }
//
//        }
//    }
//
//    static var properties = EntityQueryProperties<CategoryEntity, NSPredicate> {
//        Property(\CategoryEntity.$name) {
//            EqualToComparator { NSPredicate(format: "name = %@", $0) }
//            ContainsComparator { NSPredicate(format: "name CONTAINS %@", $0) }
//
//        }
//        Property(\CategoryEntity.$emoji) {
//            EqualToComparator { NSPredicate(format: "emoji = %@", $0) }
//            ContainsComparator { NSPredicate(format: "emoji CONTAINS %@", $0) }
//        }
//    }
//
//    static var sortingOptions = SortingOptions {
//        SortableBy(\CategoryEntity.$name)
//        SortableBy(\CategoryEntity.$emoji)
//    }
//
//    func entities(
//        matching comparators: [NSPredicate],
//        mode: ComparatorMode,
//        sortedBy: [Sort<CategoryEntity>],
//        limit: Int?
//    ) async throws -> [CategoryEntity] {
//        let context = DataController().container.viewContext
//        let request: NSFetchRequest<Category> = Category.fetchRequest()
//        let predicate = NSCompoundPredicate(type: mode == .and ? .and : .or, subpredicates: comparators)
//        request.fetchLimit = limit ?? 5
//        request.predicate = predicate
//
//        let matchingCategories = try context.fetch(request)
//        return matchingCategories.compactMap { category in
//            if let id = category.id {
//                return CategoryEntity(id: id, name: category.wrappedName, emoji: category.wrappedEmoji, income: category.income)
//            } else {
//                return nil
//            }
//        }
//    }
//
// }
