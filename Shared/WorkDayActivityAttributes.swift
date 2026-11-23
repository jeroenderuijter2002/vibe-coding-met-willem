import ActivityKit
import Foundation

/// Gegevens voor de Live Activity (vergrendelscherm en Dynamic Island).
///
/// Let op: een Live Activity kan zichzelf niet bijwerken. Het verdiende bedrag (`earned`)
/// wordt door de app ververst zolang die open is; is de app dicht, dan blijft het laatste
/// bedrag staan. De voortgangsbalk en de afteller lopen wél altijd live mee.
struct WorkDayActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var start: Date
        var end: Date
        /// Wat je aan het eind van de dag verdiend hebt.
        var totalEarnings: Double
        /// Wat je verdiend had op het moment dat de app dit bijwerkte.
        var earned: Double
    }
}

extension WorkDay {
    /// De werkdag omgezet naar de gegevens die de Live Activity nodig heeft, op moment `date`.
    func activityState(at date: Date = Date()) -> WorkDayActivityAttributes.ContentState {
        .init(start: start, end: effectiveEnd, totalEarnings: totalEarnings, earned: earned(at: date))
    }
}
