import Foundation

@Observable class EventFriendService {
    let eventStore: EventStore
    let friendStore: FriendStore
    
    init(eventStore: EventStore, friendStore: FriendStore) {
        self.eventStore = eventStore
        self.friendStore = friendStore
    }
    
    // Add a friend to an event, updates both stores
    func addFriendToEvent(friend: Friend, event: Event) {
        eventStore.addFriendToEvent(eventId: event.id, friendId: friend.id)
        friendStore.addFriendToEvent(friendId: friend.id, eventId: event.id)
    }
    
    // Remove a friend from an event, updates both stores
    func removeFriendFromEvent(friend: Friend, event: Event) {
        eventStore.removeFriendFromEvent(eventId: event.id, friendId: friend.id)
        friendStore.removeFriendFromEvent(friendId: friend.id, eventId: event.id)
    }
    
    // Get all friends attending a specific event
    func getFriendsForEvent(event: Event) -> [Friend] {
        return event.attendingFriends.compactMap { friendId in
            friendStore.getFriendById(friendId)
        }
    }
    
    // Get all events a friend is attending
    func getEventsForFriend(friend: Friend) -> [Event] {
        return friend.attendedEventIds.compactMap { eventId in
            eventStore.getEventById(eventId)
        }
    }
    
    // Check if a friend is attending an event
    func isFriendAttendingEvent(friend: Friend, event: Event) -> Bool {
        return event.isFriendAttending(friend.id)
    }
    
    // Add a new friend and immediately add them to an event
    func addNewFriendToEvent(name: String, event: Event) -> Friend {
        let newFriend = Friend(name: name, meetLocation: event.location, meetTime: Date())
        friendStore.addFriend(newFriend)
        addFriendToEvent(friend: newFriend, event: event)
        return newFriend
    }
    
    // Find a friend that might be the same person (basic matching by name)
    func findExistingFriend(name: String) -> Friend? {
        return friendStore.friends.first { 
            $0.name.lowercased() == name.lowercased() 
        }
    }
} 