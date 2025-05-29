import SwiftUI

struct SettingsView: View {
    let settingsStore: SettingsStore
    @State private var showingLogoutConfirmation = false
    @State private var showingDeleteAccountConfirmation = false
    
    private let userStore = UserStore()
    
    var body: some View {
        NavigationStack {
            List {
                contactHarrySection
                appearanceSection
                dataSection
            }
            .navigationTitle("Settings")
        }
    }
    
    private var contactHarrySection: some View {
        Section {
            Link(destination: URL(string: "https://twitter.com/harryworld")!) {
                HStack {
                    Label("Twitter / X", systemImage: "bird")
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            
            Link(destination: URL(string: "https://github.com/harryworld")!) {
                HStack {
                    Label("GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            
            Link(destination: URL(string: "https://linkedin.com/in/harryng")!) {
                HStack {
                    Label("LinkedIn", systemImage: "network")
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            
            Link(destination: URL(string: "https://threads.net/harryworld")!) {
                HStack {
                    Label("Threads", systemImage: "text.bubble")
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            
            Link(destination: URL(string: "https://youtube.com/harryworld")!) {
                HStack {
                    Label("YouTube", systemImage: "play.rectangle")
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
        } header: {
            Text("Contact Harry")
        } footer: {
            VStack(alignment: .leading, spacing: 8) {
                Text("Thanks for using EventBuddy! This is an app to help you remembering friends and enjoying all the events.")
                Text("Feel free to DM your feedback to Harry")
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
}

#Preview {
    SettingsView(settingsStore: SettingsStore())
} 