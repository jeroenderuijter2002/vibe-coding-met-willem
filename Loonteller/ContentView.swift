import SwiftUI
import WidgetKit

struct ContentView: View {
    /// De werkdag van vandaag. `nil` = je dag is nog niet gestart.
    @State private var workDay: WorkDay? = Self.loadCurrentDay()
    /// De laatst ingevulde gegevens, zodat het formulier niet leeg begint.
    @State private var lastInput: WorkDay? = WorkDayStore.lastInput

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if let workDay {
                CounterView(workDay: workDay) {
                    self.workDay = nil
                }
            } else {
                // Gegevens van een eerdere dag worden naar vandaag verplaatst.
                StartDayView(initial: lastInput?.movedToDay()) { newDay in
                    workDay = newDay
                    lastInput = newDay
                }
            }
        }
        .onChange(of: workDay) { _, newValue in
            WorkDayStore.currentDay = newValue
            // Laat de widget direct een nieuw rooster maken met de nieuwe gegevens.
            WidgetCenter.shared.reloadAllTimelines()
        }
        .onChange(of: lastInput) { _, newValue in
            WorkDayStore.lastInput = newValue
        }
        .onChange(of: scenePhase) { _, phase in
            // Open je de app de volgende dag weer, dan begin je met een nieuwe dag.
            if phase == .active, let day = workDay, !day.isCurrent() {
                workDay = nil
            }
        }
    }

    /// Haalt de opgeslagen werkdag op, maar alleen als die nog bij vandaag hoort.
    private static func loadCurrentDay() -> WorkDay? {
        guard let day = WorkDayStore.currentDay, day.isCurrent() else { return nil }
        return day
    }
}

#Preview {
    ContentView()
}
