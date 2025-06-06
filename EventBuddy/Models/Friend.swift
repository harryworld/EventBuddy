import Foundation
import SwiftData
import SwiftUI

@Model
final class Friend {
    var id: UUID
    var name: String
    var email: String?
    var phone: String?
    var jobTitle: String?
    var company: String?
    var socialMediaHandles: [String: String] = [:]
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    var isFavorite: Bool = false
    
    @Relationship(deleteRule: .nullify, inverse: \Event.attendees)
    var events: [Event] = []
    
    @Relationship(deleteRule: .nullify, inverse: \Event.friendWishes)
    var wishEvents: [Event] = []
    
    init(id: UUID = UUID(), 
         name: String, 
         email: String? = nil, 
         phone: String? = nil, 
         jobTitle: String? = nil,
         company: String? = nil,
         socialMediaHandles: [String: String] = [:], 
         notes: String? = nil,
         isFavorite: Bool = false) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.jobTitle = jobTitle
        self.company = company
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
    
    func update(name: String? = nil,
                email: String? = nil,
                phone: String? = nil,
                jobTitle: String? = nil,
                company: String? = nil,
                socialMediaHandles: [String: String]? = nil,
                notes: String? = nil,
                isFavorite: Bool? = nil) {
        if let name = name { self.name = name }
        if let email = email { self.email = email }
        if let phone = phone { self.phone = phone }
        if let jobTitle = jobTitle { self.jobTitle = jobTitle }
        if let company = company { self.company = company }
        if let socialMediaHandles = socialMediaHandles { self.socialMediaHandles = socialMediaHandles }
        if let notes = notes { self.notes = notes }
        if let isFavorite = isFavorite { self.isFavorite = isFavorite }
        self.updatedAt = Date()
    }
}

// MARK: - Helper Extensions

extension Friend {
    static var preview: Friend {
        Friend(
            name: "John Appleseed",
            email: "john@example.com",
            phone: "+1 (555) 123-4567",
            jobTitle: "iOS Developer",
            company: "Apple Inc.",
            socialMediaHandles: [
                "twitter": "johnappleseed",
                "github": "johnappleseed"
            ],
            notes: "Met at WWDC 2024"
        )
    }
} 
