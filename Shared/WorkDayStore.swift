import Foundation

/// Bewaart de werkdag op de telefoon, zodat hij er nog is als je de app afsluit.
///
/// We gebruiken de opslag van een App Group. Zodra de App Group in stap 5 is ingesteld,
/// kan de widget dezelfde gegevens lezen. Tot die tijd valt het automatisch terug op
/// de gewone opslag van de app.
enum WorkDayStore {
    static let appGroupID = "group.com.jeroenderuijter.Loonteller"

    private static let currentDayKey = "currentDay"
    private static let lastInputKey = "lastInput"

    private static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    /// De gestarte werkdag van vandaag, of `nil` als je dag nog niet gestart is.
    static var currentDay: WorkDay? {
        get { load(currentDayKey) }
        set { save(newValue, forKey: currentDayKey) }
    }

    /// De laatst ingevulde gegevens, om het formulier mee voor te vullen.
    static var lastInput: WorkDay? {
        get { load(lastInputKey) }
        set { save(newValue, forKey: lastInputKey) }
    }

    private static func load(_ key: String) -> WorkDay? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WorkDay.self, from: data)
    }

    private static func save(_ day: WorkDay?, forKey key: String) {
        if let day, let data = try? JSONEncoder().encode(day) {
            defaults.set(data, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }
}
