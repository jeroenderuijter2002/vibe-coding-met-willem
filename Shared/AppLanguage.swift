import Foundation

/// De taal van de app, in te stellen via de 🌐-knop.
enum AppLanguage: String, CaseIterable, Identifiable {
    /// Volg de taal van de iPhone.
    case system
    case dutch = "nl"
    case english = "en"

    var id: String { rawValue }

    /// De `Locale` die SwiftUI gebruikt voor teksten, bedragen en tijden.
    var locale: Locale {
        switch self {
        case .system:  return .current
        case .dutch:   return Locale(identifier: "nl_NL")
        case .english: return Locale(identifier: "en_NL")
        }
    }

    /// Sleutel in de gedeelde opslag (zie `WorkDayStore`).
    static let storageKey = "appLanguage"

    /// De opgeslagen taalkeuze (ook leesbaar voor de widget).
    static var saved: AppLanguage {
        WorkDayStore.sharedDefaults.string(forKey: storageKey).flatMap(AppLanguage.init) ?? .system
    }
}
