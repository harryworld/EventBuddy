import Foundation
import SQLiteData

@MainActor
@Observable
final class AppStore {
    @ObservationIgnored
    @Dependency(\.defaultDatabase) private var database
    @ObservationIgnored private let saveDidComplete: @MainActor () -> Void

    init(saveDidComplete: @escaping @MainActor () -> Void = {}) {
        self.saveDidComplete = saveDidComplete
    }

    func events() throws -> [Event] {
        try snapshot().events
    }

    func friends() throws -> [Friend] {
        try snapshot().friends
    }

    func profiles() throws -> [Profile] {
        try snapshot().profiles
    }

    func currentProfile() throws -> Profile? {
        try selectCurrentProfile(from: profiles())
    }

    func event(id: UUID) throws -> Event? {
        try events().first { $0.id == id }
    }

    func friend(id: UUID) throws -> Friend? {
        try friends().first { $0.id == id }
    }

    func profile(id: UUID) throws -> Profile? {
        try profiles().first { $0.id == id }
    }

    func event(for row: StoredEvent) -> Event {
        (try? event(id: row.id)) ?? row.event
    }

    func friend(for row: StoredFriend) -> Friend {
        (try? friend(id: row.id)) ?? row.friend
    }

    func profile(for row: StoredProfile) -> Profile {
        row.profile
    }

    func currentProfile(from rows: [StoredProfile]) -> Profile? {
        selectCurrentProfile(from: rows.map(\.profile))
    }

    func hasFriends() throws -> Bool {
        try database.read { db in
            try !StoredFriend.fetchAll(db).isEmpty
        }
    }

    func save(_ event: Event) throws {
        try save([event])
    }

    func save(_ friend: Friend) throws {
        try database.write { db in
            try upsert(friend, in: db)
        }
        saveDidComplete()
    }

    func save(_ profile: Profile) throws {
        try database.write { db in
            try upsert(profile, in: db)
        }
        saveDidComplete()
    }

    func save(_ events: [Event], friends: [Friend] = [], profiles: [Profile] = []) throws {
        try database.write { db in
            var friendsByID = Dictionary(uniqueKeysWithValues: friends.map { ($0.id, $0) })
            for event in events {
                for friend in event.attendees + event.friendWishes {
                    friendsByID[friend.id] = friend
                }
            }

            for friend in friendsByID.values {
                try upsert(friend, in: db)
            }
            for event in events {
                try upsert(event, in: db)
            }
            for profile in profiles {
                try upsert(profile, in: db)
            }
            for event in events {
                try replaceRelations(for: event, in: db)
            }
        }
        saveDidComplete()
    }

    func delete(_ event: Event) throws {
        try deleteEvent(id: event.id)
    }

    func delete(_ friend: Friend) throws {
        try deleteFriend(id: friend.id)
    }

    func delete(_ profile: Profile) throws {
        try deleteProfile(id: profile.id)
    }

    func deleteEvent(id: UUID) throws {
        try database.write { db in
            try deleteEvent(id: id, in: db)
        }
        saveDidComplete()
    }

    func deleteFriend(id: UUID) throws {
        try database.write { db in
            try deleteFriend(id: id, in: db)
        }
        saveDidComplete()
    }

    func deleteProfile(id: UUID) throws {
        try database.write { db in
            try deleteProfile(id: id, in: db)
        }
        saveDidComplete()
    }

    func deleteEvents() throws {
        try database.write { db in
            try db.execute(sql: #"DELETE FROM "storedEventAttendees""#)
            try db.execute(sql: #"DELETE FROM "storedEventWishes""#)
            try db.execute(sql: #"DELETE FROM "storedEvents""#)
        }
        saveDidComplete()
    }

    func deleteFriends() throws {
        try database.write { db in
            try db.execute(sql: #"DELETE FROM "storedEventAttendees""#)
            try db.execute(sql: #"DELETE FROM "storedEventWishes""#)
            try db.execute(sql: #"DELETE FROM "storedFriends""#)
        }
        saveDidComplete()
    }

    func deleteProfiles() throws {
        try database.write { db in
            try db.execute(sql: #"DELETE FROM "storedProfiles""#)
        }
        saveDidComplete()
    }

    func replace(events: [Event], friends: [Friend], profiles: [Profile]) throws {
        try database.write { db in
            try db.execute(sql: #"DELETE FROM "storedEventAttendees""#)
            try db.execute(sql: #"DELETE FROM "storedEventWishes""#)
            try db.execute(sql: #"DELETE FROM "storedEvents""#)
            try db.execute(sql: #"DELETE FROM "storedFriends""#)
            try db.execute(sql: #"DELETE FROM "storedProfiles""#)

            for friend in friends {
                try upsert(friend, in: db)
            }
            for event in events {
                try upsert(event, in: db)
            }
            for profile in profiles {
                try upsert(profile, in: db)
            }
            for event in events {
                try replaceRelations(for: event, in: db)
            }
        }
        saveDidComplete()
    }

    private func snapshot() throws -> Snapshot {
        let rows = try database.read { db in
            Rows(
                events: try StoredEvent.fetchAll(db),
                friends: try StoredFriend.fetchAll(db),
                profiles: try StoredProfile.fetchAll(db),
                attendees: try StoredEventAttendee.fetchAll(db),
                wishes: try StoredEventWish.fetchAll(db)
            )
        }

        let friendMap = Dictionary(uniqueKeysWithValues: rows.friends.map { row in
            let friend = row.friend
            return (friend.id, friend)
        })

        let eventMap = Dictionary(uniqueKeysWithValues: rows.events.map { row in
            let event = row.event
            return (event.id, event)
        })

        for relation in rows.attendees {
            guard let event = eventMap[relation.eventID], let friend = friendMap[relation.friendID] else {
                continue
            }
            linkAttendee(friend, to: event)
        }

        for relation in rows.wishes {
            guard let event = eventMap[relation.eventID], let friend = friendMap[relation.friendID] else {
                continue
            }
            linkWish(friend, to: event)
        }

        return Snapshot(
            events: eventMap.values.sorted { $0.startDate < $1.startDate },
            friends: friendMap.values.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            },
            profiles: rows.profiles.map(\.profile)
        )
    }

    private func upsert(_ event: Event, in db: Database) throws {
        let row = StoredEvent(event: event)
        try StoredEvent.upsert { row.draft }.execute(db)
    }

    private func upsert(_ friend: Friend, in db: Database) throws {
        let row = StoredFriend(friend: friend)
        try StoredFriend.upsert { row.draft }.execute(db)
    }

    private func upsert(_ profile: Profile, in db: Database) throws {
        let row = StoredProfile(profile: profile)
        try StoredProfile.upsert { row.draft }.execute(db)
    }

    private func replaceRelations(for event: Event, in db: Database) throws {
        try db.execute(
            sql: #"DELETE FROM "storedEventAttendees" WHERE "eventID" = ?"#,
            arguments: [event.id.uuidString]
        )
        try db.execute(
            sql: #"DELETE FROM "storedEventWishes" WHERE "eventID" = ?"#,
            arguments: [event.id.uuidString]
        )

        for friend in event.attendees {
            let row = StoredEventAttendee(
                id: EventBuddyDatabase.attendeeRowID(eventID: event.id, friendID: friend.id),
                eventID: event.id,
                friendID: friend.id
            )
            try StoredEventAttendee.upsert { row.draft }.execute(db)
        }

        for friend in event.friendWishes {
            let row = StoredEventWish(
                id: EventBuddyDatabase.wishRowID(eventID: event.id, friendID: friend.id),
                eventID: event.id,
                friendID: friend.id
            )
            try StoredEventWish.upsert { row.draft }.execute(db)
        }
    }

    private func deleteEvent(id: UUID, in db: Database) throws {
        try db.execute(
            sql: #"DELETE FROM "storedEventAttendees" WHERE "eventID" = ?"#,
            arguments: [id.uuidString]
        )
        try db.execute(
            sql: #"DELETE FROM "storedEventWishes" WHERE "eventID" = ?"#,
            arguments: [id.uuidString]
        )
        try db.execute(sql: #"DELETE FROM "storedEvents" WHERE "id" = ?"#, arguments: [id.uuidString])
    }

    private func deleteFriend(id: UUID, in db: Database) throws {
        try db.execute(
            sql: #"DELETE FROM "storedEventAttendees" WHERE "friendID" = ?"#,
            arguments: [id.uuidString]
        )
        try db.execute(
            sql: #"DELETE FROM "storedEventWishes" WHERE "friendID" = ?"#,
            arguments: [id.uuidString]
        )
        try db.execute(sql: #"DELETE FROM "storedFriends" WHERE "id" = ?"#, arguments: [id.uuidString])
    }

    private func deleteProfile(id: UUID, in db: Database) throws {
        try db.execute(sql: #"DELETE FROM "storedProfiles" WHERE "id" = ?"#, arguments: [id.uuidString])
    }

    private func linkAttendee(_ friend: Friend, to event: Event) {
        if !event.attendees.contains(where: { $0.id == friend.id }) {
            event.attendees.append(friend)
        }
        if !friend.events.contains(where: { $0.id == event.id }) {
            friend.events.append(event)
        }
    }

    private func linkWish(_ friend: Friend, to event: Event) {
        if !event.friendWishes.contains(where: { $0.id == friend.id }) {
            event.friendWishes.append(friend)
        }
        if !friend.wishEvents.contains(where: { $0.id == event.id }) {
            friend.wishEvents.append(event)
        }
    }

    private func selectCurrentProfile(from profiles: [Profile]) -> Profile? {
        profiles.sorted { lhs, rhs in
            let lhsIsPlaceholder = isPlaceholderProfile(lhs)
            let rhsIsPlaceholder = isPlaceholderProfile(rhs)

            if lhsIsPlaceholder != rhsIsPlaceholder {
                return !lhsIsPlaceholder
            }

            return lhs.updatedAt > rhs.updatedAt
        }
        .first
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

    private struct Rows {
        let events: [StoredEvent]
        let friends: [StoredFriend]
        let profiles: [StoredProfile]
        let attendees: [StoredEventAttendee]
        let wishes: [StoredEventWish]
    }

    private struct Snapshot {
        let events: [Event]
        let friends: [Friend]
        let profiles: [Profile]
    }
}

private func decodeStringDictionary(_ json: String) -> [String: String] {
    guard let data = json.data(using: .utf8),
          let value = try? JSONDecoder().decode([String: String].self, from: data)
    else { return [:] }
    return value
}

private func decodeBoolDictionary(_ json: String) -> [String: Bool] {
    guard let data = json.data(using: .utf8),
          let value = try? JSONDecoder().decode([String: Bool].self, from: data)
    else { return [:] }
    return value
}

private func encodeStringDictionary(_ value: [String: String]) -> String {
    guard let data = try? JSONEncoder().encode(value),
          let json = String(data: data, encoding: .utf8)
    else { return "{}" }
    return json
}

private func encodeBoolDictionary(_ value: [String: Bool]) -> String {
    guard let data = try? JSONEncoder().encode(value),
          let json = String(data: data, encoding: .utf8)
    else { return "{}" }
    return json
}

private extension StoredEvent {
    init(event: Event) {
        self.init(
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
            createdAt: event.createdAt,
            updatedAt: event.updatedAt,
            isAttending: event.isAttending,
            originalTimezoneIdentifier: event.originalTimezoneIdentifier,
            isCustomEvent: event.isCustomEvent
        )
    }

    var draft: Draft {
        Draft(
            id: id,
            title: title,
            eventDescription: eventDescription,
            location: location,
            address: address,
            startDate: startDate,
            endDate: endDate,
            eventType: eventType,
            notes: notes,
            requiresTicket: requiresTicket,
            requiresRegistration: requiresRegistration,
            url: url,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isAttending: isAttending,
            originalTimezoneIdentifier: originalTimezoneIdentifier,
            isCustomEvent: isCustomEvent
        )
    }

    var event: Event {
        let event = Event(
            id: id,
            title: title,
            eventDescription: eventDescription,
            location: location,
            address: address,
            startDate: startDate,
            endDate: endDate,
            eventType: eventType,
            notes: notes,
            requiresTicket: requiresTicket,
            requiresRegistration: requiresRegistration,
            url: url,
            isAttending: isAttending,
            originalTimezoneIdentifier: originalTimezoneIdentifier,
            isCustomEvent: isCustomEvent
        )
        event.createdAt = createdAt
        event.updatedAt = updatedAt
        return event
    }
}

private extension StoredFriend {
    init(friend: Friend) {
        self.init(
            id: friend.id,
            name: friend.name,
            email: friend.email,
            phone: friend.phone,
            jobTitle: friend.jobTitle,
            company: friend.company,
            socialMediaHandlesJSON: encodeStringDictionary(friend.socialMediaHandles),
            notes: friend.notes,
            createdAt: friend.createdAt,
            updatedAt: friend.updatedAt,
            isFavorite: friend.isFavorite
        )
    }

    var draft: Draft {
        Draft(
            id: id,
            name: name,
            email: email,
            phone: phone,
            jobTitle: jobTitle,
            company: company,
            socialMediaHandlesJSON: socialMediaHandlesJSON,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isFavorite: isFavorite
        )
    }

    var friend: Friend {
        let friend = Friend(
            id: id,
            name: name,
            email: email,
            phone: phone,
            jobTitle: jobTitle,
            company: company,
            socialMediaHandles: decodeStringDictionary(socialMediaHandlesJSON),
            notes: notes,
            isFavorite: isFavorite
        )
        friend.createdAt = createdAt
        friend.updatedAt = updatedAt
        return friend
    }
}

private extension StoredProfile {
    init(profile: Profile) {
        self.init(
            id: profile.id,
            name: profile.name,
            bio: profile.bio,
            email: profile.email,
            phone: profile.phone,
            profileImage: profile.profileImage,
            socialMediaAccountsJSON: encodeStringDictionary(profile.socialMediaAccounts),
            preferencesJSON: encodeBoolDictionary(profile.preferences),
            createdAt: profile.createdAt,
            updatedAt: profile.updatedAt,
            title: profile.title,
            company: profile.company,
            avatarSystemName: profile.avatarSystemName
        )
    }

    var draft: Draft {
        Draft(
            id: id,
            name: name,
            bio: bio,
            email: email,
            phone: phone,
            profileImage: profileImage,
            socialMediaAccountsJSON: socialMediaAccountsJSON,
            preferencesJSON: preferencesJSON,
            createdAt: createdAt,
            updatedAt: updatedAt,
            title: title,
            company: company,
            avatarSystemName: avatarSystemName
        )
    }

    var profile: Profile {
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

private extension StoredEventAttendee {
    var draft: Draft {
        Draft(id: id, eventID: eventID, friendID: friendID)
    }
}

private extension StoredEventWish {
    var draft: Draft {
        Draft(id: id, eventID: eventID, friendID: friendID)
    }
}
