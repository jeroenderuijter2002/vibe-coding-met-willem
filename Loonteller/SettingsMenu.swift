import SwiftUI
import WidgetKit

/// Sleutels en standaardwaarden van de app-instellingen.
enum AppSettings {
    /// Aantal cijfers achter de komma van de teller in de app.
    static let decimalsKey = "decimalPlaces"
    static let decimalOptions = [2, 3, 4, 5]
}

/// Keuzelijst voor de taal (Systeem / Nederlands / English).
struct LanguagePicker: View {
    @AppStorage(AppLanguage.storageKey, store: WorkDayStore.sharedDefaults)
    private var language: AppLanguage = .system

    var body: some View {
        Picker(selection: $language) {
            Text("Systeem").tag(AppLanguage.system)
            // Taalnamen staan altijd in hun eigen taal, dus niet vertalen.
            Text(verbatim: "Nederlands").tag(AppLanguage.dutch)
            Text(verbatim: "English").tag(AppLanguage.english)
        } label: {
            Label("Taal", systemImage: "globe")
        }
        .onChange(of: language) {
            // De widget moet ook van taal wisselen.
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
}

/// Keuzelijst voor het aantal cijfers achter de komma.
struct DecimalsPicker: View {
    @AppStorage(AppSettings.decimalsKey, store: WorkDayStore.sharedDefaults)
    private var decimals = 2

    var body: some View {
        Picker(selection: $decimals) {
            ForEach(AppSettings.decimalOptions, id: \.self) { count in
                // Voorbeeld: €12,34 / €12,345 / ...
                Text(12.3456789, format: .currency(code: "EUR").precision(.fractionLength(count)))
                    .tag(count)
            }
        } label: {
            Label("Decimalen", systemImage: "number")
        }
    }
}

/// ⚙️-knop met alle instellingen in een menu.
struct SettingsMenu: View {
    var body: some View {
        Menu {
            LanguagePicker()
            DecimalsPicker()
        } label: {
            Label("Instellingen", systemImage: "gearshape.fill")
        }
    }
}
