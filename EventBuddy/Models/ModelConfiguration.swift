import Foundation
import SwiftData
import SwiftUI

// MARK: - Schema Versions

enum EventBuddySchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [EventV1.self, Friend.self, Profile.self]
    }
    
    @Model
    final class EventV1 {
        var id: UUID
        var title: String
        var eventDescription: String
        var location: String
        var address: String?
        var startDate: Date
        var endDate: Date
        var eventType: String
        var notes: String?
        var countryCode: String?
        var countryFlag: String?
        var requiresTicket: Bool
        var requiresRegistration: Bool
        var url: String?
        var createdAt: Date
        var updatedAt: Date
        var isAttending: Bool
        var originalTimezoneIdentifier: String?
        // No isCustomEvent property in V1
        
        @Relationship(deleteRule: .cascade)
        var attendees: [Friend] = []
        
        init(id: UUID = UUID(), 
             title: String, 
             eventDescription: String, 
             location: String,
             address: String? = nil,
             startDate: Date, 
             endDate: Date, 
             eventType: String = EventType.social.rawValue,
             notes: String? = nil,
             countryCode: String? = nil,
             countryFlag: String? = nil,
             requiresTicket: Bool = false,
             requiresRegistration: Bool = false,
             url: String? = nil,
             isAttending: Bool = false,
             originalTimezoneIdentifier: String? = nil) {
            self.id = id
            self.title = title
            self.eventDescription = eventDescription
            self.location = location
            self.address = address
            self.startDate = startDate
            self.endDate = endDate
            self.eventType = eventType
            self.notes = notes
            self.countryCode = countryCode
            self.countryFlag = countryFlag
            self.requiresTicket = requiresTicket
            self.requiresRegistration = requiresRegistration
            self.url = url
            self.createdAt = Date()
            self.updatedAt = Date()
            self.isAttending = isAttending
            self.originalTimezoneIdentifier = originalTimezoneIdentifier ?? "America/Los_Angeles"
        }
    }
}

enum EventBuddySchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [Event.self, Friend.self, Profile.self]
    }
}

// MARK: - Migration Plan

enum EventBuddyMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [EventBuddySchemaV1.self, EventBuddySchemaV2.self]
    }
    
    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }
    
    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: EventBuddySchemaV1.self,
        toVersion: EventBuddySchemaV2.self
    )
}

// MARK: - Schema Configuration

struct EventBuddySchema {
    static let sharedModelContainer: ModelContainer = {
        do {
            return try ModelContainer(
                for: Event.self, Friend.self, Profile.self,
                migrationPlan: EventBuddyMigrationPlan.self
            )
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
