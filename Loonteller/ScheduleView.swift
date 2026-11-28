import SwiftUI

/// Het weekrooster: per weekdag of je werkt, je tijden en je reizen.
/// Alles wordt direct opgeslagen; het startscherm past zich meteen aan.
struct ScheduleView: View {
    @AppStorage(WeekSchedule.storageKey, store: WorkDayStore.sharedDefaults)
    private var scheduleData = Data()

    @Environment(\.locale) private var locale

    private var schedule: Binding<WeekSchedule> {
        Binding(get: { WeekSchedule(data: scheduleData) }, set: { scheduleData = $0.data })
    }

    var body: some View {
        Form {
            Section {
                Toggle("Weekrooster gebruiken", isOn: schedule.isEnabled)
            } footer: {
                Text("Op een werkdag wordt het startscherm automatisch ingevuld met de tijden en reizen van die dag. Je tikt zelf op \"Start mijn dag\".")
            }

            Section("Week") {
                ForEach(WeekSchedule.displayOrder, id: \.self) { index in
                    NavigationLink {
                        DayScheduleView(name: weekdayName(index), index: index, week: schedule)
                    } label: {
                        row(index)
                    }
                }
            }
            .disabled(!schedule.wrappedValue.isEnabled)
        }
        .navigationTitle("Weekrooster")
        .scrollContentBackground(.hidden)
        .background(Theme.background.ignoresSafeArea())
    }

    private func row(_ index: Int) -> some View {
        let day = schedule.wrappedValue.days[index]
        return HStack {
            Text(verbatim: weekdayName(index))
            Spacer()
            if day.isWorkDay {
                Group {
                    Text(DaySchedule.date(day.startMinutes, on: .now), style: .time)
                    Text(verbatim: "–")
                    Text(DaySchedule.date(day.endMinutes, on: .now), style: .time)
                }
                .foregroundStyle(.secondary)
            } else {
                Text("Vrij")
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// "Maandag", "Monday", ... in de taal van de app.
    private func weekdayName(_ index: Int) -> String {
        var calendar = Calendar.current
        calendar.locale = locale
        return calendar.standaloneWeekdaySymbols[index].capitalized(with: locale)
    }
}

/// Het rooster van één weekdag.
private struct DayScheduleView: View {
    let name: String
    let index: Int
    @Binding var week: WeekSchedule

    @State private var copied = false

    private var day: Binding<DaySchedule> { $week.days[index] }

    var body: some View {
        Form {
            Toggle("Werkdag", isOn: day.isWorkDay)

            if day.wrappedValue.isWorkDay {
                Section("Werktijden") {
                    DatePicker("Begintijd", selection: time(day.startMinutes), displayedComponents: .hourAndMinute)
                    DatePicker("Eindtijd", selection: time(day.endMinutes), displayedComponents: .hourAndMinute)
                    DurationPickerRow(title: "Pauze", minutes: day.breakMinutes, maxHours: 4)
                }

                Section("Reizen") {
                    HStack {
                        Text("Km per dag (heen en terug)")
                        Spacer()
                        TextField("0", value: day.kilometers, format: .number.precision(.fractionLength(0...1)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 120)
                    }
                    DurationPickerRow(title: "Reistijd (heen en terug)", minutes: day.travelMinutes)
                    if day.wrappedValue.travelMinutes > 0 {
                        DurationPickerRow(title: "Waarvan onbetaald", minutes: day.unpaidTravelMinutes)
                    }
                }

                Section {
                    Button {
                        for other in week.days.indices where other != index && week.days[other].isWorkDay {
                            week.days[other] = week.days[index]
                        }
                        copied = true
                    } label: {
                        Label(copied ? "Gekopieerd!" : "Kopieer naar alle werkdagen",
                              systemImage: copied ? "checkmark" : "doc.on.doc")
                    }
                } footer: {
                    Text("Zet deze tijden en reizen ook op je andere werkdagen.")
                }
            }
        }
        .navigationTitle(name)
        .scrollDismissesKeyboard(.immediately)
        .scrollContentBackground(.hidden)
        .background(Theme.background.ignoresSafeArea())
        .onChange(of: week.days[index]) { copied = false }
    }

    /// Koppelt een tijd in "minuten na middernacht" aan een DatePicker.
    private func time(_ minutes: Binding<Int>) -> Binding<Date> {
        Binding(get: { DaySchedule.date(minutes.wrappedValue, on: .now) },
                set: { minutes.wrappedValue = DaySchedule.minutes(of: $0) })
    }
}

#Preview {
    NavigationStack { ScheduleView() }
}
