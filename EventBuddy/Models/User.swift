import Foundation
import Contacts

@Observable class User: Identifiable {
    let id = UUID()
    var name: String
    var email: String
    var phone: String
    var title: String
    var company: String
    var avatarSystemName: String
    var socialLinks: [SocialLink]
    
    init(
        name: String = "",
        email: String = "",
        phone: String = "",
        title: String = "",
        company: String = "",
        avatarSystemName: String = "person.crop.circle.fill",
        socialLinks: [SocialLink] = []
    ) {
        self.name = name
        self.email = email
        self.phone = phone
        self.title = title
        self.company = company
        self.avatarSystemName = avatarSystemName
        self.socialLinks = socialLinks
    }
    
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
        if !email.isEmpty {
            let emailAddress = CNLabeledValue(
                label: CNLabelHome,
                value: email as NSString
            )
            contact.emailAddresses = [emailAddress]
        }
        
        // Set phone
        if !phone.isEmpty {
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
        
        for socialLink in socialLinks {
            if !socialLink.username.isEmpty {
                let profile = CNSocialProfile(
                    urlString: socialLink.url,
                    username: socialLink.username,
                    userIdentifier: nil,
                    service: socialLink.service.toContactServiceName()
                )
                
                let labeledProfile = CNLabeledValue(
                    label: socialLink.service.toContactServiceName(),
                    value: profile
                )
                
                socialProfiles.append(labeledProfile)
            }
        }
        
        contact.socialProfiles = socialProfiles
        
        return contact
    }
}

enum SocialService: String, CaseIterable, Identifiable {
    case twitter
    case linkedIn
    case github
    case instagram
    case facebook
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .twitter: return "Twitter / X"
        case .linkedIn: return "LinkedIn"
        case .github: return "GitHub"
        case .instagram: return "Instagram"
        case .facebook: return "Facebook"
        }
    }
    
    var icon: String {
        switch self {
        case .twitter: return "bird"
        case .linkedIn: return "network"
        case .github: return "chevron.left.forwardslash.chevron.right"
        case .instagram: return "camera"
        case .facebook: return "person.2.fill"
        }
    }
    
    func toContactServiceName() -> String {
        switch self {
        case .twitter: return CNSocialProfileServiceTwitter
        case .linkedIn: return CNSocialProfileServiceLinkedIn
        case .github: return "GitHub"
        case .instagram: return "Instagram"
        case .facebook: return CNSocialProfileServiceFacebook
        }
    }
}

struct SocialLink: Identifiable {
    let id = UUID()
    var service: SocialService
    var username: String
    var url: String {
        switch service {
        case .twitter:
            return "https://twitter.com/\(username)"
        case .linkedIn:
            return "https://linkedin.com/in/\(username)"
        case .github:
            return "https://github.com/\(username)"
        case .instagram:
            return "https://instagram.com/\(username)"
        case .facebook:
            return "https://facebook.com/\(username)"
        }
    }
}

@Observable class UserStore {
    var currentUser: User
    
    init() {
        // Create a default user profile
        currentUser = User(
            name: "John Appleseed",
            email: "john@example.com",
            phone: "+1 (555) 123-4567",
            title: "iOS Developer",
            company: "Apple Inc.",
            avatarSystemName: "person.crop.circle.fill",
            socialLinks: [
                SocialLink(service: .twitter, username: "johnappleseed"),
                SocialLink(service: .github, username: "johnappleseed"),
                SocialLink(service: .linkedIn, username: "johnappleseed")
            ]
        )
    }
} 