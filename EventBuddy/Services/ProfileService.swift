import Foundation
import SwiftData
import SwiftUI

@MainActor
class ProfileService {
    
    // Add sample profile for demonstration purposes
    static func addSampleProfile(modelContext: ModelContext) {
        // Clear existing profiles first (should only be one)
        clearExistingProfiles(modelContext: modelContext)
        
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
        
        modelContext.insert(sampleProfile)
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving sample profile: \(error)")
        }
    }
    
    // Clear existing profiles
    private static func clearExistingProfiles(modelContext: ModelContext) {
        do {
            try modelContext.delete(model: Profile.self)
        } catch {
            print("Error clearing profiles: \(error)")
        }
    }
    
    // Get the current user's profile
    static func getCurrentProfile(modelContext: ModelContext) -> Profile? {
        let descriptor = FetchDescriptor<Profile>()
        do {
            let profiles = try modelContext.fetch(descriptor)
            return profiles.first
        } catch {
            print("Error fetching profile: \(error)")
            return nil
        }
    }
    
    // Create a new profile if none exists
    static func createDefaultProfile(modelContext: ModelContext) -> Profile {
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
        
        modelContext.insert(defaultProfile)
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving default profile: \(error)")
        }
        
        return defaultProfile
    }
    
    // Update profile and save changes
    static func updateProfile(_ profile: Profile, modelContext: ModelContext) {
        profile.markAsUpdated()
        
        do {
            try modelContext.save()
        } catch {
            print("Error updating profile: \(error)")
        }
    }
    
    // Add or update social media account
    static func updateSocialAccount(for profile: Profile, service: String, username: String, modelContext: ModelContext) {
        if username.isEmpty {
            profile.socialMediaAccounts.removeValue(forKey: service)
        } else {
            let cleanUsername = username.hasPrefix("@") ? String(username.dropFirst()) : username
            profile.socialMediaAccounts[service] = cleanUsername
        }
        
        updateProfile(profile, modelContext: modelContext)
    }
    
    // Remove social media account
    static func removeSocialAccount(for profile: Profile, service: String, modelContext: ModelContext) {
        profile.socialMediaAccounts.removeValue(forKey: service)
        updateProfile(profile, modelContext: modelContext)
    }
} 
