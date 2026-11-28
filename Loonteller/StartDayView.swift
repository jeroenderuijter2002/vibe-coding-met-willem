import SwiftUI

/// Het invulscherm: hier vul je de gegevens van vandaag in en start je je dag.
struct StartDayView: View {
    /// Wordt aangeroepen als je op "Start mijn dag" tikt.
    var onStart: (WorkDay) -> Void

    @State private var payType: PayType
    @State private var amount: Double?
    @State private var start: Date
    @State private var end: Date
    @State private var breakMinutes: Int
    // Reizen
    @State private var kilometers: Double?
    @State private var kilometerRate: Double?
    @State private var travelMinutes: Int
    @State private var travelHourlyRate: Double?

    /// - Parameter initial: eerder ingevulde gegevens (bij "Aanpassen"), of `nil` voor standaardwaarden.
    init(initial: WorkDay? = nil, onStart: @escaping (WorkDay) -> Void) {
        self.onStart = onStart
        _payType = State(initialValue: initial?.payType ?? .daily)
        _amount = State(initialValue: initial?.amount)
        _start = State(initialValue: initial?.start ?? Self.today(hour: 7))
        _end = State(initialValue: initial?.end ?? Self.today(hour: 16))
        _breakMinutes = State(initialValue: initial?.breakMinutes ?? 30)
        _kilometers = State(initialValue: initial.map(\.kilometers).flatMap { $0 > 0 ? $0 : nil })
        _kilometerRate = State(initialValue: initial?.kilometerRate ?? WorkDay.defaultKilometerRate)
        _travelMinutes = State(initialValue: initial?.travelMinutes ?? 0)
        _travelHourlyRate = State(initialValue: initial?.travelHourlyRate)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    statsHeader
                }
                .listRowBackground(Color.clear)

                Section("Loon") {
                    Picker("Soort loon", selection: $payType) {
                        Text("Dagloon").tag(PayType.daily)
                        Text("Uurloon").tag(PayType.hourly)
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        if payType == .daily { Text("Per dag") } else { Text("Per uur") }
                        Spacer()
                        Text(verbatim: "€")
                            .foregroundStyle(.secondary)
                        TextField("0,00", value: $amount, format: .number.precision(.fractionLength(0...2)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 120)
                    }
                }

                Section("Werktijden") {
                    DatePicker("Begintijd", selection: $start, displayedComponents: .hourAndMinute)
                    DatePicker("Eindtijd", selection: $end, displayedComponents: .hourAndMinute)
                    Stepper(value: $breakMinutes, in: 0...240, step: 5) {
                        HStack {
                            Text("Pauze")
                            Spacer()
                            Text("\(breakMinutes) min")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section {
                    euroField("Km per dag (heen en terug)", value: $kilometers, showEuro: false, placeholder: "0")
                    euroField("Vergoeding per km", value: $kilometerRate, fractionDigits: 3)
                    Stepper(value: $travelMinutes, in: 0...480, step: 5) {
                        HStack {
                            Text("Reistijd (heen en terug)")
                            Spacer()
                            Text("\(travelMinutes) min")
                                .foregroundStyle(.secondary)
                        }
                    }
                    if travelMinutes > 0 {
                        euroField("Reistijd per uur", value: $travelHourlyRate,
                                  placeholder: payType == .hourly ? "Uurloon" : "0,00")
                    }
                } header: {
                    Text("Reizen")
                } footer: {
                    Text("De reisvergoeding staat in één keer op de teller zodra je dag begint.")
                }

                if let workDay {
                    Section {
                        if workDay.travelEarnings > 0 {
                            breakdownRow("Loon", workDay.wageEarnings)
                            if workDay.kilometerAllowance > 0 {
                                breakdownRow("Kilometervergoeding", workDay.kilometerAllowance)
                            }
                            if workDay.travelTimePay > 0 {
                                breakdownRow("Reistijd", workDay.travelTimePay)
                            }
                        }
                        HStack {
                            Text("Je verdient vandaag")
                            Spacer()
                            Text(workDay.totalEarnings, format: .currency(code: "EUR"))
                                .bold()
                        }
                    }
                }

                Section {
                    // Gebruikt precies de ingevulde begin- en eindtijd, zodat de teller gelijk loopt
                    // met je echte werkdag. Start je te laat (bijv. om 7:30 terwijl je om 7:00 begon),
                    // dan telt hij vanaf 7:00 en staat het geld van dat halfuur er meteen.
                    Button {
                        if let workDay { onStart(workDay) }
                    } label: {
                        Label("Start mijn dag", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                            .bold()
                            .foregroundStyle(.black)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    // Uitzondering: negeert de begintijd en begint nu, met dezelfde lengte.
                    Button {
                        if let workDay { onStart(workDay.starting(at: Date())) }
                    } label: {
                        Label("Begin nu", systemImage: "bolt.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                } footer: {
                    if let workDay {
                        startFooter(for: workDay, now: Date())
                    }
                }
                .disabled(workDay == nil)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                Section("Instellingen") {
                    LanguagePicker()
                    DecimalsPicker()
                }
            }
            .navigationTitle("Start mijn dag")
            .scrollDismissesKeyboard(.immediately)
            .scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { SettingsMenu() }
            }
        }
    }

    /// Bovenaan: je level, totaal verdiend en je streak.
    private var statsHeader: some View {
        let lifetime = Stats.recordedTotal(excluding: nil)
        let level = Level.current(for: lifetime)
        return HStack(spacing: 14) {
            Text(verbatim: level.emoji)
                .font(.system(size: 44))
            VStack(alignment: .leading, spacing: 4) {
                Text(level.title)
                    .font(.headline)
                    .foregroundStyle(Theme.goldLight)
                Text("Totaal verdiend: \(lifetime, format: .currency(code: "EUR"))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ProgressView(value: level.progress(for: lifetime))
                    .tint(Theme.gold)
            }
            Spacer()
            VStack(spacing: 0) {
                Text(verbatim: "🔥 \(Stats.streak())")
                    .font(.title3.bold())
                Text("reeks")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.white.opacity(0.06), in: .rect(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Theme.gold.opacity(0.3), lineWidth: 1))
    }

    /// Uitleg onder de startknoppen: wat de teller gaat doen met de ingevulde tijden.
    @ViewBuilder
    private func startFooter(for workDay: WorkDay, now: Date) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if now >= workDay.effectiveEnd {
                Text("Let op: je eindtijd is al voorbij, dus de teller staat direct op het volle bedrag. Begin je nu pas? Tik dan op \"Begin nu\".")
            } else if now >= workDay.start {
                Text("Je bent om \(Text(workDay.start, style: .time)) begonnen. De teller telt vanaf dat moment, dus wat je sindsdien verdiend hebt staat er meteen.")
            } else {
                Text("De teller begint om \(Text(workDay.start, style: .time)) en stopt om \(Text(workDay.effectiveEnd, style: .time)).")
            }
            Text("\"Begin nu\" negeert je begintijd en begint direct, voor \(Duration.seconds(workDay.shiftDuration), format: .units(allowed: [.hours, .minutes], width: .wide)).")
        }
    }

    /// Een regel met een naam en een invulveld voor een bedrag (of getal) rechts.
    private func euroField(_ title: LocalizedStringKey, value: Binding<Double?>, fractionDigits: Int = 2,
                           showEuro: Bool = true, placeholder: LocalizedStringKey = "0,00") -> some View {
        HStack {
            Text(title)
            Spacer()
            if showEuro {
                Text(verbatim: "€")
                    .foregroundStyle(.secondary)
            }
            TextField(placeholder, value: value, format: .number.precision(.fractionLength(0...fractionDigits)))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 120)
        }
    }

    /// Een regel van de uitsplitsing: naam links, bedrag rechts.
    private func breakdownRow(_ title: LocalizedStringKey, _ value: Double) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value, format: .currency(code: "EUR"))
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    /// De ingevulde werkdag, of `nil` als er nog geen (geldig) bedrag is ingevuld.
    private var workDay: WorkDay? {
        guard let amount, amount > 0 else { return nil }
        return WorkDay(payType: payType, amount: amount, start: start, end: end, breakMinutes: breakMinutes,
                       kilometers: max(0, kilometers ?? 0),
                       kilometerRate: max(0, kilometerRate ?? 0),
                       travelMinutes: travelMinutes,
                       travelHourlyRate: travelHourlyRate.map { max(0, $0) })
    }

    /// Vandaag op een bepaald heel uur, bijvoorbeeld 07:00.
    private static func today(hour: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
    }
}

#Preview {
    StartDayView { _ in }
}
