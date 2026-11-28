import Foundation

/// Het rooster van één weekdag: tijden en reizen.
/// Loon, BTW en tarieven staan niet in het rooster; die komen van je laatst ingevulde dag.
struct DaySchedule: Codable, Equatable {
    var isWorkDay: Bool
    /// Begintijd in minuten na middernacht (7:00 = 420).
    var startMinutes: Int = 7 * 60
    /// Eindtijd in minuten na middernacht (16:00 = 960).
    var endMinutes: Int = 16 * 60
    var breakMinutes: Int = 30
    /// Kilometers heen en terug samen.
    var kilometers: Double = 0
    /// Reistijd heen en terug samen, in minuten.
    var travelMinutes: Int = 0
    var unpaidTravelMinutes: Int = 0

    /// Een tijdstip (minuten na middernacht) op de dag van `day`.
    static func date(_ minutes: Int, on day: Date, calendar: Calendar = .current) -> Date {
        calendar.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: day) ?? day
    }

    /// Minuten na middernacht van een tijdstip.
    static func minutes(of date: Date, calendar: Calendar = .current) -> Int {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
    }

    /// Een werkdag met de tijden en reizen van dit rooster, en het loon, de BTW en tarieven van `base`.
    func applied(to base: WorkDay, on day: Date = Date()) -> WorkDay {
        var copy = base
        copy.start = Self.date(startMinutes, on: day)
        copy.end = Self.date(endMinutes, on: day)
        copy.breakMinutes = breakMinutes
        copy.kilometers = kilometers
        copy.travelMinutes = travelMinutes
        copy.unpaidTravelMinutes = unpaidTravelMinutes
        return copy
    }
}

/// Je vaste weekrooster. Op een werkdag wordt het startscherm hiermee ingevuld.
struct WeekSchedule: Codable, Equatable {
    var isEnabled = false
    /// Index 0 = zondag, 1 = maandag, ... 6 = zaterdag (zoals `Calendar` weekdagen telt, min 1).
    /// Standaard: maandag t/m vrijdag werken, weekend vrij.
    var days: [DaySchedule] = (0..<7).map { DaySchedule(isWorkDay: $0 != 0 && $0 != 6) }

    /// Volgorde op het scherm: maandag eerst.
    static let displayOrder = [1, 2, 3, 4, 5, 6, 0]

    static func index(of date: Date, calendar: Calendar = .current) -> Int {
        calendar.component(.weekday, from: date) - 1
    }

    /// Het rooster van `date`, als het rooster aan staat en het een werkdag is.
    func workDay(on date: Date = Date()) -> DaySchedule? {
        guard isEnabled else { return nil }
        let day = days[Self.index(of: date)]
        return day.isWorkDay ? day : nil
    }

    /// Of je volgens je rooster vrij bent op `date`.
    func isDayOff(on date: Date = Date()) -> Bool {
        isEnabled && !days[Self.index(of: date)].isWorkDay
    }

    // MARK: - Opslaan

    /// Sleutel in de gedeelde opslag. Het rooster staat er als JSON (`Data`), zodat schermen
    /// het met `@AppStorage` kunnen volgen en meteen bijwerken als je iets wijzigt.
    static let storageKey = "weekSchedule"

    init() {}

    init(data: Data) {
        self = (try? JSONDecoder().decode(WeekSchedule.self, from: data)) ?? WeekSchedule()
    }

    var data: Data {
        (try? JSONEncoder().encode(self)) ?? Data()
    }

    static var saved: WeekSchedule {
        WeekSchedule(data: WorkDayStore.sharedDefaults.data(forKey: storageKey) ?? Data())
    }
}
