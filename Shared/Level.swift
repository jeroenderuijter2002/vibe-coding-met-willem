import SwiftUI

/// Een level/titel, gebaseerd op hoeveel je in totaal (over alle dagen) verdiend hebt.
struct Level: Equatable {
    let number: Int
    /// Vanaf dit totaalbedrag heb je dit level.
    let threshold: Double
    let emoji: String
    let title: LocalizedStringKey

    static let all: [Level] = [
        Level(number: 1, threshold: 0,       emoji: "🐣", title: "Stagiair"),
        Level(number: 2, threshold: 100,     emoji: "🧱", title: "Sjouwer"),
        Level(number: 3, threshold: 500,     emoji: "🛠️", title: "Harde werker"),
        Level(number: 4, threshold: 1_500,   emoji: "🧰", title: "Vakman"),
        Level(number: 5, threshold: 5_000,   emoji: "💸", title: "Geldmachine"),
        Level(number: 6, threshold: 15_000,  emoji: "😎", title: "Baas"),
        Level(number: 7, threshold: 50_000,  emoji: "💎", title: "Goudhaantje"),
        Level(number: 8, threshold: 100_000, emoji: "🏆", title: "Miljonair in wording"),
    ]

    /// Het level dat bij een totaalbedrag hoort.
    static func current(for lifetime: Double) -> Level {
        all.last { lifetime >= $0.threshold } ?? all[0]
    }

    /// Het volgende level, of `nil` als je al het hoogste level hebt.
    var next: Level? {
        Level.all.first { $0.number == number + 1 }
    }

    /// Hoe ver je bent richting het volgende level (0...1).
    func progress(for lifetime: Double) -> Double {
        guard let next else { return 1 }
        return min(1, max(0, (lifetime - threshold) / (next.threshold - threshold)))
    }
}
