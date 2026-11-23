import SwiftUI

/// Het teller-scherm: laat live zien hoeveel je vandaag al verdiend hebt.
struct CounterView: View {
    let workDay: WorkDay
    /// Wordt aangeroepen als je op "Aanpassen" tikt.
    var onEdit: () -> Void

    var body: some View {
        // TimelineView tekent het scherm elke 0,1 seconde opnieuw, zodat de teller loopt.
        TimelineView(.periodic(from: .now, by: 0.1)) { context in
            let now = context.date
            let progress = workDay.progress(at: now)

            VStack(spacing: 24) {
                Spacer()

                Text(statusText(at: now))
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text(workDay.earned(at: now), format: .currency(code: "EUR"))
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.green)
                    .contentTransition(.numericText())
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                VStack(spacing: 8) {
                    ProgressView(value: progress)
                        .tint(.green)
                    HStack {
                        Text(workDay.start, style: .time)
                        Spacer()
                        Text(progress, format: .percent.precision(.fractionLength(0)))
                            .bold()
                        Spacer()
                        Text(workDay.effectiveEnd, style: .time)
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }

                if now >= workDay.start && now < workDay.effectiveEnd {
                    HStack(spacing: 4) {
                        Text("Nog")
                        Text(timerInterval: now...workDay.effectiveEnd, countsDown: true)
                            .monospacedDigit()
                        Text("te gaan")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                Text("Vandaag in totaal: \(workDay.totalEarnings, format: .currency(code: "EUR"))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                HStack {
                    Button("Aanpassen", action: onEdit)
                    LanguageMenu()
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.bordered)
            }
            .padding(32)
        }
    }

    private func statusText(at now: Date) -> LocalizedStringKey {
        if now < workDay.start { return "Je dag is nog niet begonnen" }
        if now >= workDay.effectiveEnd { return "Klaar voor vandaag! 🎉" }
        return "Verdiend tot nu toe"
    }
}

#Preview {
    CounterView(
        workDay: WorkDay(
            payType: .hourly,
            amount: 20,
            start: .now.addingTimeInterval(-3 * 3600),
            end: .now.addingTimeInterval(5 * 3600),
            breakMinutes: 30
        ),
        onEdit: {}
    )
}
