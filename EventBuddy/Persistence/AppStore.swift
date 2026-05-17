import Foundation
import SQLiteData

@MainActor
@Observable
final class AppStore {
    @ObservationIgnored
    @Dependency(\.defaultDatabase) private var database
    @ObservationIgnored private var deletedEventIDs: Set<UUID> = []
    @ObservationIgnored private var deletedFriendIDs: Set<UUID> = []
    @ObservationIgnored private var deletedProfileIDs: Set<UUID> = []

    var events: [Event] = []
    var friends: [Friend] = []
    var profiles: [Profile] = []

    init() {}

    func reload() throws {
        let snapshot = try database.read { db in
            Snapshot(
                events: try StoredEvent.fetchAll(db),
                friends: try StoredFriend.fetchAll(db),
                profiles: try StoredProfile.fetchAll(db),
                attendees: try StoredEventAttendee.fetchAll(db),
                wishes: try StoredEventWish.fetchAll(db)
            )
        }

        let friendMap = Dictionary(uniqueKeysWithValues: snapshot.friends.map { row in
            let friend = Friend(
                id: row.id,
                name: row.name,
                email: row.email,
                phone: row.phone,
                jobTitle: row.jobTitle,
                company: row.company,
                socialMediaHandles: decodeStringDictionary(row.socialMediaHandlesJSON),
                notes: row.notes,
                isFavorite: row.isFavorite
            )
            friend.createdAt = row.createdAt
            friend.updatedAt = row.updatedAt
            return (friend.id, friend)
        })

        let eventMap = Dictionary(uniqueKeysWithValues: snapshot.events.map { row in
            let event = Event(
                id: row.id,
                title: row.title,
                eventDescription: row.eventDescription,
                location: row.location,
                address: row.address,
                startDate: row.startDate,
                endDate: row.endDate,
                eventType: row.eventType,
                notes: row.notes,
                requiresTicket: row.requiresTicket,
                requiresRegistration: row.requiresRegistration,
                url: row.url,
                isAttending: row.isAttending,
                originalTimezoneIdentifier: row.originalTimezoneIdentifier,
                isCustomEvent: row.isCustomEvent
            )
            event.createdAt = row.createdAt
            event.updatedAt = row.updatedAt
            return (event.id, event)
        })

        for relation in snapshot.attendees {
            guard let event = eventMap[relation.eventID], let friend = friendMap[relation.friendID] else {
                continue
            }
            linkAttendee(friend, to: event)
        }

        for relation in snapshot.wishes {
            guard let event = eventMap[relation.eventID], let friend = friendMap[relation.friendID] else {
                continue
            }
            linkWish(friend, to: event)
        }

        events = eventMap.values.sorted { $0.startDate < $1.startDate }
        friends = friendMap.values.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        profiles = snapshot.profiles.map { row in
            let profile = Profile(
                id: row.id,
                name: row.name,
                bio: row.bio,
                email: row.email,
                phone: row.phone,
                profileImage: row.profileImage,
                socialMediaAccounts: decodeStringDictionary(row.socialMediaAccountsJSON),
                preferences: decodeBoolDictionary(row.preferencesJSON),
                title: row.title,
                company: row.company,
                avatarSystemName: row.avatarSystemName
            )
            profile.createdAt = row.createdAt
            profile.updatedAt = row.updatedAt
            return profile
        }
    }

    func persistAll() throws {
        let eventRows = events.map(StoredEvent.init(event:))
        let friendRows = friends.map(StoredFriend.init(friend:))
        let profileRows = profiles.map(StoredProfile.init(profile:))
        let attendeeRows = events.flatMap { event in
            event.attendees.map {
                StoredEventAttendee(
                    id: EventBuddyDatabase.attendeeRowID(eventID: event.id, friendID: $0.id),
                    eventID: event.id,
                    friendID: $0.id
                )
            }
        }
        let wishRows = events.flatMap { event in
            event.friendWishes.map {
                StoredEventWish(
                    id: EventBuddyDatabase.wishRowID(eventID: event.id, friendID: $0.id),
                    eventID: event.id,
                    friendID: $0.id
                )
            }
        }
        let eventRowIDs = Set(eventRows.map(\.id))
        let friendRowIDs = Set(friendRows.map(\.id))
        let profileRowIDs = Set(profileRows.map(\.id))
        let attendeeRowIDs = Set(attendeeRows.map(\.id))
        let wishRowIDs = Set(wishRows.map(\.id))
        let deletedEventIDs = deletedEventIDs.subtracting(eventRowIDs)
        let deletedFriendIDs = deletedFriendIDs.subtracting(friendRowIDs)
        let deletedProfileIDs = deletedProfileIDs.subtracting(profileRowIDs)

        try database.write { db in
            let existingAttendees = try StoredEventAttendee.fetchAll(db)
            let existingWishes = try StoredEventWish.fetchAll(db)

            for row in eventRows {
                try StoredEvent.upsert { row.draft }.execute(db)
            }

            for row in friendRows {
                try StoredFriend.upsert { row.draft }.execute(db)
            }

            for row in profileRows {
                try StoredProfile.upsert { row.draft }.execute(db)
            }

            for row in attendeeRows {
                try StoredEventAttendee.upsert { row.draft }.execute(db)
            }
            for row in existingAttendees {
                let relationWasRemovedFromLoadedEvent = eventRowIDs.contains(row.eventID) && !attendeeRowIDs.contains(row.id)
                let parentWasDeleted = deletedEventIDs.contains(row.eventID) || deletedFriendIDs.contains(row.friendID)
                if relationWasRemovedFromLoadedEvent || parentWasDeleted {
                    try db.execute(sql: #"DELETE FROM "storedEventAttendees" WHERE "id" = ?"#, arguments: [row.id])
                }
            }

            for row in wishRows {
                try StoredEventWish.upsert { row.draft }.execute(db)
            }
            for row in existingWishes {
                let relationWasRemovedFromLoadedEvent = eventRowIDs.contains(row.eventID) && !wishRowIDs.contains(row.id)
                let parentWasDeleted = deletedEventIDs.contains(row.eventID) || deletedFriendIDs.contains(row.friendID)
                if relationWasRemovedFromLoadedEvent || parentWasDeleted {
                    try db.execute(sql: #"DELETE FROM "storedEventWishes" WHERE "id" = ?"#, arguments: [row.id])
                }
            }

            for id in deletedEventIDs {
                try db.execute(sql: #"DELETE FROM "storedEvents" WHERE "id" = ?"#, arguments: [id.uuidString])
            }

            for id in deletedFriendIDs {
                try db.execute(sql: #"DELETE FROM "storedFriends" WHERE "id" = ?"#, arguments: [id.uuidString])
            }

            for id in deletedProfileIDs {
                try db.execute(sql: #"DELETE FROM "storedProfiles" WHERE "id" = ?"#, arguments: [id.uuidString])
            }
        }

        self.deletedEventIDs.subtract(deletedEventIDs)
        self.deletedFriendIDs.subtract(deletedFriendIDs)
        self.deletedProfileIDs.subtract(deletedProfileIDs)
    }

    func insert(_ event: Event) {
        guard !events.contains(where: { $0.id == event.id }) else { return }
        deletedEventIDs.remove(event.id)
        events.append(event)
        events.sort { $0.startDate < $1.startDate }
    }

    func insert(_ friend: Friend) {
        guard !friends.contains(where: { $0.id == friend.id }) else { return }
        deletedFriendIDs.remove(friend.id)
        friends.append(friend)
        friends.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func insert(_ profile: Profile) {
        guard !profiles.contains(where: { $0.id == profile.id }) else { return }
        deletedProfileIDs.remove(profile.id)
        profiles.append(profile)
    }

    func delete(_ event: Event) {
        deletedEventIDs.insert(event.id)
        events.removeAll { $0.id == event.id }
        for friend in friends {
            friend.events.removeAll { $0.id == event.id }
            friend.wishEvents.removeAll { $0.id == event.id }
        }
    }

    func delete(_ friend: Friend) {
        deletedFriendIDs.insert(friend.id)
        friends.removeAll { $0.id == friend.id }
        for event in events {
            event.removeFriend(friend.id)
            event.removeFriendWish(friend.id)
        }
    }

    func delete(_ profile: Profile) {
        deletedProfileIDs.insert(profile.id)
        profiles.removeAll { $0.id == profile.id }
    }

    func deleteAllEvents() {
        deletedEventIDs.formUnion(events.map(\.id))
        events.removeAll()
        for friend in friends {
            friend.events.removeAll()
            friend.wishEvents.removeAll()
        }
    }

    func deleteAllFriends() {
        deletedFriendIDs.formUnion(friends.map(\.id))
        friends.removeAll()
        for event in events {
            event.attendees.removeAll()
            event.friendWishes.removeAll()
        }
    }

    func deleteAllProfiles() {
        deletedProfileIDs.formUnion(profiles.map(\.id))
        profiles.removeAll()
    }

    private struct Snapshot {
        let events: [StoredEvent]
        let friends: [StoredFriend]
        let profiles: [StoredProfile]
        let attendees: [StoredEventAttendee]
        let wishes: [StoredEventWish]
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
