import SwiftUI

/// Eén gouden munt, van de zijkant gezien.
struct CoinView: View {
    var width: CGFloat = 46
    var height: CGFloat = 12

    var body: some View {
        ZStack {
            // Dikte van de munt
            Ellipse()
                .fill(Theme.accentDark)
                .offset(y: 2.5)
            // Bovenkant
            Ellipse()
                .fill(Theme.accentGradient)
            Ellipse()
                .stroke(Theme.accentDark.opacity(0.8), lineWidth: 1)
            Ellipse()
                .fill(.white.opacity(0.35))
                .frame(width: width * 0.45, height: height * 0.25)
                .offset(x: -width * 0.12, y: -height * 0.12)
        }
        .frame(width: width, height: height)
    }
}

/// Stapels munten die groeien met je voortgang.
/// Munten vullen eerst stapel 1, dan stapel 2, enzovoort. Nieuwe munten vallen van boven in beeld.
struct CoinStackView: View {
    /// Aantal munten dat er nu ligt (0...stacks × coinsPerStack).
    let coins: Int
    var stacks = 5
    var coinsPerStack = 20
    /// Grootte: 1 = normaal (app), kleiner voor de widget.
    var scale: CGFloat = 1

    /// Hoeveel een munt "onder" de vorige schuift, zodat het een stapel wordt.
    private var overlap: CGFloat { 6.5 * scale }
    private var coinHeight: CGFloat { 12 * scale }
    private var coinWidth: CGFloat { 46 * scale }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .bottom, spacing: 10 * scale) {
                ForEach(0..<stacks, id: \.self) { stack in
                    VStack(spacing: -overlap) {
                        // Hoogste munt eerst, zodat hij bovenop ligt.
                        ForEach((0..<coinsIn(stack: stack)).reversed(), id: \.self) { _ in
                            CoinView(width: coinWidth, height: coinHeight)
                                .transition(.asymmetric(
                                    insertion: .offset(y: -420).combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }
                    }
                    .frame(height: stackHeight, alignment: .bottom)
                }
            }
            // Tafelblad waar de munten op liggen
            Capsule()
                .fill(.white.opacity(0.12))
                .frame(height: 6 * scale)
                .padding(.top, 2 * scale)
        }
        .animation(.spring(response: 0.55, dampingFraction: 0.6), value: coins)
        .accessibilityElement()
        .accessibilityLabel(Text("\(coins) munten"))
    }

    private var stackHeight: CGFloat {
        CGFloat(coinsPerStack) * (coinHeight - overlap) + overlap + 3 * scale
    }

    private func coinsIn(stack: Int) -> Int {
        min(coinsPerStack, max(0, coins - stack * coinsPerStack))
    }
}

#Preview {
    ZStack {
        Theme.background.ignoresSafeArea()
        CoinStackView(coins: 47)
    }
}
