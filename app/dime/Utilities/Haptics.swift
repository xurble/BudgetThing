//
//  Haptics.swift
//  dime
//

import UIKit

enum Haptics {
    private static let suiteName = "group.farm.poplar.budgetthing"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    private static var hapticType: Int {
        guard let defaults else {
            return 1
        }

        if let value = defaults.object(forKey: "haptics") as? Int {
            return value
        }

        return 1
    }

    private static var isEnabled: Bool {
        hapticType != 0
    }

    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle, onlyExcessive: Bool = false) {
        guard isEnabled else {
            return
        }

        if onlyExcessive && hapticType != 2 {
            return
        }

        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}
