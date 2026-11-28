import Foundation

/// Afgemaakte dagen, voor later (geschiedenis per week/maand).
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

    /// "2026-11-23" voor een datum.
    static func dayKey(_ date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
}
