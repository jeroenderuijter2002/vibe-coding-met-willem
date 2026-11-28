import SwiftUI

/// Kleuren en stijl van de app: diep middernachtblauw met koraal/koperen munten en perzik accenten.
/// Wil je andere kleuren? Pas alleen dit bestand aan (en `tools/make_icon.swift` voor het icoon).
enum Theme {
    /// Hoofdkleur: koraal (munten, knoppen, voortgangsbalken).
    static let accent = Color(red: 0.94, green: 0.54, blue: 0.42)        // #F08A6C
    /// Donkere variant: koper (rand en dikte van de munten).
    static let accentDark = Color(red: 0.72, green: 0.33, blue: 0.23)    // #B8533A
    /// Lichte variant: perzik (kleine teksten en accenten).
    static let accentLight = Color(red: 1.0, green: 0.79, blue: 0.69)    // #FFC9B0

    /// Bovenkant van de achtergrond: middernachtblauw.
    static let backgroundTop = Color(red: 0.06, green: 0.09, blue: 0.19) // #0F1630
    /// Onderkant van de achtergrond: bijna zwart blauw.
    static let backgroundBottom = Color(red: 0.03, green: 0.04, blue: 0.10) // #070B1A

    static let background = LinearGradient(
        colors: [backgroundTop, backgroundBottom],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Verloop voor munten en het grote bedrag: perzik → koraal → koper.
    static let accentGradient = LinearGradient(
        colors: [accentLight, accent, accentDark],
        startPoint: .top,
        endPoint: .bottom
    )
}

/// Een "kaartje" als achtergrond, bijv. voor badges.
struct GlassCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.white.opacity(0.08), in: .capsule)
            .overlay(Capsule().stroke(Theme.accent.opacity(0.35), lineWidth: 1))
    }
}

extension View {
    func glassCard() -> some View { modifier(GlassCard()) }
}
