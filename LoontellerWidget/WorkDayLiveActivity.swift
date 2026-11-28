import ActivityKit
import WidgetKit
import SwiftUI

/// Live Activity: op het vergrendelscherm en in het Dynamic Island.
/// De balk en de afteller lopen live mee. Het verdiende bedrag wordt door de app ververst
/// zolang die open is (zie `LiveActivityManager`).
struct WorkDayLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkDayActivityAttributes.self) { context in
            LockScreenView(state: context.state)
                .environment(\.locale, AppLanguage.saved.locale)
                .padding()
                .environment(\.colorScheme, .dark)
                .activityBackgroundTint(Color(red: 0.03, green: 0.14, blue: 0.09).opacity(0.92))
                .activitySystemActionForegroundColor(Theme.gold)
        } dynamicIsland: { context in
            let state = context.state
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(state.earned, format: .currency(code: "EUR"))
                            .bold()
                            .monospacedDigit()
                    } icon: {
                        CoinView(width: 22, height: 8)
                    }
                    .environment(\.locale, AppLanguage.saved.locale)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: state.start...state.end, countsDown: true)
                        .monospacedDigit()
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 80)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        ProgressView(timerInterval: state.start...state.end, countsDown: false) {
                            EmptyView()
                        } currentValueLabel: {
                            EmptyView()
                        }
                        .tint(Theme.gold)
                        Text("Vandaag in totaal: \(state.totalEarnings, format: .currency(code: "EUR"))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .environment(\.locale, AppLanguage.saved.locale)
                }
            } compactLeading: {
                CoinView(width: 20, height: 7)
            } compactTrailing: {
                // Verdiend tot nu toe (ververst door de app zolang die open is).
                Text(state.earned, format: .currency(code: "EUR"))
                    .monospacedDigit()
                    .foregroundStyle(Theme.gold)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .frame(maxWidth: 72)
                    .environment(\.locale, AppLanguage.saved.locale)
            } minimal: {
                CoinView(width: 20, height: 7)
            }
        }
    }
}

private struct LockScreenView: View {
    let state: WorkDayActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label {
                    Text(verbatim: "Loonteller")
                } icon: {
                    CoinView(width: 22, height: 8)
                }
                .font(.headline)
                .foregroundStyle(Theme.goldLight)
                Spacer()
                Text(state.earned, format: .currency(code: "EUR"))
                    .font(.system(.title2, design: .rounded).weight(.heavy))
                    .monospacedDigit()
                    .foregroundStyle(Theme.goldGradient)
            }

            ProgressView(timerInterval: state.start...state.end, countsDown: false) {
                EmptyView()
            } currentValueLabel: {
                EmptyView()
            }
            .tint(Theme.gold)

            HStack {
                Text(state.start, style: .time)
                Spacer()
                Text("Nog \(Text(timerInterval: state.start...state.end, countsDown: true)) te gaan")
                    .monospacedDigit()
                Spacer()
                Text(state.end, style: .time)
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            Text("Vandaag in totaal: \(state.totalEarnings, format: .currency(code: "EUR"))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
