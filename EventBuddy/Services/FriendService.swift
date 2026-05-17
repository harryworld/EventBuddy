import Foundation
import SwiftUI

@MainActor
class FriendService {
    
    // Deterministic UUID for sample friend
    private static let sampleFriendId = UUID(uuidString: "12345678-1234-1234-1234-123456789ABC")!
    
    // UserDefaults key to track if sample friends were added
    private static let sampleFriendsAddedKey = "EventBuddy.SampleFriendsAdded"
    
    // Add sample friends for demonstration purposes
    static func addSampleFriends(appStore: AppStore) {
        let sampleWasAdded = UserDefaults.standard.bool(forKey: sampleFriendsAddedKey)
        
        if !sampleWasAdded {
            if hasAnyFriends(appStore: appStore) {
                UserDefaults.standard.set(true, forKey: sampleFriendsAddedKey)
                return
            }

            // Rule 1: If sample was not added, insert it
            insertSampleFriend(appStore: appStore)
            UserDefaults.standard.set(true, forKey: sampleFriendsAddedKey)
        } else {
            // Rule 2: If sample was added before, check if it still exists
            if sampleFriendExists(appStore: appStore) {
                // Rule 3: If exists, update the sample instead of deleting and inserting
                updateSampleFriend(appStore: appStore)
            } else {
                // Rule 4: If not exists, ignore it
                return
            }
        }
    }
    
    // Insert the sample friend
    private static func insertSampleFriend(appStore: AppStore) {
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
        
        do {
            try appStore.save(sampleFriend)
        } catch {
            print("Error saving sample friend: \(error)")
        }
    }

    private static func hasAnyFriends(appStore: AppStore) -> Bool {
        do {
            return try appStore.hasFriends()
        } catch {
            print("Error checking existing friends: \(error)")
            return false
        }
    }
    
    // Check if sample friend exists in database
    private static func sampleFriendExists(appStore: AppStore) -> Bool {
        do {
            return try appStore.friend(id: sampleFriendId) != nil
        } catch {
            print("Error checking if sample friend exists: \(error)")
            return false
        }
    }
    
    // Update sample friend
    private static func updateSampleFriend(appStore: AppStore) {
        do {
            if let friend = try appStore.friend(id: sampleFriendId) {
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
                
                try appStore.save(friend)
            }
        } catch {
            print("Error updating sample friend: \(error)")
        }
    }
    
    // Reset sample friends flag (useful for testing or resetting app state)
    static func resetSampleFriendsFlag() {
        UserDefaults.standard.removeObject(forKey: sampleFriendsAddedKey)
    }
}
