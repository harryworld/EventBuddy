import SwiftUI

struct SettingsView: View {
    @Environment(EventPersistenceService.self) private var eventPersistenceService
    @Environment(\.scenePhase) private var scenePhase
    let settingsStore: SettingsStore
    @State private var showingLogoutConfirmation = false
    @State private var showingDeleteAccountConfirmation = false
    @State private var calendarStore = EventCalendarStore()
    @State private var isAddingCalendarEvents = false
    @State private var calendarBatchSummary: EventCalendarStore.BatchAddSummary?
    #if os(macOS)
    @State private var cliInstallerStatus: String?
    #endif
    
    var body: some View {
        NavigationStack {
            List {
                contactHarrySection
                aboutAuthorSection
                appearanceSection
                shareAppSection
                calendarSection
                dataSection
                creditsSection
                aboutProjectSection
            }
            .navigationTitle("Settings")
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            refreshCalendarAuthorization()
        }
        .onAppear {
            refreshCalendarAuthorization()
        }
    }

    private var calendarSection: some View {
        Section {
            HStack {
                Label("Calendar Access", systemImage: "calendar.badge.checkmark")
                    .foregroundStyle(.primary)

                Spacer()

                Text(calendarStore.authorizationDescription)
                    .foregroundStyle(.secondary)
            }

            if calendarStore.hasFullAccess {
                if calendarStore.calendars.isEmpty {
                    Text("No writable calendars are available.")
                        .foregroundStyle(.secondary)
                } else {
                    HStack {
                        Label("Default Calendar", systemImage: "calendar")
                            .foregroundStyle(.primary)
                            .lineLimit(1)

                        Spacer(minLength: 12)

                        Picker(selection: Binding(
                            get: { calendarStore.selectedCalendarIdentifier ?? calendarStore.calendars.first?.id ?? "" },
                            set: { calendarStore.selectedCalendarIdentifier = $0.isEmpty ? nil : $0 }
                        )) {
                            ForEach(calendarStore.calendars) { calendar in
                                Text(calendar.displayName).tag(calendar.id)
                            }
                        } label: {
                            EmptyView()
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                    }
                }

                Button {
                    addAttendingEventsToCalendar()
                } label: {
                    Label(
                        isAddingCalendarEvents ? "Adding Events..." : "Add Attending Events",
                        systemImage: "calendar.badge.plus"
                    )
                }
                .disabled(isAddingCalendarEvents || calendarStore.calendars.isEmpty)

                if let calendarBatchSummary {
                    CalendarBatchSummaryView(summary: calendarBatchSummary)
                }
            } else {
                Button {
                    requestCalendarAccess()
                } label: {
                    Label("Allow Calendar Access", systemImage: "calendar.badge.plus")
                }
                .disabled(calendarStore.authorizationStatus == .denied || calendarStore.authorizationStatus == .restricted)

                if calendarStore.authorizationStatus == .writeOnly {
                    Text("Full calendar access is needed to check for existing events before adding.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Calendar")
        } footer: {
            Text("Calendar choice appears after access is granted. Batch add imports upcoming events marked as attending and skips events already in the selected calendar.")
        }
        .task {
            refreshCalendarAuthorization()
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
            Toggle(isOn: Binding(
                get: { settingsStore.settings.cloudKitSyncEnabled },
                set: { settingsStore.setCloudKitSyncEnabled($0) }
            )) {
                Label("iCloud Sync", systemImage: "arrow.triangle.2.circlepath.icloud")
            }
            .disabled(!settingsStore.canToggleCloudKitSync)

            HStack {
                Label("iCloud Account", systemImage: "person.crop.circle.badge.checkmark")
                    .foregroundStyle(.primary)

                Spacer()

                Text(settingsStore.cloudKitAccountAvailability.description)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label("Last Synced", systemImage: "clock.arrow.circlepath")
                    .foregroundStyle(.primary)

                Spacer()

                Text(settingsStore.isUpdatingCloudKitSync ? "Syncing..." : settingsStore.cloudKitLastSyncedDescription)
                    .foregroundStyle(.secondary)
            }

            if let cloudKitSyncError = settingsStore.cloudKitSyncError {
                Text(cloudKitSyncError)
                    .foregroundStyle(.red)
                    .font(.footnote)
            }

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

            #if os(macOS)
            Button {
                installCLI()
            } label: {
                Label("Install CLI", systemImage: "terminal")
            }
            .accessibilityLabel("Install CLI")
            .accessibilityHint("Installs the wwdcbuddy command line shim into your shell path.")

            Button(role: .destructive) {
                removeCLI()
            } label: {
                Label("Remove CLI", systemImage: "trash")
            }
            .accessibilityLabel("Remove CLI")
            .accessibilityHint("Removes the installed wwdcbuddy command line shim from your shell path.")

            if let cliInstallerStatus {
                Text(cliInstallerStatus)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            #endif
            
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
        .task {
            await settingsStore.refreshCloudKitAccountAvailability()
        }
    }
    
    private var creditsSection: some View {
        Section {
            HStack {
                Label("App Icon", systemImage: "app.badge")
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text("Codex")
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

    private func requestCalendarAccess() {
        Task { @MainActor in
            _ = await calendarStore.requestFullAccess()
            refreshCalendarAuthorization()
        }
    }

    private func refreshCalendarAuthorization() {
        calendarStore.refreshAuthorizationStatus()
    }

    private func addAttendingEventsToCalendar() {
        Task { @MainActor in
            isAddingCalendarEvents = true
            calendarBatchSummary = nil
            defer { isAddingCalendarEvents = false }

            let startOfToday = Calendar.current.startOfDay(for: Date())
            let attendingEvents = (try? eventPersistenceService.events())?
                .filter { $0.isAttending && $0.startDate >= startOfToday } ?? []
            calendarBatchSummary = await calendarStore.addEvents(attendingEvents)
        }
    }

    #if os(macOS)
    private func installCLI() {
        do {
            let installedURL = try CLIInstaller.installShim()
            cliInstallerStatus = "Installed \(installedURL.path)"
        } catch {
            cliInstallerStatus = error.localizedDescription
        }
    }

    private func removeCLI() {
        do {
            let result = try CLIInstaller.removeShim()
            cliInstallerStatus = result.statusMessage
        } catch {
            cliInstallerStatus = error.localizedDescription
        }
    }
    #endif
}

private struct CalendarBatchSummaryView: View {
    let summary: EventCalendarStore.BatchAddSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(summary.message)
                .foregroundStyle(summary.failed > 0 ? .orange : .secondary)

            if let errorMessage = summary.errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            }
        }
        .font(.footnote)
    }
}

#Preview {
    let persistenceService = EventPersistenceService()
    return SettingsView(settingsStore: SettingsStore())
        .environment(persistenceService)
}
