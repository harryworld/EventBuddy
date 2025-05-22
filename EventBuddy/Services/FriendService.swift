import Foundation
import SwiftData
import SwiftUI

@MainActor
class FriendService {
    
    // Add sample friends for demonstration purposes
    static func addSampleFriends(modelContext: ModelContext) {
        // Clear existing friends first
        clearExistingFriends(modelContext: modelContext)
        
        let friends = [
            Friend(
                name: "Emily Chen",
                email: "emily@google.com",
                phone: "+1 (555) 123-4567",
                socialMediaHandles: [
                    "linkedin": "emilychen",
                    "github": "emilychen"
                ],
                notes: "Works at Google"
            ),
            
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
            
            Friend(
                name: "Miguel Rodriguez",
                email: "miguel@swiftui.dev",
                phone: "+1 (555) 345-6789",
                socialMediaHandles: [
                    "twitter": "migueldev",
                    "github": "migueldev"
                ],
                notes: "SwiftUI Developer",
                isFavorite: true
            ),
            
            Friend(
                name: "Sarah Thompson",
                email: "sarah@indie.dev",
                phone: "+1 (555) 456-7890",
                socialMediaHandles: [
                    "twitter": "sarahdev",
                    "github": "sarahdev",
                    "linkedin": "saraht"
                ],
                notes: "Indie Developer"
            )
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
