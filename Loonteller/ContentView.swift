import SwiftUI
import WidgetKit

struct ContentView: View {
    /// De werkdag van vandaag. `nil` = je dag is nog niet gestart.
    @State private var workDay: WorkDay? = Self.loadCurrentDay()
    /// De laatst ingevulde gegevens, zodat het formulier niet leeg begint.
    @State private var lastInput: WorkDay? = WorkDayStore.lastInput

    /// Gekozen taal; alle teksten, bedragen en tijden volgen deze.
    @AppStorage(AppLanguage.storageKey, store: WorkDayStore.sharedDefaults)
    private var language: AppLanguage = .system

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if let workDay {
                CounterView(workDay: workDay) {
                    self.workDay = nil
                }
            } else {
                StartDayView(initial: startDayInitial()) { newDay in
                    workDay = newDay
                    lastInput = newDay
                }
            }
        }
        .environment(\.locale, language.locale)
        .tint(Theme.gold)
        .preferredColorScheme(.dark)
        .onChange(of: workDay) { oldValue, newValue in
            // Was de vorige dag al klaar? Dan telt hij mee voor je streak en level.
            if let oldValue { Stats.recordCompleted(oldValue) }
            WorkDayStore.currentDay = newValue
            // Laat de widget direct een nieuw rooster maken met de nieuwe gegevens.
            WidgetCenter.shared.reloadAllTimelines()
            LiveActivityManager.sync(with: newValue)
        }
        .onChange(of: lastInput) { _, newValue in
            WorkDayStore.lastInput = newValue
        }
        .onChange(of: scenePhase) { _, phase in
            // Open je de app de volgende dag weer, dan begin je met een nieuwe dag.
            guard phase == .active else { return }
            if let day = workDay, !day.isCurrent() {
                Stats.recordCompleted(day)
                workDay = nil
            }
            // Bij openen: Live Activity gelijk trekken (bijv. afsluiten als je dag klaar is).
            LiveActivityManager.sync(with: workDay)
        }
        // Zolang de app open is: het bedrag in de Live Activity elke seconde bijwerken.
        // Deze taak stopt vanzelf als de app naar de achtergrond gaat of de dag verandert.
        .task(id: LiveUpdateKey(day: workDay, isActive: scenePhase == .active)) {
            guard scenePhase == .active, let workDay else { return }
            await LiveActivityManager.keepUpdating(workDay)
        }
    }

    /// Bepaalt wanneer de bijwerk-taak opnieuw moet starten.
    private struct LiveUpdateKey: Equatable {
        let day: WorkDay?
        let isActive: Bool
    }

    /// Waarmee het startscherm wordt ingevuld:
    /// 1. Al een dag ingevuld vandaag (bijv. na "Aanpassen")? Dan die.
    /// 2. Werkdag volgens je weekrooster? Tijden en reizen uit het rooster, loon/BTW/tarieven van je vorige dag.
    /// 3. Anders: je vorige dag, verplaatst naar vandaag.
    private func startDayInitial(now: Date = Date()) -> WorkDay? {
        if let lastInput, Calendar.current.isDate(lastInput.start, inSameDayAs: now) {
            return lastInput
        }
        let previous = lastInput?.movedToDay(of: now)
        guard let scheduled = WeekSchedule.saved.workDay(on: now) else { return previous }
        let base = previous ?? WorkDay(payType: .daily, amount: 0, start: now, end: now, breakMinutes: 0)
        return scheduled.applied(to: base, on: now)
    }

    /// Haalt de opgeslagen werkdag op, maar alleen als die nog bij vandaag hoort.
    private static func loadCurrentDay() -> WorkDay? {
        guard let day = WorkDayStore.currentDay else { return nil }
        guard day.isCurrent() else {
            // Dag van gisteren (of eerder) die klaar is: opslaan voor streak en level.
            Stats.recordCompleted(day)
            return nil
        }
        return day
    }
}

#Preview {
    ContentView()
}
