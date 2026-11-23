import SwiftUI

/// Kleuren en stijl van de app: donker groen met goud, als een kluis vol geld.
enum Theme {
    static let gold = Color(red: 1.0, green: 0.80, blue: 0.25)
    static let goldDark = Color(red: 0.78, green: 0.53, blue: 0.05)
    static let goldLight = Color(red: 1.0, green: 0.92, blue: 0.60)

    static let background = LinearGradient(
        colors: [Color(red: 0.04, green: 0.20, blue: 0.13), Color(red: 0.01, green: 0.06, blue: 0.04)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let goldGradient = LinearGradient(
        colors: [goldLight, gold, goldDark],
        startPoint: .top,
        endPoint: .bottom
    )
}

/// Een gouden "kaartje" als achtergrond, bijv. voor badges.
struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.white.opacity(0.08), in: .capsule)
            .overlay(Capsule().stroke(Theme.gold.opacity(0.35), lineWidth: 1))
    }
}

extension View {
    func glassCard() -> some View { modifier(GlassCard()) }
}
