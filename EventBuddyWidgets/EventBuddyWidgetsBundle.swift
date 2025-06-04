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
        EventBuddyWidgetsControl()
        EventBuddyWidgetsLiveActivity()
    }
}
