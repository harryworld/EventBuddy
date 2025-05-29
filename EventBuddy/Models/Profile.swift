import Foundation
import SwiftData
import SwiftUI
import Contacts

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
    
    // Additional properties for contact sharing
    var title: String = ""
    var company: String = ""
    var avatarSystemName: String = "person.crop.circle.fill"
    
    init(id: UUID = UUID(), 
         name: String, 
         bio: String, 
         email: String? = nil, 
         phone: String? = nil, 
         profileImage: Data? = nil, 
         socialMediaAccounts: [String: String] = [:], 
         preferences: [String: Bool] = [:],
         title: String = "",
         company: String = "",
         avatarSystemName: String = "person.crop.circle.fill") {
        self.id = id
        self.name = name
        self.bio = bio
        self.email = email
        self.phone = phone
        self.profileImage = profileImage
        self.socialMediaAccounts = socialMediaAccounts
        self.preferences = preferences
        self.title = title
        self.company = company
        self.avatarSystemName = avatarSystemName
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    // Update the updatedAt timestamp
    func markAsUpdated() {
        updatedAt = Date()
    }
}

// MARK: - Contact Creation Extension

extension Profile {
    // Create a CNContact object to be encoded in the QR code
    func createContact() -> CNContact {
        let contact = CNMutableContact()

        // Set name
        let nameComponents = name.components(separatedBy: " ")
        if nameComponents.count > 1 {
            contact.givenName = nameComponents[0]
            contact.familyName = nameComponents.dropFirst().joined(separator: " ")
        } else {
            contact.givenName = name
        }

        // Set email
        if let email = email, !email.isEmpty {
            let emailAddress = CNLabeledValue(
                label: CNLabelHome,
                value: email as NSString
            )
            contact.emailAddresses = [emailAddress]
        }

        // Set phone
        if let phone = phone, !phone.isEmpty {
            let phoneNumber = CNLabeledValue(
                label: CNLabelPhoneNumberMobile,
                value: CNPhoneNumber(stringValue: phone)
            )
            contact.phoneNumbers = [phoneNumber]
        }

        // Set job details
        if !title.isEmpty {
            contact.jobTitle = title
        }

        if !company.isEmpty {
            contact.organizationName = company
        }

        // Set social profiles
        var socialProfiles: [CNLabeledValue<CNSocialProfile>] = []

        for (service, username) in socialMediaAccounts {
            if !username.isEmpty {
                let cleanUsername = username.hasPrefix("@") ? String(username.dropFirst()) : username
                let url = socialMediaURL(for: service, username: cleanUsername)
                
                let profile = CNSocialProfile(
                    urlString: url,
                    username: cleanUsername,
                    userIdentifier: nil,
                    service: contactServiceName(for: service)
                )

                let labeledProfile = CNLabeledValue(
                    label: contactServiceName(for: service),
                    value: profile
                )

                socialProfiles.append(labeledProfile)
            }
        }

        contact.socialProfiles = socialProfiles

        return contact
    }
    
    // Helper methods for social media
    private func socialMediaURL(for service: String, username: String) -> String {
        switch service.lowercased() {
        case "twitter":
            return "https://twitter.com/\(username)"
        case "linkedin":
            return "https://linkedin.com/in/\(username)"
        case "github":
            return "https://github.com/\(username)"
        case "instagram":
            return "https://instagram.com/\(username)"
        case "facebook":
            return "https://facebook.com/\(username)"
        case "threads":
            return "https://threads.net/\(username)"
        case "youtube":
            return "https://youtube.com/\(username)"
        default:
            return "https://\(username)"
        }
    }
    
    private func contactServiceName(for service: String) -> String {
        switch service.lowercased() {
        case "twitter": return CNSocialProfileServiceTwitter
        case "linkedin": return CNSocialProfileServiceLinkedIn
        case "github": return "GitHub"
        case "instagram": return "Instagram"
        case "facebook": return CNSocialProfileServiceFacebook
        case "threads": return "Threads"
        case "youtube": return "YouTube"
        default: return service.capitalized
        }
    }
    
    // Helper computed properties for social links
    var socialLinks: [SocialLinkInfo] {
        socialMediaAccounts.compactMap { (service, username) in
            guard !username.isEmpty else { return nil }
            return SocialLinkInfo(
                service: service,
                username: username,
                url: socialMediaURL(for: service, username: username)
            )
        }
    }
}

// MARK: - Helper Types

struct SocialLinkInfo: Identifiable {
    let id = UUID()
    let service: String
    let username: String
    let url: String
    
    var displayName: String {
        switch service.lowercased() {
        case "twitter": return "Twitter / X"
        case "linkedin": return "LinkedIn"
        case "github": return "GitHub"
        case "instagram": return "Instagram"
        case "facebook": return "Facebook"
        case "threads": return "Threads"
        case "youtube": return "YouTube"
        default: return service.capitalized
        }
    }
    
    var icon: String {
        switch service.lowercased() {
        case "twitter": return "bird"
        case "linkedin": return "network"
        case "github": return "chevron.left.forwardslash.chevron.right"
        case "instagram": return "camera"
        case "facebook": return "person.2.fill"
        case "threads": return "text.bubble"
        case "youtube": return "play.rectangle"
        default: return "link"
        }
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
            ],
            title: "iOS Developer",
            company: "Tech Corp",
            avatarSystemName: "person.crop.circle.fill"
        )
    }
}
