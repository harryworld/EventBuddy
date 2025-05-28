import Foundation
import SwiftData
import SwiftUI

@MainActor
class FriendService {
    
    // Add sample friends for demonstration purposes
    static func addSampleFriends(modelContext: ModelContext) {
        // Clear existing friends first
//        clearExistingFriends(modelContext: modelContext)
        
        let friends = [
            Friend(
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
            ),
        ]
        
        for friend in friends {
            modelContext.insert(friend)
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
} 
