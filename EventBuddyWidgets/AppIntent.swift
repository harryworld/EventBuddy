//
//  AppIntent.swift
//  EventBuddyWidgets
//
//  Created by Harry Ng on 2/6/2025.
//

import WidgetKit
import AppIntents

struct EventBuddyWidgetConfigurationIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "EventBuddy Widget Configuration" }
    static var description: IntentDescription { "Configure your EventBuddy widget display options." }

    @Parameter(title: "Widget Type", default: .events)
    var widgetType: WidgetTypeIntent
    
    @Parameter(title: "Event Filter", default: .all)
    var eventFilter: EventFilterIntent
    
    @Parameter(title: "Time Range", default: .week)
    var timeRange: TimeRangeIntent
}

enum WidgetTypeIntent: String, CaseIterable, AppEnum {
    case events = "events"
    case qrCode = "qrCode"
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Widget Type")
    }
    
    static var caseDisplayRepresentations: [WidgetTypeIntent: DisplayRepresentation] {
        [
            .events: DisplayRepresentation(title: "Events"),
            .qrCode: DisplayRepresentation(title: "QR Code")
        ]
    }
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

enum TimeRangeIntent: String, CaseIterable, AppEnum {
    case week = "week"
    case month = "month"
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Time Range")
    }
    
    static var caseDisplayRepresentations: [TimeRangeIntent: DisplayRepresentation] {
        [
            .week: DisplayRepresentation(title: "Next 7 Days"),
            .month: DisplayRepresentation(title: "Next 30 Days")
        ]
    }
}
