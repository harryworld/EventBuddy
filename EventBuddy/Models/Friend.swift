import Foundation
import SwiftData
import SwiftUI

@Model
final class Friend {
    var id: UUID
    var name: String
    var email: String?
    var phone: String?
    var socialMediaHandles: [String: String] = [:]
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    var isFavorite: Bool = false
    
    @Relationship(deleteRule: .cascade, inverse: \Event.attendees)
    var events: [Event] = []
    
    init(id: UUID = UUID(), 
         name: String, 
         email: String? = nil, 
         phone: String? = nil, 
         socialMediaHandles: [String: String] = [:], 
         notes: String? = nil,
         isFavorite: Bool = false) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.socialMediaHandles = socialMediaHandles
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isFavorite = isFavorite
    }

    func toggleFavorite() {
        isFavorite.toggle()
        updatedAt = Date()
    }
}

// MARK: - Helper Extensions

extension Friend {
    static var preview: Friend {
        Friend(
            name: "John Appleseed",
            email: "john@example.com",
            phone: "+1 (555) 123-4567",
            socialMediaHandles: [
                "twitter": "johnappleseed",
                "github": "johnappleseed"
            ],
            notes: "Met at WWDC 2024"
        )
    }
} 
