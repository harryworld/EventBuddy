import Foundation
import SwiftUI

@MainActor
class FriendService {
    
    // Deterministic UUID for sample friend
    private static let sampleFriendId = UUID(uuidString: "12345678-1234-1234-1234-123456789ABC")!
    
    // UserDefaults key to track if sample friends were added
    private static let sampleFriendsAddedKey = "EventBuddy.SampleFriendsAdded"
    
    // Add sample friends for demonstration purposes
    static func addSampleFriends(eventPersistenceService: EventPersistenceService) {
        let sampleWasAdded = UserDefaults.standard.bool(forKey: sampleFriendsAddedKey)
        
        if !sampleWasAdded {
            if hasAnyFriends(service: eventPersistenceService) {
                UserDefaults.standard.set(true, forKey: sampleFriendsAddedKey)
                return
            }

            // Rule 1: If sample was not added, insert it
            insertSampleFriend(service: eventPersistenceService)
            UserDefaults.standard.set(true, forKey: sampleFriendsAddedKey)
        } else {
            // Rule 2: If sample was added before, check if it still exists
            if sampleFriendExists(service: eventPersistenceService) {
                // Rule 3: If exists, update the sample instead of deleting and inserting
                updateSampleFriend(service: eventPersistenceService)
            } else {
                // Rule 4: If not exists, ignore it
                return
            }
        }
    }
    
    // Insert the sample friend
    private static func insertSampleFriend(service: EventPersistenceService) {
        let sampleFriend = Friend(
            id: sampleFriendId,
            name: "John Appleseed",
            email: "john@apple.com",
            phone: "+1 (555) 234-5678",
            jobTitle: "Senior Software Engineer",
            company: "Apple Inc.",
            socialMediaHandles: [
                "twitter": "johnapple",
                "linkedin": "johnapple",
                "github": "johnapple"
            ],
            notes: "Works at Apple",
            isFavorite: true
        )

        service.save(sampleFriend)
    }

    private static func hasAnyFriends(service: EventPersistenceService) -> Bool {
        return service.hasFriends()
    }
    
    // Check if sample friend exists in database
    private static func sampleFriendExists(service: EventPersistenceService) -> Bool {
        service.friend(for: sampleFriendId) != nil
    }
    
    // Update sample friend
    private static func updateSampleFriend(service: EventPersistenceService) {
        if let friend = service.friend(for: sampleFriendId) {
            friend.update(
                name: "John Appleseed",
                email: "john@apple.com",
                phone: "+1 (555) 234-5678",
                jobTitle: "Senior Software Engineer",
                company: "Apple Inc.",
                socialMediaHandles: [
                    "twitter": "johnapple",
                    "linkedin": "johnapple",
                    "github": "johnapple"
                ],
                notes: "Works at Apple",
                isFavorite: true
            )
            
            service.save(friend)
        }
    }
    
    // Reset sample friends flag (useful for testing or resetting app state)
    static func resetSampleFriendsFlag() {
        UserDefaults.standard.removeObject(forKey: sampleFriendsAddedKey)
    }
}
