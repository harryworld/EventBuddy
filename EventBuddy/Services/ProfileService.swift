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
            name: "Alex Developer",
            bio: "iOS Developer passionate about SwiftUI and creating amazing user experiences. Love attending tech conferences and meeting fellow developers.",
            email: "alex@eventbuddy.app",
            phone: "+1 (555) 123-4567",
            profileImage: nil,
            socialMediaAccounts: [
                "twitter": "@alexdev",
                "github": "alexdev",
                "linkedin": "alex-developer"
            ],
            preferences: [
                "darkMode": true,
                "notificationsEnabled": true,
                "shareLocation": false
            ]
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
            ]
        )
        
        modelContext.insert(defaultProfile)
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving default profile: \(error)")
        }
        
        return defaultProfile
    }
} 