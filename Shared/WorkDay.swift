import Foundation

/// Hoe je betaald wordt: een vast bedrag per dag, of per uur.
enum PayType: String, Codable, CaseIterable {
    case daily
    case hourly
}

/// De gegevens van één werkdag, zoals je ze invult bij "Start mijn dag".
struct WorkDay: Codable, Equatable {
    /// Dagloon of uurloon.
    var payType: PayType
    /// Het bedrag: per dag (bij `.daily`) of per uur (bij `.hourly`).
    var amount: Double
    /// Wanneer je begint.
    var start: Date
    /// Wanneer je stopt. Ligt dit vóór `start`, dan rekenen we met de volgende dag (nachtdienst).
    var end: Date
    /// Onbetaalde pauze in minuten.
    var breakMinutes: Int

    // MARK: - Tijden

    /// De eindtijd, eventueel een dag later als je over middernacht werkt.
    var effectiveEnd: Date {
        end > start ? end : end.addingTimeInterval(24 * 60 * 60)
    }

    /// Hoe lang je op het werk bent, van begin tot eind (inclusief pauze), in seconden.
    var shiftDuration: TimeInterval {
        effectiveEnd.timeIntervalSince(start)
    }

    /// Hoeveel seconden je betaald werkt: totale tijd min pauze.
    var paidSeconds: TimeInterval {
        max(0, shiftDuration - Double(breakMinutes) * 60)
    }

    // MARK: - Geld

    /// Wat je aan het eind van de dag verdiend hebt.
    var totalEarnings: Double {
        switch payType {
        case .daily:  return amount
        case .hourly: return amount * paidSeconds / 3600
        }
    }

    /// Hoe ver je in je werkdag bent: 0 (nog niet begonnen) tot 1 (klaar).
    /// De pauze is in de basisversie gelijk over de dag verdeeld.
    func progress(at date: Date) -> Double {
        guard shiftDuration > 0 else { return 0 }
        let elapsed = date.timeIntervalSince(start)
        return min(1, max(0, elapsed / shiftDuration))
    }

    /// Hoeveel je op moment `date` al verdiend hebt.
    func earned(at date: Date) -> Double {
        totalEarnings * progress(at: date)
    }

    // MARK: - Welke dag?

    /// Hoort deze werkdag nog bij "vandaag"?
    /// Ja als hij vandaag begonnen is, of als hij nog niet afgelopen is (nachtdienst).
    func isCurrent(at date: Date = Date(), calendar: Calendar = .current) -> Bool {
        calendar.isDate(start, inSameDayAs: date) || date < effectiveEnd
    }

    /// Dezelfde tijden (uren en minuten), maar dan op de dag van `date`.
    /// Handig om de gegevens van gisteren voor te vullen voor vandaag.
    func movedToDay(of date: Date = Date(), calendar: Calendar = .current) -> WorkDay {
        func sameTime(_ time: Date) -> Date {
            let parts = calendar.dateComponents([.hour, .minute], from: time)
            return calendar.date(bySettingHour: parts.hour ?? 0, minute: parts.minute ?? 0, second: 0, of: date) ?? time
        }
        var copy = self
        copy.start = sameTime(start)
        copy.end = sameTime(end)
        return copy
    }
}
