import Foundation
import SwiftData
import SwiftUI

struct EventBuddySchema {
    static let sharedModelContainer: ModelContainer = {
        do {
            return try ModelContainer(for: Event.self, Friend.self, Profile.self)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
}

// Example of how to use this in your App
extension SwiftUI.App {
    func setupSwiftDataContainer() -> ModelContainer {
        return EventBuddySchema.sharedModelContainer
    }
}
