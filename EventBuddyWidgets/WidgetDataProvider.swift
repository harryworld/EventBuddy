import WidgetKit
import Foundation
import SQLiteData

enum WidgetEventFilter: String, CaseIterable {
    case all
    case attending

    var displayName: String {
        switch self {
        case .all: return "All Events"
        case .attending: return "Attending Events"
        }
    }
}

enum WidgetTimeScope: String, CaseIterable {
    case today
    case future

    var displayName: String {
        switch self {
        case .today: return "Today Only"
        case .future: return "Future Days"
        }
    }
}

@MainActor
class WidgetDataProvider {
    static let shared = WidgetDataProvider()

    private let database: (any DatabaseWriter)?
    private let bootstrapError: Error?

    private init() {
        do {
            database = try EventBuddyDatabase.makeDatabase(attachMetadatabase: false)
            bootstrapError = nil
        } catch {
            database = nil
            bootstrapError = error
            print("Error opening widget database: \(error)")
        }
    }
    
    func getUpcomingEvents(
        filter: WidgetEventFilter = .all,
        timeScope: WidgetTimeScope = .future,
        limit: Int = 5
    ) -> [Event] {
        guard let database else {
            if let bootstrapError {
                print("Widget database unavailable while fetching events: \(bootstrapError)")
            }
            return []
        }

        let now = Date()
        let calendar = Calendar.current

        let startDate: Date
        let endDate: Date
        switch timeScope {
        case .today:
            let today = calendar.dateInterval(of: .day, for: now)
            startDate = today?.start ?? now
            endDate = today?.end ?? now
        case .future:
            startDate = now
            endDate = calendar.date(byAdding: .day, value: 30, to: now) ?? now
        }
        
        do {
            let rows = try database.read { db in
                let events = try StoredEvent.fetchAll(db)
                let attendances = try StoredEventAttendance.fetchAll(db)
                return (events: events, attendances: attendances)
            }
            let attendanceByEventID = Dictionary(
                uniqueKeysWithValues: rows.attendances.map { ($0.eventID, $0.isAttending) }
            )
            
            let allEvents = rows.events.map { row in
                Event.fromStoredEvent(row, isAttending: attendanceByEventID[row.id])
            }
                .filter { event in
                    event.startDate >= startDate && event.startDate < endDate
                }
                .sorted { $0.startDate < $1.startDate }
            
            let filteredEvents: [Event]
            switch filter {
            case .all:
                filteredEvents = allEvents
            case .attending:
                filteredEvents = allEvents.filter { $0.isAttending }
            }
            
            return Array(filteredEvents.prefix(limit))
        } catch {
            print("Error fetching events for widget: \(error)")
            return []
        }
    }
    
    func getNextEvent(filter: WidgetEventFilter = .all) -> Event? {
        return getUpcomingEvents(filter: filter, timeScope: .future, limit: 1).first
    }
    
    func getCurrentProfile() -> Profile? {
        guard let database else {
            if let bootstrapError {
                print("Widget database unavailable while fetching profile: \(bootstrapError)")
            }
            return nil
        }

        do {
            return try database.read { db in
                let rows = try StoredProfile.fetchAll(db)
                let profiles = rows
                    .map { $0.asProfile() }
                    .sorted { $0.updatedAt > $1.updatedAt }

                if let nonPlaceholder = profiles.first(where: { !isPlaceholderProfile($0) }) {
                    return nonPlaceholder
                }

                return profiles.first
            }
        } catch {
            print("Error fetching profile for widget: \(error)")
            return nil
        }
    }
}

private func isPlaceholderProfile(_ profile: Profile) -> Bool {
    (profile.name == "John Appleseed" &&
        profile.email == "john@apple.com" &&
        profile.company == "Apple Inc." &&
        profile.title == "iOS Developer") ||
    (profile.name == "Your Name" &&
        profile.bio == "Add your bio here" &&
        profile.email == nil &&
        (profile.phone ?? "").isEmpty &&
        profile.company.isEmpty &&
        profile.title.isEmpty)
}

private func decodeStringDictionary(_ json: String) -> [String: String] {
    guard let data = json.data(using: .utf8),
          let value = try? JSONDecoder().decode([String: String].self, from: data) else {
        return [:]
    }
    return value
}

private func decodeBoolDictionary(_ json: String) -> [String: Bool] {
    guard let data = json.data(using: .utf8),
          let value = try? JSONDecoder().decode([String: Bool].self, from: data) else {
        return [:]
    }
    return value
}

private extension Event {
    static func fromStoredEvent(_ event: StoredEvent, isAttending: Bool? = nil) -> Event {
        let mapped = Event(
            id: event.id,
            title: event.title,
            eventDescription: event.eventDescription,
            location: event.location,
            address: event.address,
            startDate: event.startDate,
            endDate: event.endDate,
            eventType: event.eventType,
            notes: event.notes,
            requiresTicket: event.requiresTicket,
            requiresRegistration: event.requiresRegistration,
            url: event.url,
            isAttending: isAttending ?? event.isAttending,
            originalTimezoneIdentifier: event.originalTimezoneIdentifier,
            isCustomEvent: event.isCustomEvent
        )
        mapped.createdAt = event.createdAt
        mapped.updatedAt = event.updatedAt
        return mapped
    }
}

private extension StoredProfile {
    func asProfile() -> Profile {
        let profile = Profile(
            id: id,
            name: name,
            bio: bio,
            email: email,
            phone: phone,
            profileImage: profileImage,
            socialMediaAccounts: decodeStringDictionary(socialMediaAccountsJSON),
            preferences: decodeBoolDictionary(preferencesJSON),
            title: title,
            company: company,
            avatarSystemName: avatarSystemName
        )
        profile.createdAt = createdAt
        profile.updatedAt = updatedAt
        return profile
    }
}
