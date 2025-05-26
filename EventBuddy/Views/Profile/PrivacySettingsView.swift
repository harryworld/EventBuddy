import SwiftUI

struct PrivacySettingsView: View {
    let settingsStore: SettingsStore
    
    var body: some View {
        List {
            Section {
                privacyControl(
                    title: "Profile Visibility",
                    description: "Who can see your profile",
                    currentLevel: settingsStore.settings.privacySettings.profileVisibility,
                    action: { newLevel in
                        settingsStore.settings.privacySettings.profileVisibility = newLevel
                    }
                )
                
                privacyControl(
                    title: "Events Visibility",
                    description: "Who can see your events",
                    currentLevel: settingsStore.settings.privacySettings.eventsVisibility,
                    action: { newLevel in
                        settingsStore.settings.privacySettings.eventsVisibility = newLevel
                    }
                )
                
                privacyControl(
                    title: "Friends List Visibility",
                    description: "Who can see your friends list",
                    currentLevel: settingsStore.settings.privacySettings.friendsListVisibility,
                    action: { newLevel in
                        settingsStore.settings.privacySettings.friendsListVisibility = newLevel
                    }
                )
                
                privacyControl(
                    title: "Contact Info Visibility",
                    description: "Who can see your contact information",
                    currentLevel: settingsStore.settings.privacySettings.contactInfoVisibility,
                    action: { newLevel in
                        settingsStore.settings.privacySettings.contactInfoVisibility = newLevel
                    }
                )
            }
        }
        .navigationTitle("Privacy Settings")
    }
    
    private func privacyControl(
        title: String,
        description: String,
        currentLevel: PrivacyLevel,
        action: @escaping (PrivacyLevel) -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            Text(description)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Picker("Privacy Level", selection: Binding(
                get: { currentLevel },
                set: { action($0) }
            )) {
                ForEach(PrivacyLevel.allCases) { level in
                    Label(level.displayName, systemImage: level.icon)
                        .tag(level)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        PrivacySettingsView(settingsStore: SettingsStore())
    }
} 