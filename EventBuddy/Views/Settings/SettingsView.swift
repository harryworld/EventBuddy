import SwiftUI

struct SettingsView: View {
    let settingsStore: SettingsStore
    @State private var showingLogoutConfirmation = false
    @State private var showingDeleteAccountConfirmation = false
    
    var body: some View {
        NavigationStack {
            List {
                contactHarrySection
                appearanceSection
                shareAppSection
                dataSection
                creditsSection
                aboutProjectSection
            }
            .navigationTitle("Settings")
        }
    }
    
    private var aboutProjectSection: some View {
        Section {
            Link(destination: URL(string: "https://github.com/harryworld/EventBuddy")!) {
                HStack {
                    Label("View on GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
        } header: {
            Text("About EventBuddy")
        } footer: {
            Text("EventBuddy is open source and part of the BuildWithHarry series. Contributions and suggestions are welcome!")
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
    
    private var shareAppSection: some View {
        Section {
            ShareLink(
                item: URL(string: "https://apple.co/4mEeOD5")!,
                subject: Text("Check out EventBuddy!"),
                message: Text("I'm using EventBuddy to connect with friends at WWDC events. Download it here:")
            ) {
                HStack {
                    Label("Share EventBuddy", systemImage: "square.and.arrow.up")
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
        } header: {
            Text("Share")
        } footer: {
            Text("Help your friends discover EventBuddy and connect at WWDC events!")
        }
    }
    
    private var dataSection: some View {
        Section {
            let dataSync = Binding(
                get: { settingsStore.settings.dataSync },
                set: { settingsStore.settings.dataSync = $0 }
            )
            
            Toggle(isOn: dataSync) {
                Label("Sync Data Across Devices", systemImage: "arrow.triangle.2.circlepath.icloud")
            }
            .disabled(true)

            NavigationLink {
                DataExportView()
            } label: {
                Label("Export Data", systemImage: "square.and.arrow.up")
            }
            
            #if DEBUG
            NavigationLink {
                DataExportTestView()
            } label: {
                Label("Create Test Data", systemImage: "testtube.2")
                    .foregroundStyle(.orange)
            }
            #endif
        } header: {
            Text("Data")
        } footer: {
            Text("EventBuddy v\(appVersion) (\(buildNumber))")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
        }
    }
    
    private var creditsSection: some View {
        Section {
            HStack {
                Label("App Icon", systemImage: "app.badge")
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text("Hwang & ChatGPT")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Credits")
        } footer: {
            Text("Special thanks to everyone who contributed to making EventBuddy better!")
        }
    }
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
}

#Preview {
    SettingsView(settingsStore: SettingsStore())
} 
