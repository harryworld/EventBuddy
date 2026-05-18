import Foundation
import SwiftUI

@MainActor
class ProfileService {
    
    // Add sample profile for demonstration purposes
    static func addSampleProfile(appStore: AppStore) {
        // Clear existing profiles first (should only be one)
        clearExistingProfiles(appStore: appStore)
        
        let sampleProfile = Profile(
            name: "John Appleseed",
            bio: "",
            email: "john@apple.com",
            phone: "",
            profileImage: nil,
            socialMediaAccounts: [:],
            preferences: [
                "darkMode": true,
                "notificationsEnabled": true,
                "shareLocation": false
            ],
            title: "iOS Developer",
            company: "Apple Inc.",
            avatarSystemName: "person.crop.circle.fill"
        )
        
        do {
            try appStore.save(sampleProfile)
        } catch {
            print("Error saving sample profile: \(error)")
        }
    }
    
    // Clear existing profiles
    private static func clearExistingProfiles(appStore: AppStore) {
        do {
            try appStore.deleteProfiles()
        } catch {
            print("Error clearing profiles: \(error)")
        }
    }
    
    // Get the current user's profile
    static func getCurrentProfile(appStore: AppStore) -> Profile? {
        do {
            return try appStore.currentProfile()
        } catch {
            print("Error fetching profile: \(error)")
            return nil
        }
    }
    
    // Create a new profile if none exists
    static func createDefaultProfile(appStore: AppStore) -> Profile {
        let defaultProfile = Profile(
            name: "Your Name",
            bio: "Add your bio here",
            email: nil,
            phone: nil,
            profileImage: nil,
            socialMediaAccounts: [:],
            preferences: [
                "darkMode": false,
                "notificationsEnabled": true,
                "shareLocation": false
            ],
            title: "",
            company: "",
            avatarSystemName: "person.crop.circle.fill"
        )
        
        do {
            try appStore.save(defaultProfile)
        } catch {
            print("Error saving default profile: \(error)")
        }
        
        return defaultProfile
    }
    
    // Update profile and save changes
    static func updateProfile(_ profile: Profile, appStore: AppStore) {
        profile.markAsUpdated()
        
        do {
            try appStore.save(profile)
        } catch {
            print("Error updating profile: \(error)")
        }
    }
    
    // Add or update social media account
    static func updateSocialAccount(for profile: Profile, service: String, username: String, appStore: AppStore) {
        if username.isEmpty {
            profile.socialMediaAccounts.removeValue(forKey: service)
        } else {
            let cleanUsername = username.hasPrefix("@") ? String(username.dropFirst()) : username
            profile.socialMediaAccounts[service] = cleanUsername
        }
        
        updateProfile(profile, appStore: appStore)
    }
    
    // Remove social media account
    static func removeSocialAccount(for profile: Profile, service: String, appStore: AppStore) {
        profile.socialMediaAccounts.removeValue(forKey: service)
        updateProfile(profile, appStore: appStore)
    }
} 
