import WidgetKit
import SwiftUI

/// Eén "plaatje" van de widget op een bepaald moment.
struct EarningsEntry: TimelineEntry {
    let date: Date
    /// Verdiend bedrag op `date`.
    let earned: Double
}

/// Maakt van tevoren een rooster van widget-plaatjes: één per minuut.
/// iOS laat ze op het juiste moment zien, zodat het bedrag elke minuut verspringt.
struct Provider: TimelineProvider {
    /// Maximaal aantal plaatjes per keer (6 uur). Daarna vraagt iOS een nieuw rooster.
    private let maxEntries = 360

    func placeholder(in context: Context) -> EarningsEntry {
        EarningsEntry(date: Date(), earned: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (EarningsEntry) -> Void) {
        let now = Date()
        // In de widget-galerij laten we een voorbeeldbedrag zien als er nog geen dag is.
        let earned = Self.activeDay(at: now)?.earned(at: now) ?? (context.isPreview ? 87.50 : 0)
        completion(EarningsEntry(date: now, earned: earned))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EarningsEntry>) -> Void) {
        let now = Date()
        let calendar = Calendar.current
        let nextMidnight = calendar.startOfDay(for: now).addingTimeInterval(24 * 60 * 60)

        // Geen gestarte dag: €0,00. De app ververst de widget zodra je je dag start.
        guard let day = Self.activeDay(at: now) else {
            completion(Timeline(entries: [EarningsEntry(date: now, earned: 0)], policy: .after(nextMidnight)))
            return
        }

        // Dag is al klaar: vol bedrag tonen tot middernacht, daarna weer opnieuw kijken.
        guard now < day.effectiveEnd else {
            completion(Timeline(entries: [EarningsEntry(date: now, earned: day.totalEarnings)], policy: .after(nextMidnight)))
            return
        }

        // Elke hele minuut een plaatje, vanaf nu tot het einde van de werkdag.
        var entries = [EarningsEntry(date: now, earned: day.earned(at: now))]
        var moment = calendar.nextDate(after: now, matching: DateComponents(second: 0), matchingPolicy: .nextTime) ?? now
        while moment <= day.effectiveEnd && entries.count < maxEntries {
            entries.append(EarningsEntry(date: moment, earned: day.earned(at: moment)))
            moment = moment.addingTimeInterval(60)
        }
        // Precies op de eindtijd het volle bedrag.
        if moment > day.effectiveEnd {
            entries.append(EarningsEntry(date: day.effectiveEnd, earned: day.totalEarnings))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    /// De opgeslagen werkdag, als die bij vandaag hoort.
    private static func activeDay(at date: Date) -> WorkDay? {
        guard let day = WorkDayStore.currentDay, day.isCurrent(at: date) else { return nil }
        return day
    }
}

struct LoontellerWidgetEntryView: View {
    var entry: EarningsEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Verdiend tot nu toe:")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(entry.earned, format: .currency(code: "EUR"))
                .font(.system(.title, design: .rounded).bold())
                .monospacedDigit()
                .foregroundStyle(.green)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

@main
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
        .supportedFamilies([.systemSmall])
    }
}

#Preview(as: .systemSmall) {
    LoontellerWidget()
} timeline: {
    EarningsEntry(date: .now, earned: 0)
    EarningsEntry(date: .now, earned: 87.5)
}
