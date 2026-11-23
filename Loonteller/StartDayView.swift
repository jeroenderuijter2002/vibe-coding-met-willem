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

    /// - Parameter initial: eerder ingevulde gegevens (bij "Aanpassen"), of `nil` voor standaardwaarden.
    init(initial: WorkDay? = nil, onStart: @escaping (WorkDay) -> Void) {
        self.onStart = onStart
        _payType = State(initialValue: initial?.payType ?? .daily)
        _amount = State(initialValue: initial?.amount)
        _start = State(initialValue: initial?.start ?? Self.today(hour: 7))
        _end = State(initialValue: initial?.end ?? Self.today(hour: 16))
        _breakMinutes = State(initialValue: initial?.breakMinutes ?? 30)
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

                if let workDay {
                    Section {
                        HStack {
                            Text("Je verdient vandaag")
                            Spacer()
                            Text(workDay.totalEarnings, format: .currency(code: "EUR"))
                                .bold()
                        }
                    }
                }

                Section {
                    // Begint direct, met dezelfde lengte als de ingevulde werktijden.
                    Button {
                        if let workDay { onStart(workDay.starting(at: Date())) }
                    } label: {
                        Label("Start nu", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                            .bold()
                            .foregroundStyle(.black)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    // Gebruikt precies de ingevulde begin- en eindtijd.
                    Button {
                        if let workDay { onStart(workDay) }
                    } label: {
                        Text("Start met ingevulde tijden")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                } footer: {
                    if let workDay {
                        if workDay.effectiveEnd <= Date() {
                            Text("Let op: je ingevulde eindtijd is al voorbij. Met \"Start met ingevulde tijden\" staat de teller direct op het volle bedrag.")
                        } else {
                            Text("\"Start nu\" begint direct en duurt \(Duration.seconds(workDay.shiftDuration), format: .units(allowed: [.hours, .minutes], width: .wide)).")
                        }
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

    /// De ingevulde werkdag, of `nil` als er nog geen (geldig) bedrag is ingevuld.
    private var workDay: WorkDay? {
        guard let amount, amount > 0 else { return nil }
        return WorkDay(payType: payType, amount: amount, start: start, end: end, breakMinutes: breakMinutes)
    }

    /// Vandaag op een bepaald heel uur, bijvoorbeeld 07:00.
    private static func today(hour: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
    }
}

#Preview {
    StartDayView { _ in }
}
