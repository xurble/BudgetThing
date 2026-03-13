//
//  IntentHandler.swift
//  BudgetIntent
//
//  Created by Rafael Soh on 17/8/22.
//

import Intents
import SwiftData

class IntentHandler: INExtension, @preconcurrency BudgetWidgetConfigurationIntentHandling {
    @MainActor
    func provideBudgetOptionsCollection(for _: BudgetWidgetConfigurationIntent, with completion: @escaping (INObjectCollection<WidgetBudget>?, Error?) -> Void) {
        let dataController = DataController.shared
        let descriptor = dataController.fetchDescriptorForBudgets()

        let budgets: [WidgetBudget] = dataController.results(for: descriptor).compactMap { budget in
            guard let id = budget.id else {
                return nil
            }
            return WidgetBudget(identifier: id.uuidString, display: budget.wrappedName)
        }

        let collection = INObjectCollection(items: budgets)
        completion(collection, nil)
    }

    override func handler(for _: INIntent) -> Any {
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.

        return self
    }
}
