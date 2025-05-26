import Foundation
import SwiftData
import SwiftUI

@Model
final class Profile {
    var id: UUID
    var name: String
    var bio: String
    var email: String?
    var phone: String?
    var profileImage: Data?
    var socialMediaAccounts: [String: String] = [:]
    var preferences: [String: Bool] = [:]
    var createdAt: Date
    var updatedAt: Date
    
    init(id: UUID = UUID(), 
         name: String, 
         bio: String, 
         email: String? = nil, 
         phone: String? = nil, 
         profileImage: Data? = nil, 
         socialMediaAccounts: [String: String] = [:], 
         preferences: [String: Bool] = [:]) {
        self.id = id
        self.name = name
        self.bio = bio
        self.email = email
        self.phone = phone
        self.profileImage = profileImage
        self.socialMediaAccounts = socialMediaAccounts
        self.preferences = preferences
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Helper Extensions

extension Profile {
    static var preview: Profile {
        Profile(
            name: "Jane Developer",
            bio: "iOS Developer passionate about SwiftUI and Apple technologies",
            email: "jane@example.com",
            phone: "+1 (555) 987-6543",
            profileImage: nil,
            socialMediaAccounts: [
                "twitter": "@janedev",
                "github": "janedev",
                "linkedin": "jane-developer"
            ],
            preferences: [
                "darkMode": true,
                "notificationsEnabled": true,
                "shareLocation": false
            ]
        )
    }
}
