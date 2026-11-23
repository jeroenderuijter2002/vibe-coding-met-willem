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
                Section("Loon") {
                    Picker("Soort loon", selection: $payType) {
                        Text("Dagloon").tag(PayType.daily)
                        Text("Uurloon").tag(PayType.hourly)
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Text(payType == .daily ? "Per dag" : "Per uur")
                        Spacer()
                        Text("€")
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
                    Button {
                        if let workDay { onStart(workDay) }
                    } label: {
                        Text("Start mijn dag")
                            .frame(maxWidth: .infinity)
                            .bold()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(workDay == nil)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Start mijn dag")
            .scrollDismissesKeyboard(.immediately)
        }
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
