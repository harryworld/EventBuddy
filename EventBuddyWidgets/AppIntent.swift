//
//  AppIntent.swift
//  EventBuddyWidgets
//
//  Created by Harry Ng on 2/6/2025.
//

import WidgetKit
import AppIntents

struct EventBuddyWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "WWDCBuddy Widget Configuration" }
    static var description: IntentDescription { "Configure your WWDCBuddy widget display options." }
    static var parameterSummary: some ParameterSummary {
        Summary("Show \(\.$eventFilter) for \(\.$timeScope)")
    }
    
    @Parameter(title: "Event Filter", default: .all)
    var eventFilter: EventFilterIntent
    
    @Parameter(title: "Time Scope", default: .future)
    var timeScope: TimeScopeIntent
}

enum EventFilterIntent: String, CaseIterable, AppEnum {
    case all = "all"
    case attending = "attending"
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Event Filter")
    }
    
    static var caseDisplayRepresentations: [EventFilterIntent: DisplayRepresentation] {
        [
            .all: DisplayRepresentation(title: "All Events"),
            .attending: DisplayRepresentation(title: "Attending Events")
        ]
    }
}

enum TimeScopeIntent: String, CaseIterable, AppEnum {
    case today = "today"
    case future = "future"
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Time Scope")
    }
    
    static var caseDisplayRepresentations: [TimeScopeIntent: DisplayRepresentation] {
        [
            .today: DisplayRepresentation(title: "Today Only"),
            .future: DisplayRepresentation(title: "Future Days")
        ]
    }
}
