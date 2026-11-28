import ActivityKit
import Foundation

/// Start, wijzigt en stopt de Live Activity op het vergrendelscherm.
enum LiveActivityManager {
    private typealias WorkActivity = Activity<WorkDayActivityAttributes>

    /// Zorgt dat de Live Activity klopt met de huidige werkdag.
    /// - `nil` (geen dag / aanpassen): Live Activity weg.
    /// - dag loopt nog: Live Activity bijwerken, en starten als `allowStart` aan staat.
    /// - dag is klaar: Live Activity afsluiten (blijft nog even zichtbaar op het vergrendelscherm).
    static func sync(with day: WorkDay?, allowStart: Bool = true) {
        Task {
            guard let day else {
                for activity in WorkActivity.activities {
                    await activity.end(nil, dismissalPolicy: .immediate)
                }
                return
            }

            let now = Date()
            let content = ActivityContent(state: day.activityState(at: now), staleDate: day.effectiveEnd)

            if now >= day.effectiveEnd {
                for activity in WorkActivity.activities {
                    await activity.end(content, dismissalPolicy: .default)
                }
                return
            }

            if let activity = WorkActivity.activities.first {
                await activity.update(content)
            } else if allowStart, ActivityAuthorizationInfo().areActivitiesEnabled {
                do {
                    _ = try WorkActivity.request(attributes: WorkDayActivityAttributes(), content: content)
                } catch {
                    print("Live Activity starten mislukt: \(error)")
                }
            }
        }
    }

    /// Werkt het bedrag in de Live Activity elke seconde bij, zolang deze taak loopt
    /// (dus zolang de app open is). Start geen nieuwe Live Activity als je die zelf hebt weggeveegd.
    static func keepUpdating(_ day: WorkDay) async {
        while !Task.isCancelled && Date() < day.effectiveEnd {
            sync(with: day, allowStart: false)
            try? await Task.sleep(for: .seconds(1))
        }
        if !Task.isCancelled {
            sync(with: day, allowStart: false)
        }
    }
}
