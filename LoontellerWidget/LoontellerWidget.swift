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
        .tint(.green)
        .font(.caption2)
        .foregroundStyle(.secondary)
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

    private func amount(size: CGFloat) -> some View {
        Text(entry.earned, format: .currency(code: "EUR"))
            .font(.system(size: size, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.green)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Verdiend tot nu toe:")
                .font(.caption)
                .foregroundStyle(.secondary)
            amount(size: 28)
            Spacer(minLength: 0)
            if let day = entry.day {
                LiveProgress(start: day.start, end: day.effectiveEnd, now: entry.date)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var medium: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Verdiend tot nu toe:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                amount(size: 34)
                Spacer(minLength: 0)
                if let day = entry.day {
                    Text("Vandaag in totaal: \(day.totalEarnings, format: .currency(code: "EUR"))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                if let day = entry.day {
                    HStack {
                        Text(day.start, style: .time)
                        Spacer()
                        Text(day.effectiveEnd, style: .time)
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    LiveProgress(start: day.start, end: day.effectiveEnd, now: entry.date)
                } else {
                    Text("Start je dag in de app")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}

struct LoontellerWidget: Widget {
    let kind = "LoontellerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            LoontellerWidgetEntryView(entry: entry)
                .environment(\.locale, AppLanguage.saved.locale)
                .containerBackground(.fill.tertiary, for: .widget)
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
