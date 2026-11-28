import SwiftUI

/// Laat geld-confetti (💰🪙💵🎉) van boven naar beneden regenen, elke keer dat `trigger` verandert.
struct ConfettiView: View {
    let trigger: Int

    private struct Piece: Identifiable {
        let id = UUID()
        let emoji: String
        let x: CGFloat          // 0...1 van de breedte
        let delay: Double
        let duration: Double
        let rotation: Double
        let size: CGFloat
    }

    @State private var pieces: [Piece] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(pieces) { piece in
                    FallingPiece(piece: piece, area: geo.size)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onChange(of: trigger) {
            let emojis = ["💰", "🪙", "💵", "🎉", "💶", "✨"]
            let burst = (0..<40).map { _ in
                Piece(emoji: emojis.randomElement()!,
                      x: .random(in: 0.02...0.98),
                      delay: .random(in: 0...0.6),
                      duration: .random(in: 1.6...2.8),
                      rotation: .random(in: -360...360),
                      size: .random(in: 22...38))
            }
            pieces.append(contentsOf: burst)
            // Opruimen als alles gevallen is.
            Task {
                try? await Task.sleep(for: .seconds(4))
                pieces.removeAll { piece in burst.contains { $0.id == piece.id } }
            }
        }
    }

    private struct FallingPiece: View {
        let piece: Piece
        let area: CGSize
        @State private var fallen = false

        var body: some View {
            Text(verbatim: piece.emoji)
                .font(.system(size: piece.size))
                .rotationEffect(.degrees(fallen ? piece.rotation : 0))
                .position(x: piece.x * area.width, y: fallen ? area.height + 60 : -60)
                .onAppear {
                    withAnimation(.easeIn(duration: piece.duration).delay(piece.delay)) {
                        fallen = true
                    }
                }
        }
    }
}
