import WidgetKit
import SwiftUI

/// Eén "plaatje" van de widget op een bepaald moment.
struct EarningsEntry: TimelineEntry {
    let date: Date
    /// Verdiend bedrag op `date`.
    let earned: Double
    /// De werkdag van vandaag, of `nil` als je dag nog niet gestart is.
    let day: WorkDay?
}

/// Maakt van tevoren een rooster van widget-plaatjes: één per minuut.
/// iOS laat ze op het juiste moment zien, zodat het bedrag elke minuut verspringt.
/// De voortgangsbalk en de afteller lopen daartussen live door.
struct Provider: TimelineProvider {
    /// Maximaal aantal plaatjes per keer (6 uur). Daarna vraagt iOS een nieuw rooster.
    private let maxEntries = 360

    func placeholder(in context: Context) -> EarningsEntry {
        EarningsEntry(date: Date(), earned: 0, day: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (EarningsEntry) -> Void) {
        let now = Date()
        if let day = Self.activeDay(at: now) {
            completion(EarningsEntry(date: now, earned: day.earned(at: now), day: day))
        } else if context.isPreview {
            // Voorbeeld in de widget-galerij.
            let example = WorkDay(payType: .daily, amount: 200,
                                  start: now.addingTimeInterval(-4 * 3600),
                                  end: now.addingTimeInterval(4 * 3600), breakMinutes: 0)
            completion(EarningsEntry(date: now, earned: example.earned(at: now), day: example))
        } else {
            completion(EarningsEntry(date: now, earned: 0, day: nil))
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EarningsEntry>) -> Void) {
        let now = Date()
        let calendar = Calendar.current
        let nextMidnight = calendar.startOfDay(for: now).addingTimeInterval(24 * 60 * 60)

        // Geen gestarte dag: €0,00. De app ververst de widget zodra je je dag start.
        guard let day = Self.activeDay(at: now) else {
            completion(Timeline(entries: [EarningsEntry(date: now, earned: 0, day: nil)], policy: .after(nextMidnight)))
            return
        }

        // Dag is al klaar: vol bedrag tonen tot middernacht, daarna weer opnieuw kijken.
        guard now < day.effectiveEnd else {
            completion(Timeline(entries: [EarningsEntry(date: now, earned: day.totalEarnings, day: day)], policy: .after(nextMidnight)))
            return
        }

        // Elke hele minuut een plaatje, vanaf nu tot het einde van de werkdag.
        var entries = [EarningsEntry(date: now, earned: day.earned(at: now), day: day)]
        var moment = calendar.nextDate(after: now, matching: DateComponents(second: 0), matchingPolicy: .nextTime) ?? now
        while moment < day.effectiveEnd && entries.count < maxEntries {
            entries.append(EarningsEntry(date: moment, earned: day.earned(at: moment), day: day))
            moment = moment.addingTimeInterval(60)
        }
        // Precies op de eindtijd het volle bedrag.
        if moment >= day.effectiveEnd {
            entries.append(EarningsEntry(date: day.effectiveEnd, earned: day.totalEarnings, day: day))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    /// De opgeslagen werkdag, als die bij vandaag hoort.
    private static func activeDay(at date: Date) -> WorkDay? {
        guard let day = WorkDayStore.currentDay, day.isCurrent(at: date) else { return nil }
        return day
    }
}

// MARK: - Weergave

/// Voortgangsbalk + afteller die live meelopen (zonder dat de widget opnieuw getekend hoeft te worden).
struct LiveProgress: View {
    let start: Date
    let end: Date
    /// Moment van tekenen, om te bepalen of de dag al begonnen/klaar is.
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if now >= end {
                ProgressView(value: 1)
                Text("Klaar voor vandaag! 🎉")
            } else {
                // Met timerInterval loopt de balk vanzelf vloeiend van begin tot eind.
                ProgressView(timerInterval: start...end, countsDown: false) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
                if now >= start {
                    Text("Nog \(Text(timerInterval: now...end, countsDown: true)) te gaan")
                        .monospacedDigit()
                } else {
                    Text("Begint om \(Text(start, style: .time))")
                }
            }
        }
        .tint(Theme.gold)
        .font(.caption2)
        .foregroundStyle(.white.opacity(0.65))
    }
}

struct LoontellerWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: EarningsEntry

    var body: some View {
        switch family {
        case .systemMedium: medium
        default: small
        }
    }

    private var coins: Int {
        guard let day = entry.day else { return 0 }
        return Int(day.earnedFraction(at: entry.date) * 100)
    }

    private func amount(size: CGFloat) -> some View {
        Text(entry.earned, format: .currency(code: "EUR"))
            .font(.system(size: size, weight: .heavy, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(Theme.goldGradient)
            .shadow(color: Theme.gold.opacity(0.35), radius: 6)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
    }

    private var label: some View {
        Text("Verdiend tot nu toe:")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.7))
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                label
                Spacer(minLength: 0)
                CoinView(width: 22, height: 7)
            }
            amount(size: 28)
            Spacer(minLength: 0)
            if let day = entry.day {
                LiveProgress(start: day.start, end: day.effectiveEnd, now: entry.date)
            } else {
                Text("Start je dag in de app")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.65))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var medium: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                label
                amount(size: 32)
                if let day = entry.day {
                    Text("van \(day.totalEarnings, format: .currency(code: "EUR")) ex BTW")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                    if day.vatPercent > 0 {
                        Text("Incl. BTW: \(entry.earned * day.vatMultiplier, format: .currency(code: "EUR"))")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.goldLight)
                    }
                    Spacer(minLength: 0)
                    LiveProgress(start: day.start, end: day.effectiveEnd, now: entry.date)
                } else {
                    Spacer(minLength: 0)
                    Text("Start je dag in de app")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.65))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

            // Dezelfde muntenstapels als in de app, in het klein.
            CoinStackView(coins: coins, scale: 0.5)
        }
    }
}

struct LoontellerWidget: Widget {
    let kind = "LoontellerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            LoontellerWidgetEntryView(entry: entry)
                .environment(\.locale, AppLanguage.saved.locale)
                .environment(\.colorScheme, .dark)
                .containerBackground(for: .widget) { Theme.background }
        }
        .configurationDisplayName("Loonteller")
        .description("Zie hoeveel je vandaag al verdiend hebt.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    LoontellerWidget()
} timeline: {
    EarningsEntry(date: .now, earned: 0, day: nil)
    EarningsEntry(date: .now, earned: 87.5,
                  day: WorkDay(payType: .daily, amount: 200, start: .now.addingTimeInterval(-3600),
                               end: .now.addingTimeInterval(3 * 3600), breakMinutes: 0))
}
