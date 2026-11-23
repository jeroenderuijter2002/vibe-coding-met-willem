import SwiftUI

struct ContentView: View {
    /// De werkdag van vandaag. `nil` = je dag is nog niet gestart.
    @State private var workDay: WorkDay?
    /// De laatst ingevulde gegevens, zodat "Aanpassen" niet alles leegmaakt.
    @State private var lastInput: WorkDay?

    var body: some View {
        if let workDay {
            // Tijdelijk overzicht. In stap 3 wordt dit het teller-scherm.
            VStack(spacing: 16) {
                Image(systemName: "eurosign.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.green)
                Text("Je dag is gestart!")
                    .font(.title.bold())
                HStack(spacing: 4) {
                    Text(workDay.start, style: .time)
                    Text("–")
                    Text(workDay.end, style: .time)
                }
                Text("Vandaag: \(workDay.totalEarnings.formatted(.currency(code: "EUR")))")
                    .font(.headline)
                Button("Aanpassen") {
                    self.workDay = nil
                }
                .buttonStyle(.bordered)
            }
            .padding()
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
