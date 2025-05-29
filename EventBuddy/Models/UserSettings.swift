import Foundation
import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    
    var icon: String {
        switch self {
        case .system: return "gear"
        case .light: return "sun.max"
        case .dark: return "moon"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum PrivacyLevel: String, CaseIterable, Identifiable {
    case public_ = "public"
    case friendsOnly = "friendsOnly"
    case private_ = "private"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .public_: return "Public"
        case .friendsOnly: return "Friends Only"
        case .private_: return "Private"
        }
    }
    
    var icon: String {
        switch self {
        case .public_: return "globe"
        case .friendsOnly: return "person.2"
        case .private_: return "lock"
        }
    }
}

struct PrivacySettings {
    var profileVisibility: PrivacyLevel = .public_
    var eventsVisibility: PrivacyLevel = .public_
    var friendsListVisibility: PrivacyLevel = .friendsOnly
    var contactInfoVisibility: PrivacyLevel = .friendsOnly
}

@Observable class UserSettings {
    var notificationsEnabled: Bool = true
    var eventReminders: Bool = true
    var friendRequestNotifications: Bool = true
    var eventInviteNotifications: Bool = true
    var appTheme: AppTheme = .system
    var privacySettings: PrivacySettings = PrivacySettings()
    var dataSync: Bool = true
    
    // Add other settings as needed
}

@Observable class SettingsStore {
    var settings: UserSettings
    
    init() {
        self.settings = UserSettings()
    }
    
    func resetToDefaults() {
        settings = UserSettings()
    }
} 