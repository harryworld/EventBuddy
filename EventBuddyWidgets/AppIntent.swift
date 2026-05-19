//
//  AppIntent.swift
//  EventBuddyWidgets
//
//  Created by Harry Ng on 2/6/2025.
//

import WidgetKit
import AppIntents

struct EventBuddyWidgetConfigurationIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "WWDCBuddy Widget Configuration"
    static let description: IntentDescription = IntentDescription("Configure your WWDCBuddy widget display options.")

    @Parameter(title: "Attending Only", default: false)
    var attendingOnly: Bool

    @Parameter(title: "Today Only", default: false)
    var todayOnly: Bool

    init() {}

    init(attendingOnly: Bool, todayOnly: Bool) {
        self.attendingOnly = attendingOnly
        self.todayOnly = todayOnly
    }

    var eventFilter: WidgetEventFilter { attendingOnly ? .attending : .all }
    var timeScope: WidgetTimeScope { todayOnly ? .today : .future }
}
