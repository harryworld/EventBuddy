import SwiftUI

struct SettingsView: View {
    let settingsStore: SettingsStore
    @State private var showingLogoutConfirmation = false
    @State private var showingDeleteAccountConfirmation = false
    
    var body: some View {
        NavigationStack {
            List {
                contactHarrySection
                aboutAuthorSection
                appearanceSection
                shareAppSection
                dataSection
                creditsSection
                aboutProjectSection
            }
            .navigationTitle("Settings")
        }
    }

    private var aboutAuthorSection: some View {
        Section {
            Link(destination: URL(string: "https://buildwithharry.com")!) {
                HStack {
                    Label("Build with Harry", systemImage: "hammer")
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }

            Link(destination: URL(string: "https://useaida.app")!) {
                HStack {
                    Label("Aida Website", systemImage: "globe")
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }

            Link(destination: URL(string: "https://apps.apple.com/us/app/aida-simple-fast-daily-planner/id6757127406")!) {
                HStack {
                    Label("Aida on App Store", systemImage: "apple.logo")
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
        } header: {
            Text("About Author")
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
            Text("About WWDCBuddy")
        } footer: {
            Text("WWDCBuddy is open source and part of the BuildWithHarry series. Contributions and suggestions are welcome!")
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
                Text("Thanks for using WWDCBuddy! This is an app to help you remember friends and enjoy WWDC events.")
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
                subject: Text("Check out WWDCBuddy!"),
                message: Text("I'm using WWDCBuddy to connect with friends at WWDC events. Download it here:")
            ) {
                HStack {
                    Label("Share WWDCBuddy", systemImage: "square.and.arrow.up")
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
            Text("Help your friends discover WWDCBuddy and connect at WWDC events!")
        }
    }
    
    private var dataSection: some View {
        Section {
            NavigationLink {
                DataExportView()
            } label: {
                Label("Export Data", systemImage: "square.and.arrow.up")
            }
            
            NavigationLink {
                DataImportView()
            } label: {
                Label("Import Data", systemImage: "square.and.arrow.down")
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
            Text("WWDCBuddy \(appVersion) (\(buildNumber))")
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
            Text("Special thanks to everyone who contributed to making WWDCBuddy better!")
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
