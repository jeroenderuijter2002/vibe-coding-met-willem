import SwiftUI

struct ContentView: View {
    /// De werkdag van vandaag. `nil` = je dag is nog niet gestart.
    @State private var workDay: WorkDay?
    /// De laatst ingevulde gegevens, zodat "Aanpassen" niet alles leegmaakt.
    @State private var lastInput: WorkDay?

    var body: some View {
        if let workDay {
            CounterView(workDay: workDay) {
                self.workDay = nil
            }
        } else {
            StartDayView(initial: lastInput) { newDay in
                workDay = newDay
                lastInput = newDay
            }
        }
    }
}

#Preview {
    ContentView()
}
