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
        let sampleWasAdded = UserDefaults.standard.bool(forKey: sampleFriendsAddedKey)
        
        if !sampleWasAdded {
            // Rule 1: If sample was not added, insert it
            insertSampleFriend(modelContext: modelContext)
            UserDefaults.standard.set(true, forKey: sampleFriendsAddedKey)
        } else {
            // Rule 2: If sample was added before, check if it still exists
            if sampleFriendExists(modelContext: modelContext) {
                // Rule 3: If exists, overwrite the sample
                removeSampleFriendIfExists(modelContext: modelContext)
                insertSampleFriend(modelContext: modelContext)
            } else {
                // Rule 4: If not exists, ignore it
                return
            }
        }
    }
    
    // Insert the sample friend
    private static func insertSampleFriend(modelContext: ModelContext) {
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
    }
    
    // Check if sample friend exists in database
    private static func sampleFriendExists(modelContext: ModelContext) -> Bool {
        let descriptor = FetchDescriptor<Friend>(
            predicate: #Predicate<Friend> { friend in
                friend.id == sampleFriendId
            }
        )
        
        do {
            let existingFriends = try modelContext.fetch(descriptor)
            return !existingFriends.isEmpty
        } catch {
            print("Error checking if sample friend exists: \(error)")
            return false
        }
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
