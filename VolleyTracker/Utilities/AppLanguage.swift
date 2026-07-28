import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case bulgarian = "bg"

    static let storageKey = "appLanguage"
    static var defaultLanguage: AppLanguage {
        Locale.preferredLanguages.first?.hasPrefix("bg") == true ? .bulgarian : .english
    }

    static var selected: AppLanguage {
        let rawValue = UserDefaults.standard.string(forKey: storageKey)
            ?? defaultLanguage.rawValue
        return AppLanguage(rawValue: rawValue) ?? defaultLanguage
    }

    var id: String { rawValue }

    var locale: Locale {
        Locale(identifier: rawValue)
    }

    var nativeName: String {
        switch self {
        case .english:
            "English"
        case .bulgarian:
            "Български"
        }
    }
}

enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case matchNight

    static let storageKey = "appAppearance"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .matchNight: "Match Night"
        }
    }

    var icon: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max.fill"
        case .matchNight: "moon.stars.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .matchNight: .dark
        }
    }
}

enum AppCurrency: String, CaseIterable, Identifiable {
    case eur = "EUR"
    case bgn = "BGN"

    static let storageKey = "appCurrency"

    var id: String { rawValue }
    var title: String { rawValue }
    var symbol: String { self == .eur ? "€" : "лв." }

    static var selected: AppCurrency {
        let rawValue = UserDefaults.standard.string(forKey: storageKey) ?? AppCurrency.eur.rawValue
        return AppCurrency(rawValue: rawValue) ?? .eur
    }

    func format(_ value: Double, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = rawValue
        formatter.locale = locale
        formatter.minimumFractionDigits = value.rounded() == value ? 0 : 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "\(symbol) \(value)"
    }
}
