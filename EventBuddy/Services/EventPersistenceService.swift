import Foundation
import SQLiteData

@MainActor
@Observable
final class EventPersistenceService {
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

    /// Pre-renders the current profile's QR code to the shared app group so the
    /// widget can display it without generating the image itself.
    func refreshProfileQRCodeCache() {
        let profile = (try? currentProfile()) ?? nil
        ProfileQRCodeCache.update(for: profile)
    }

    func fetchEvent(id: UUID) throws -> Event? {
        try events().first { $0.id == id }
    }

    func fetchFriend(id: UUID) throws -> Friend? {
        try friends().first { $0.id == id }
    }

    func fetchProfile(id: UUID) throws -> Profile? {
        try profiles().first { $0.id == id }
    }

    func event(for row: StoredEvent) -> Event {
        (try? fetchEvent(id: row.id)) ?? row.event
    }

    func event(for id: UUID) -> Event? {
        do {
            return try fetchEvent(id: id)
        } catch {
            print("Failed to load event: \(error)")
            return nil
        }
    }

    func friend(for row: StoredFriend) -> Friend {
        (try? fetchFriend(id: row.id)) ?? row.friend
    }

    func friend(for id: UUID) -> Friend? {
        do {
            return try fetchFriend(id: id)
        } catch {
            print("Failed to load friend: \(error)")
            return nil
        }
    }

    func profile(for row: StoredProfile) -> Profile {
        row.profile
    }

    func currentProfile(from rows: [StoredProfile]) -> Profile? {
        selectCurrentProfile(from: rows.map(\.profile))
    }

    func hasAnyFriends() throws -> Bool {
        try database.read { db in
            try !StoredFriend.fetchAll(db).isEmpty
        }
    }

    func hasFriends() -> Bool {
        do {
            return try hasAnyFriends()
        } catch {
            print("Failed to check friends existence: \(error)")
            return false
        }
    }

    func persist(_ event: Event) throws {
        try persist([event])
    }

    func persistCatalogEvents(_ events: [Event]) throws {
        try persist(events, persistsAttendance: false)
    }

    func persist(_ friend: Friend) throws {
        try database.write { db in
            try upsert(friend, in: db)
        }
        saveDidComplete()
    }

    func persist(_ profile: Profile) throws {
        try database.write { db in
            try upsert(profile, in: db)
        }
        refreshProfileQRCodeCache()
        saveDidComplete()
    }

    func persist(_ events: [Event], friends: [Friend] = [], profiles: [Profile] = []) throws {
        try persist(events, friends: friends, profiles: profiles, persistsAttendance: true)
    }

    private func persist(
        _ events: [Event],
        friends: [Friend] = [],
        profiles: [Profile] = [],
        persistsAttendance: Bool
    ) throws {
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
                if persistsAttendance {
                    try upsertAttendance(for: event, in: db)
                }
            }
        }
        if !profiles.isEmpty {
            refreshProfileQRCodeCache()
        }
        saveDidComplete()
    }

    func save(_ event: Event) {
        do {
            try persist(event)
        } catch {
            print("Failed to save event: \(error)")
        }
    }

    func save(_ friend: Friend) {
        do {
            try persist(friend)
        } catch {
            print("Failed to save friend: \(error)")
        }
    }

    func save(_ profile: Profile) {
        do {
            try persist(profile)
        } catch {
            print("Failed to save profile: \(error)")
        }
    }

    func save(events: [Event] = [], friends: [Friend] = [], profiles: [Profile] = []) {
        do {
            try persist(events, friends: friends, profiles: profiles)
        } catch {
            print("Failed to save batch data: \(error)")
        }
    }

    func remove(_ event: Event) throws {
        try removeEvent(id: event.id)
    }

    func remove(_ friend: Friend) throws {
        try removeFriend(id: friend.id)
    }

    func remove(_ profile: Profile) throws {
        try removeProfile(id: profile.id)
    }

    func delete(_ event: Event) {
        do {
            try remove(event)
        } catch {
            print("Failed to delete event: \(error)")
        }
    }

    func delete(_ friend: Friend) {
        do {
            try remove(friend)
        } catch {
            print("Failed to delete friend: \(error)")
        }
    }

    func removeEvent(id: UUID) throws {
        try database.write { db in
            try deleteEvent(id: id, in: db)
        }
        saveDidComplete()
    }

    func removeFriend(id: UUID) throws {
        try database.write { db in
            try deleteFriend(id: id, in: db)
        }
        saveDidComplete()
    }

    func removeProfile(id: UUID) throws {
        try database.write { db in
            try deleteProfile(id: id, in: db)
        }
        refreshProfileQRCodeCache()
        saveDidComplete()
    }

    func deleteFriend(id: UUID) {
        do {
            try removeFriend(id: id)
        } catch {
            print("Failed to delete friend by id: \(error)")
        }
    }

    func deleteFriends() {
        do {
            try removeFriends()
        } catch {
            print("Failed to delete all friends: \(error)")
        }
    }

    func deleteEvents() {
        do {
            try removeEvents()
        } catch {
            print("Failed to delete all events: \(error)")
        }
    }

    func removeEvents() throws {
        try database.write { db in
            try db.execute(sql: #"DELETE FROM "storedEventAttendances""#)
            try db.execute(sql: #"DELETE FROM "storedEventAttendees""#)
            try db.execute(sql: #"DELETE FROM "storedEventWishes""#)
            try db.execute(sql: #"DELETE FROM "storedEvents""#)
        }
        saveDidComplete()
    }

    func removeFriends() throws {
        try database.write { db in
            try db.execute(sql: #"DELETE FROM "storedEventAttendees""#)
            try db.execute(sql: #"DELETE FROM "storedEventWishes""#)
            try db.execute(sql: #"DELETE FROM "storedFriends""#)
        }
        saveDidComplete()
    }

    func removeProfiles() throws {
        try database.write { db in
            try db.execute(sql: #"DELETE FROM "storedProfiles""#)
        }
        refreshProfileQRCodeCache()
        saveDidComplete()
    }

    func replace(events: [Event], friends: [Friend], profiles: [Profile]) throws {
        try database.write { db in
            try db.execute(sql: #"DELETE FROM "storedEventAttendances""#)
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
                try upsertAttendance(for: event, in: db)
            }
        }
        refreshProfileQRCodeCache()
        saveDidComplete()
    }

    private func snapshot() throws -> Snapshot {
        let rows = try database.read { db in
            Rows(
                events: try StoredEvent.fetchAll(db),
                friends: try StoredFriend.fetchAll(db),
                profiles: try StoredProfile.fetchAll(db),
                attendances: try StoredEventAttendance.fetchAll(db),
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

        for attendance in rows.attendances {
            guard let event = eventMap[attendance.eventID] else {
                continue
            }
            event.isAttending = attendance.isAttending
            event.updatedAt = Swift.max(event.updatedAt, attendance.updatedAt)
        }

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
            arguments: [sqliteUUIDString(event.id)]
        )
        try db.execute(
            sql: #"DELETE FROM "storedEventWishes" WHERE "eventID" = ?"#,
            arguments: [sqliteUUIDString(event.id)]
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

    private func upsertAttendance(for event: Event, in db: Database) throws {
        let row = StoredEventAttendance(
            id: EventBuddyDatabase.eventAttendanceRowID(eventID: event.id),
            eventID: event.id,
            isAttending: event.isAttending,
            updatedAt: event.updatedAt
        )
        try StoredEventAttendance.upsert { row.draft }.execute(db)
    }

    private func deleteEvent(id: UUID, in db: Database) throws {
        try db.execute(
            sql: #"DELETE FROM "storedEventAttendances" WHERE "eventID" = ?"#,
            arguments: [sqliteUUIDString(id)]
        )
        try db.execute(
            sql: #"DELETE FROM "storedEventAttendees" WHERE "eventID" = ?"#,
            arguments: [sqliteUUIDString(id)]
        )
        try db.execute(
            sql: #"DELETE FROM "storedEventWishes" WHERE "eventID" = ?"#,
            arguments: [sqliteUUIDString(id)]
        )
        try db.execute(sql: #"DELETE FROM "storedEvents" WHERE "id" = ?"#, arguments: [sqliteUUIDString(id)])
    }

    private func deleteFriend(id: UUID, in db: Database) throws {
        try db.execute(
            sql: #"DELETE FROM "storedEventAttendees" WHERE "friendID" = ?"#,
            arguments: [sqliteUUIDString(id)]
        )
        try db.execute(
            sql: #"DELETE FROM "storedEventWishes" WHERE "friendID" = ?"#,
            arguments: [sqliteUUIDString(id)]
        )
        try db.execute(sql: #"DELETE FROM "storedFriends" WHERE "id" = ?"#, arguments: [sqliteUUIDString(id)])
    }

    private func deleteProfile(id: UUID, in db: Database) throws {
        try db.execute(sql: #"DELETE FROM "storedProfiles" WHERE "id" = ?"#, arguments: [sqliteUUIDString(id)])
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
        let attendances: [StoredEventAttendance]
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

private func sqliteUUIDString(_ id: UUID) -> String {
    id.uuidString.lowercased()
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

private extension StoredEventAttendance {
    var draft: Draft {
        Draft(id: id, eventID: eventID, isAttending: isAttending, updatedAt: updatedAt)
    }
}
