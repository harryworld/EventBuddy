import Foundation
import SwiftData
import SwiftUI

@MainActor
class FriendService {
    
    // Deterministic UUID for sample friend
    private static let sampleFriendId = UUID(uuidString: "12345678-1234-1234-1234-123456789ABC")!
    
    // UserDefaults key to track if sample friends were added
    private static let sampleFriendsAddedKey = "EventBuddy.SampleFriendsAdded"
    
    // Add sample friends for demonstration purposes
    static func addSampleFriends(modelContext: ModelContext) {
        // Check if sample friends were already added using UserDefaults
        if UserDefaults.standard.bool(forKey: sampleFriendsAddedKey) {
            return // Sample friends already added, skip
        }
        
        let sampleFriend = Friend(
            id: sampleFriendId,
            name: "John Appleseed",
            email: "john@apple.com",
            phone: "+1 (555) 234-5678",
            socialMediaHandles: [
                "twitter": "johnapple",
                "linkedin": "johnapple",
                "github": "johnapple"
            ],
            notes: "Works at Apple",
            isFavorite: true
        )
        
        modelContext.insert(sampleFriend)
        
        // Mark sample friends as added in UserDefaults
        UserDefaults.standard.set(true, forKey: sampleFriendsAddedKey)
    }
    
    // Remove sample friend if it exists (to replace with updated data)
    private static func removeSampleFriendIfExists(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Friend>(
            predicate: #Predicate<Friend> { friend in
                friend.id == sampleFriendId
            }
        )
        
        do {
            let existingFriends = try modelContext.fetch(descriptor)
            for friend in existingFriends {
                modelContext.delete(friend)
            }
        } catch {
            print("Error removing existing sample friend: \(error)")
        }
    }

    // Clear existing friends
    private static func clearExistingFriends(modelContext: ModelContext) {
        do {
            try modelContext.delete(model: Friend.self)
        } catch {
            print("Error clearing friends: \(error)")
        }
    }
    
    // Reset sample friends flag (useful for testing or resetting app state)
    static func resetSampleFriendsFlag() {
        UserDefaults.standard.removeObject(forKey: sampleFriendsAddedKey)
    }
}
