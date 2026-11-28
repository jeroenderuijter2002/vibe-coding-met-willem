import WidgetKit
import SwiftUI

/// Alles wat de widget-extensie aanbiedt: de beginscherm-widget en de Live Activity.
@main
struct LoontellerWidgetBundle: WidgetBundle {
    var body: some Widget {
        LoontellerWidget()
        WorkDayLiveActivity()
    }
}
