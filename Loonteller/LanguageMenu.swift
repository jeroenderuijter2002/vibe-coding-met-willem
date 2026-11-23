import SwiftUI
import WidgetKit

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

/// 🌐-knop die de taalkeuze als menu opent.
struct LanguageMenu: View {
    var body: some View {
        Menu {
            LanguagePicker()
        } label: {
            Label("Taal", systemImage: "globe")
        }
    }
}
