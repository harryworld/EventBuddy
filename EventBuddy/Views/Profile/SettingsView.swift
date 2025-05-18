import SwiftUI

struct SettingsView: View {
    let settingsStore: SettingsStore
    @State private var showingLogoutConfirmation = false
    @State private var showingDeleteAccountConfirmation = false
    
    var body: some View {
        NavigationStack {
            List {
                accountSection
                appearanceSection
                notificationsSection
                privacySection
                dataSection
                supportSection
                logoutSection
            }
            .navigationTitle("Settings")
        }
    }
    
    private var accountSection: some View {
        Section("Account") {
            NavigationLink {
                Text("Account Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            } label: {
                Label("Account Settings", systemImage: "person.circle")
            }
            
            NavigationLink {
                Text("Security")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            } label: {
                Label("Security", systemImage: "lock.shield")
            }
        }
    }
    
    private var appearanceSection: some View {
        Section("Appearance") {
            NavigationLink {
                AppThemeView(settingsStore: settingsStore)
            } label: {
                HStack {
                    Label("App Theme", systemImage: "paintbrush")
                    Spacer()
                    Text(settingsStore.settings.appTheme.displayName)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private var notificationsSection: some View {
        Section("Notifications") {
            let notificationsEnabled = Binding(
                get: { settingsStore.settings.notificationsEnabled },
                set: { settingsStore.settings.notificationsEnabled = $0 }
            )
            
            let eventReminders = Binding(
                get: { settingsStore.settings.eventReminders },
                set: { settingsStore.settings.eventReminders = $0 }
            )
            
            let friendRequestNotifications = Binding(
                get: { settingsStore.settings.friendRequestNotifications },
                set: { settingsStore.settings.friendRequestNotifications = $0 }
            )
            
            let eventInviteNotifications = Binding(
                get: { settingsStore.settings.eventInviteNotifications },
                set: { settingsStore.settings.eventInviteNotifications = $0 }
            )
            
            Toggle(isOn: notificationsEnabled) {
                Label("Enable Notifications", systemImage: "bell")
            }
            
            if settingsStore.settings.notificationsEnabled {
                Toggle(isOn: eventReminders) {
                    Label("Event Reminders", systemImage: "calendar.badge.clock")
                }
                
                Toggle(isOn: friendRequestNotifications) {
                    Label("Friend Requests", systemImage: "person.badge.plus")
                }
                
                Toggle(isOn: eventInviteNotifications) {
                    Label("Event Invitations", systemImage: "envelope")
                }
            }
        }
    }
    
    private var privacySection: some View {
        Section("Privacy") {
            NavigationLink {
                PrivacySettingsView(settingsStore: settingsStore)
            } label: {
                Label("Privacy Settings", systemImage: "hand.raised")
            }
        }
    }
    
    private var dataSection: some View {
        Section("Data") {
            let dataSync = Binding(
                get: { settingsStore.settings.dataSync },
                set: { settingsStore.settings.dataSync = $0 }
            )
            
            Toggle(isOn: dataSync) {
                Label("Sync Data Across Devices", systemImage: "arrow.triangle.2.circlepath.icloud")
            }
            
            NavigationLink {
                VStack {
                    Text("Export Data")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Button("Export All Data") {
                        // Data export action would go here
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
            } label: {
                Label("Export Data", systemImage: "square.and.arrow.up")
            }
        }
    }
    
    private var supportSection: some View {
        Section("Support") {
            NavigationLink {
                Text("Help Center")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            } label: {
                Label("Help Center", systemImage: "questionmark.circle")
            }
            
            NavigationLink {
                Text("Report a Problem")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            } label: {
                Label("Report a Problem", systemImage: "exclamationmark.triangle")
            }
            
            Button {
                // Reset action would go here
                settingsStore.resetToDefaults()
            } label: {
                Label("Reset All Settings", systemImage: "arrow.counterclockwise")
                    .foregroundStyle(.red)
            }
        }
    }
    
    private var logoutSection: some View {
        Section {
            Button {
                showingLogoutConfirmation = true
            } label: {
                Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                    .foregroundStyle(.red)
            }
            
            Button {
                showingDeleteAccountConfirmation = true
            } label: {
                Label("Delete Account", systemImage: "person.crop.circle.badge.xmark")
                    .foregroundStyle(.red)
            }
        }
        .confirmationDialog("Are you sure you want to log out?", isPresented: $showingLogoutConfirmation) {
            Button("Log Out", role: .destructive) {
                // Logout action would go here
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Delete Account?", isPresented: $showingDeleteAccountConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                // Delete account action would go here
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
    }
}

#Preview {
    SettingsView(settingsStore: SettingsStore())
} 