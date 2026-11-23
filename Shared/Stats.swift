import Foundation

/// Statistieken over alle dagen heen: afgemaakte dagen, totaal verdiend en de streak.
enum Stats {
    private static let completedDaysKey = "completedDays"

    /// Afgemaakte dagen: "2026-11-23" → verdiend bedrag die dag.
    static var completedDays: [String: Double] {
        get { WorkDayStore.sharedDefaults.dictionary(forKey: completedDaysKey) as? [String: Double] ?? [:] }
        set { WorkDayStore.sharedDefaults.set(newValue, forKey: completedDaysKey) }
    }

    /// Sla een werkdag op als "afgemaakt", maar alleen als hij echt voorbij is.
    /// Een dag wordt maar één keer geteld.
    static func recordCompleted(_ day: WorkDay, at now: Date = Date()) {
        guard now >= day.effectiveEnd else { return }
        let key = dayKey(day.start)
        guard completedDays[key] == nil else { return }
        completedDays[key] = day.totalEarnings
    }

    /// Of deze werkdag al als afgemaakt is opgeslagen.
    static func isRecorded(_ day: WorkDay) -> Bool {
        completedDays[dayKey(day.start)] != nil
    }

    /// Totaal verdiend op alle afgemaakte dagen, zonder `day` (die tellen we live mee).
    static func recordedTotal(excluding day: WorkDay?) -> Double {
        var days = completedDays
        if let day { days[dayKey(day.start)] = nil }
        return days.values.reduce(0, +)
    }

    /// Aantal werkdagen achter elkaar dat je je dag hebt afgemaakt.
    /// Weekenddagen zonder werk breken de streak niet, en vandaag ook niet (je bent misschien nog bezig).
    static func streak(at now: Date = Date(), calendar: Calendar = .current) -> Int {
        let days = completedDays
        var count = 0
        var date = calendar.startOfDay(for: now)
        for offset in 0..<3650 {
            if days[dayKey(date, calendar: calendar)] != nil {
                count += 1
            } else if offset > 0 && !calendar.isDateInWeekend(date) {
                break
            }
            guard let previous = calendar.date(byAdding: .day, value: -1, to: date) else { break }
            date = previous
        }
        return count
    }

    /// "2026-11-23" voor een datum.
    static func dayKey(_ date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}
