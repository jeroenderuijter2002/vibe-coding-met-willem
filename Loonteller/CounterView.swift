import SwiftUI

/// Het teller-scherm als "money game": munten stapelen zich op, je stijgt in level,
/// en bij mijlpalen (25/50/75/100%) is er een feestje.
struct CounterView: View {
    let workDay: WorkDay
    /// Wordt aangeroepen als je op "Aanpassen" tikt.
    var onEdit: () -> Void

    /// Aantal munten op een volle dag (5 stapels van 20). Eén munt = 1% van je dag.
    private let totalCoins = 100

    /// Totaal verdiend op eerdere, afgemaakte dagen (vandaag tellen we live mee).
    @State private var earlierEarnings: Double = 0
    @State private var streak: Int = 0

    // Feestjes
    @State private var banner: Banner?
    @State private var confettiTrigger = 0

    private struct Banner: Equatable {
        let id = UUID()
        let text: LocalizedStringKey
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            // De rest van het scherm (munten, mijlpalen, level) wordt 4× per seconde bijgewerkt.
            // Het bedrag zelf loopt apart, elk beeldje (zie LiveAmountView).
            TimelineView(.periodic(from: .now, by: 0.25)) { context in
                content(at: context.date)
            }

            // Mijlpaal- of level-up-melding bovenin
            VStack {
                if let banner {
                    Text(banner.text)
                        .font(.title3.bold())
                        .foregroundStyle(.black)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Theme.goldGradient, in: .capsule)
                        .shadow(color: Theme.gold.opacity(0.6), radius: 16)
                        .transition(.move(edge: .top).combined(with: .scale).combined(with: .opacity))
                        .id(banner.id)
                }
                Spacer()
            }
            .padding(.top, 8)
            .animation(.spring(response: 0.5, dampingFraction: 0.65), value: banner)

            ConfettiView(trigger: confettiTrigger)
        }
        .preferredColorScheme(.dark)
        .onAppear(perform: loadStats)
        .sensoryFeedback(.success, trigger: confettiTrigger)
    }

    // MARK: - Inhoud

    @ViewBuilder
    private func content(at now: Date) -> some View {
        let progress = workDay.progress(at: now)
        let earned = workDay.earned(at: now)
        let coins = Int(progress * Double(totalCoins))
        let milestone = Int(progress * 4)            // 0...4 → 25%, 50%, 75%, 100%
        let lifetime = earlierEarnings + earned
        let level = Level.current(for: lifetime)

        VStack(spacing: 18) {
            topBar(level: level, lifetime: lifetime)

            Spacer(minLength: 0)

            // Bedrag
            VStack(spacing: 4) {
                Text(statusText(at: now))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))

                LiveAmountView(workDay: workDay)

                Text("van \(workDay.totalEarnings, format: .currency(code: "EUR"))")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
            }

            // Muntenstapels
            CoinStackView(coins: coins)
                .sensoryFeedback(.impact(weight: .light), trigger: coins)

            Text("1 munt = \(workDay.totalEarnings / Double(totalCoins), format: .currency(code: "EUR"))")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))

            // Voortgang van de dag
            dayProgress(progress: progress, now: now)

            Spacer(minLength: 0)

            HStack {
                Button("Aanpassen", action: onEdit)
                SettingsMenu()
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.bordered)
            .tint(Theme.gold)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .onChange(of: milestone) { old, new in
            guard new > old else { return }
            celebrate(milestone: new)
        }
        .onChange(of: level.number) { old, new in
            guard new > old else { return }
            show(Banner(text: "Level up! \(Text(verbatim: level.emoji)) \(Text(level.title))"))
            confettiTrigger += 1
        }
    }

    private func topBar(level: Level, lifetime: Double) -> some View {
        HStack(alignment: .top) {
            // Level
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(verbatim: level.emoji)
                    Text(level.title)
                        .bold()
                }
                .font(.subheadline)
                .foregroundStyle(Theme.goldLight)

                ProgressView(value: level.progress(for: lifetime))
                    .tint(Theme.gold)
                    .frame(width: 140)

                if let next = level.next {
                    Text("Nog \(next.threshold - lifetime, format: .currency(code: "EUR").precision(.fractionLength(0))) tot \(Text(next.title))")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                } else {
                    Text("Hoogste level bereikt!")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .glassCard()

            Spacer()

            // Streak
            VStack(spacing: 0) {
                Text(verbatim: "🔥 \(streak)")
                    .font(.title3.bold())
                Text("reeks")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.6))
            }
            .glassCard()
        }
    }

    private func dayProgress(progress: Double, now: Date) -> some View {
        VStack(spacing: 6) {
            // Met timerInterval schuift de balk zelf vloeiend mee (niet in sprongetjes).
            ProgressView(timerInterval: workDay.start...workDay.effectiveEnd, countsDown: false) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
            .tint(Theme.gold)
            HStack {
                Text(workDay.start, style: .time)
                Spacer()
                Text(progress, format: .percent.precision(.fractionLength(0)))
                    .bold()
                    .foregroundStyle(Theme.goldLight)
                Spacer()
                Text(workDay.effectiveEnd, style: .time)
            }
            .font(.footnote)
            .foregroundStyle(.white.opacity(0.6))

            if now >= workDay.start && now < workDay.effectiveEnd {
                Text("Nog \(Text(timerInterval: now...workDay.effectiveEnd, countsDown: true)) te gaan")
                    .monospacedDigit()
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    // MARK: - Logica

    private func statusText(at now: Date) -> LocalizedStringKey {
        if now < workDay.start { return "Je dag is nog niet begonnen" }
        if now >= workDay.effectiveEnd { return "Klaar voor vandaag! 🎉" }
        return "Verdiend tot nu toe"
    }

    private func celebrate(milestone: Int) {
        let text: LocalizedStringKey
        switch milestone {
        case 1: text = "Kwart binnen! 💪"
        case 2: text = "Halverwege! 🔥"
        case 3: text = "Bijna daar! 🚀"
        default: text = "Dag voltooid! 🏆"
        }
        show(Banner(text: text))
        confettiTrigger += 1

        if milestone >= 4 {
            Stats.recordCompleted(workDay)
            loadStats()
        }
    }

    private func show(_ newBanner: Banner) {
        banner = newBanner
        Task {
            try? await Task.sleep(for: .seconds(3))
            if banner == newBanner { banner = nil }
        }
    }

    private func loadStats() {
        // Is de dag al klaar (bijv. app later geopend)? Dan meteen opslaan.
        Stats.recordCompleted(workDay)
        // Vandaag tellen we live mee, dus die halen we uit het opgeslagen totaal.
        earlierEarnings = Stats.recordedTotal(excluding: workDay)
        streak = Stats.streak()
    }
}

/// Het grote gouden bedrag. Wordt elk beeldje van het scherm opnieuw getekend (60–120× per seconde),
/// zodat het vloeiend oploopt. Het aantal cijfers achter de komma is in te stellen.
private struct LiveAmountView: View {
    let workDay: WorkDay

    @AppStorage(AppSettings.decimalsKey, store: WorkDayStore.sharedDefaults)
    private var decimals = 2

    var body: some View {
        TimelineView(.animation) { context in
            Text(workDay.earned(at: context.date),
                 format: .currency(code: "EUR").precision(.fractionLength(decimals)))
                .font(.system(size: 58, weight: .heavy, design: .rounded))
                .monospacedDigit()   // cijfers even breed, zodat het bedrag niet heen en weer schuift
                .foregroundStyle(Theme.goldGradient)
                .shadow(color: Theme.gold.opacity(0.4), radius: 12)
                .minimumScaleFactor(0.4)
                .lineLimit(1)
        }
    }
}

#Preview {
    CounterView(
        workDay: WorkDay(
            payType: .hourly,
            amount: 20,
            start: .now.addingTimeInterval(-3 * 3600),
            end: .now.addingTimeInterval(5 * 3600),
            breakMinutes: 30
        ),
        onEdit: {}
    )
}
