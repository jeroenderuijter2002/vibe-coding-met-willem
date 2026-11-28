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

    // MARK: Reizen (krijg je in één keer bij het begin van je dag)

    /// Gereden kilometers per dag, heen en terug samen.
    var kilometers: Double = 0
    /// Kilometervergoeding per km.
    var kilometerRate: Double = WorkDay.defaultKilometerRate
    /// Reistijd per dag in minuten, heen en terug samen.
    var travelMinutes: Int = 0
    /// Vergoeding per uur reistijd. `nil` = je uurloon (bij dagloon: niets).
    var travelHourlyRate: Double? = nil

    /// Standaard kilometervergoeding (belastingvrij maximum).
    static let defaultKilometerRate = 0.23

    // MARK: BTW (voor zzp'ers: alle bedragen hierboven zijn ex BTW)

    /// BTW-percentage dat over alles (loon + reisvergoeding) komt: 21, 9 of 0.
    var vatPercent: Int = 21

    static let vatOptions = [21, 9, 0]

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

    /// Je loon voor de hele dag (zonder reisvergoeding).
    var wageEarnings: Double {
        switch payType {
        case .daily:  return amount
        case .hourly: return amount * paidSeconds / 3600
        }
    }

    /// Kilometervergoeding voor vandaag.
    var kilometerAllowance: Double {
        kilometers * kilometerRate
    }

    /// Het uurtarief voor reistijd: zelf ingevuld, anders je uurloon.
    var effectiveTravelHourlyRate: Double {
        travelHourlyRate ?? (payType == .hourly ? amount : 0)
    }

    /// Betaalde reistijd voor vandaag.
    var travelTimePay: Double {
        Double(travelMinutes) / 60 * effectiveTravelHourlyRate
    }

    /// Alle reisvergoeding samen. Die staat in één keer op de teller zodra je dag begint.
    var travelEarnings: Double {
        kilometerAllowance + travelTimePay
    }

    /// Wat je aan het eind van de dag verdiend hebt: loon + reisvergoeding.
    var totalEarnings: Double {
        wageEarnings + travelEarnings
    }

    /// Hoe ver je in je werkdag bent: 0 (nog niet begonnen) tot 1 (klaar).
    /// De pauze is in de basisversie gelijk over de dag verdeeld.
    func progress(at date: Date) -> Double {
        guard shiftDuration > 0 else { return 0 }
        let elapsed = date.timeIntervalSince(start)
        return min(1, max(0, elapsed / shiftDuration))
    }

    /// Hoeveel je op moment `date` al verdiend hebt.
    /// Vanaf de begintijd staat de reisvergoeding er meteen; het loon loopt geleidelijk op.
    func earned(at date: Date) -> Double {
        guard date >= start else { return 0 }
        return travelEarnings + wageEarnings * progress(at: date)
    }

    /// Factor om van ex naar incl BTW te gaan, bijv. 1,21.
    var vatMultiplier: Double { 1 + Double(vatPercent) / 100 }

    /// De BTW over je hele dag.
    var totalVAT: Double { totalEarnings * Double(vatPercent) / 100 }

    /// Je dagtotaal incl BTW (wat er op de factuur komt).
    var totalIncludingVAT: Double { totalEarnings * vatMultiplier }

    /// Hoeveel je op moment `date` verdiend hebt, incl BTW.
    func earnedIncludingVAT(at date: Date) -> Double {
        earned(at: date) * vatMultiplier
    }

    /// Welk deel van het dagtotaal je al hebt (0...1). Hiermee tellen we de munten.
    func earnedFraction(at date: Date) -> Double {
        guard totalEarnings > 0 else { return progress(at: date) }
        return min(1, earned(at: date) / totalEarnings)
    }

    // MARK: - Welke dag?

    /// Hoort deze werkdag nog bij "vandaag"?
    /// Ja als hij vandaag begonnen is, of als hij nog niet afgelopen is (nachtdienst).
    func isCurrent(at date: Date = Date(), calendar: Calendar = .current) -> Bool {
        calendar.isDate(start, inSameDayAs: date) || date < effectiveEnd
    }

    /// Dezelfde werkdag, maar dan beginnend op `date` (bijv. nu), met dezelfde lengte.
    func starting(at date: Date) -> WorkDay {
        var copy = self
        copy.start = date
        copy.end = date.addingTimeInterval(shiftDuration)
        return copy
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

extension WorkDay {
    /// Zelf uitlezen, zodat werkdagen die vóór de reisvergoeding zijn opgeslagen nog steeds laden
    /// (die missen de nieuwe velden; dan gebruiken we de standaardwaarden).
    /// Staat in een extensie, zodat `WorkDay(payType:amount:...)` gewoon blijft werken.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            payType: try c.decode(PayType.self, forKey: .payType),
            amount: try c.decode(Double.self, forKey: .amount),
            start: try c.decode(Date.self, forKey: .start),
            end: try c.decode(Date.self, forKey: .end),
            breakMinutes: try c.decode(Int.self, forKey: .breakMinutes),
            kilometers: try c.decodeIfPresent(Double.self, forKey: .kilometers) ?? 0,
            kilometerRate: try c.decodeIfPresent(Double.self, forKey: .kilometerRate) ?? WorkDay.defaultKilometerRate,
            travelMinutes: try c.decodeIfPresent(Int.self, forKey: .travelMinutes) ?? 0,
            travelHourlyRate: try c.decodeIfPresent(Double.self, forKey: .travelHourlyRate),
            vatPercent: try c.decodeIfPresent(Int.self, forKey: .vatPercent) ?? 21
        )
    }
}
