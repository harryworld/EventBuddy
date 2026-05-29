import Foundation
import Contacts

@Observable
final class Profile: Identifiable, Hashable {
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
        self.email = Self.normalizedEmail(email)
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

    static func normalizedEmail(_ email: String?) -> String? {
        guard let email else { return nil }
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty else { return nil }
        return trimmedEmail.lowercased()
    }

    static func == (lhs: Profile, rhs: Profile) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
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
        SocialPlatform.urlString(for: service, username: username)
    }
    
    private func contactServiceName(for service: String) -> String {
        switch service.lowercased() {
        case "twitter": return CNSocialProfileServiceTwitter
        case "linkedin": return CNSocialProfileServiceLinkedIn
        case "github": return "GitHub"
        case "mastodon": return "Mastodon"
        case "instagram": return "Instagram"
        case "facebook": return CNSocialProfileServiceFacebook
        case "threads": return "Threads"
        case "youtube": return "YouTube"
        default: return SocialPlatform.displayName(for: service)
        }
    }
    
    // Helper computed properties for social links
    var socialLinks: [SocialLinkInfo] {
        socialMediaAccounts.compactMap { (service, username) in
            guard !username.isEmpty else { return nil }
            let cleanUsername = SocialPlatform.storageUsername(username, for: service)
            return SocialLinkInfo(
                service: service,
                username: cleanUsername,
                url: socialMediaURL(for: service, username: cleanUsername)
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
        SocialPlatform.displayName(for: service)
    }
    
    var displayHandle: String {
        SocialPlatform.displayHandle(for: service, username: username)
    }

    var icon: String {
        SocialPlatform.icon(for: service)
    }
}

enum SocialPlatform {
    static let coreServices = ["twitter", "linkedin", "github", "mastodon", "bluesky"]
    static let allServices = coreServices + ["instagram", "facebook", "threads", "youtube"]

    static func displayName(for service: String) -> String {
        switch service.lowercased() {
        case "twitter": return "Twitter / X"
        case "linkedin": return "LinkedIn"
        case "github": return "GitHub"
        case "mastodon": return "Mastodon"
        case "bluesky": return "Bluesky"
        case "instagram": return "Instagram"
        case "facebook": return "Facebook"
        case "threads": return "Threads"
        case "youtube": return "YouTube"
        default: return service.capitalized
        }
    }

    static func icon(for service: String) -> String {
        switch service.lowercased() {
        case "twitter": return "bird"
        case "linkedin": return "network"
        case "github": return "chevron.left.forwardslash.chevron.right"
        case "mastodon": return "at"
        case "bluesky": return "cloud"
        case "instagram": return "camera"
        case "facebook": return "person.2.fill"
        case "threads": return "text.bubble"
        case "youtube": return "play.rectangle"
        default: return "link"
        }
    }

    static func placeholder(for service: String) -> String {
        switch service.lowercased() {
        case "twitter", "instagram", "threads":
            return "e.g. johndoe (without @)"
        case "linkedin", "github":
            return "e.g. johndoe"
        case "mastodon":
            return "e.g. johndoe@mastodon.social"
        case "bluesky":
            return "e.g. johndoe.bsky.social"
        case "facebook":
            return "e.g. john.doe"
        default:
            return "Username"
        }
    }

    static func storageUsername(_ username: String, for service: String) -> String {
        var trimmed = username.trimmingCharacters(in: .whitespacesAndNewlines)

        // If a full link was pasted, reduce it to just the handle so the UI
        // can display the handle instead of the full URL.
        if trimmed.contains("://"), let extracted = handle(fromURL: trimmed, for: service) {
            trimmed = extracted
        }

        return trimmed.hasPrefix("@") ? String(trimmed.dropFirst()) : trimmed
    }

    /// Extracts the platform handle from a full profile URL.
    private static func handle(fromURL urlString: String, for service: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }

        let host = url.host?.lowercased() ?? ""
        let parts = url.path.split(separator: "/").map(String.init)

        func stripAt(_ value: String) -> String {
            value.hasPrefix("@") ? String(value.dropFirst()) : value
        }

        switch service.lowercased() {
        case "mastodon":
            // https://mastodon.social/@johndoe -> johndoe@mastodon.social
            guard let first = parts.first else { return nil }
            let user = stripAt(first)
            return host.isEmpty ? user : "\(user)@\(host)"
        case "bluesky":
            // https://bsky.app/profile/johndoe.bsky.social -> johndoe.bsky.social
            if let idx = parts.firstIndex(of: "profile"), idx + 1 < parts.count {
                return stripAt(parts[idx + 1])
            }
            return parts.last.map(stripAt)
        case "linkedin":
            // https://linkedin.com/in/johndoe -> johndoe
            if let idx = parts.firstIndex(of: "in"), idx + 1 < parts.count {
                return parts[idx + 1]
            }
            return parts.last
        default:
            // twitter, github, instagram, facebook, threads, youtube, ...
            return parts.first.map(stripAt)
        }
    }

    static func displayHandle(for service: String, username: String) -> String {
        let cleanUsername = storageUsername(username, for: service)
        guard !cleanUsername.isEmpty else { return "" }
        return "@\(cleanUsername)"
    }

    static func urlString(for service: String, username: String) -> String {
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedUsername.contains("://") {
            return trimmedUsername
        }

        let cleanUsername = storageUsername(trimmedUsername, for: service)

        switch service.lowercased() {
        case "twitter":
            return "https://twitter.com/\(cleanUsername)"
        case "linkedin":
            return "https://linkedin.com/in/\(cleanUsername)"
        case "github":
            return "https://github.com/\(cleanUsername)"
        case "mastodon":
            return mastodonURLString(for: cleanUsername)
        case "bluesky":
            return "https://bsky.app/profile/\(cleanUsername)"
        case "instagram":
            return "https://instagram.com/\(cleanUsername)"
        case "facebook":
            return "https://facebook.com/\(cleanUsername)"
        case "threads":
            return "https://threads.net/@\(cleanUsername)"
        case "youtube":
            return "https://youtube.com/\(cleanUsername)"
        default:
            return "https://\(cleanUsername)"
        }
    }

    private static func mastodonURLString(for username: String) -> String {
        let components = username.split(separator: "@", omittingEmptySubsequences: true)

        if components.count >= 2 {
            let user = components[0]
            let host = components.dropFirst().joined(separator: "@")
            return "https://\(host)/@\(user)"
        }

        return "https://mastodon.social/@\(username)"
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
