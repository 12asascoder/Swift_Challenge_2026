import WidgetKit
import SwiftUI

@main
struct AMBERWidgetBundle: WidgetBundle {
    var body: some Widget {
        AMBERMoodWidget()
        AMBERLockWidget()
    }
}
