//
//  EventBuddyWidgetsBundle.swift
//  EventBuddyWidgets
//
//  Created by Harry Ng on 2/6/2025.
//

import WidgetKit
import SwiftUI

@main
struct EventBuddyWidgetsBundle: WidgetBundle {
    var body: some Widget {
        EventBuddyWidgets()
        QRCodeWidget()
        #if os(iOS) && canImport(ActivityKit)
        EventBuddyWidgetsLiveActivity()
        #endif
        #if os(iOS)
        if #available(iOS 18, *) {
            EventBuddyWidgetsControl()
        }
        #endif
    }
}
