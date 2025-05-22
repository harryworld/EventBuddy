import Foundation
import SwiftData
import SwiftUI

struct EventBuddySchema {
    static let schema = Schema([
        Event.self,
        Friend.self,
        Profile.self
    ])
    
    static let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Event.self,
            Friend.self,
            Profile.self
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema)
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
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

/*
Usage in App:

@main
struct EventBuddyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Event.self, Friend.self, Profile.self])
    }
}
*/ 