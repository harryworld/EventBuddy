#if os(macOS)
import SwiftUI

struct MacSettingsWorkspace: View {
    @Environment(EventPersistenceService.self) private var eventPersistenceService
    @Environment(\.scenePhase) private var scenePhase

    let settingsStore: SettingsStore

    @State private var selectedCategory: MacSettingsCategory? = .sync
    @State private var calendarStore = EventCalendarStore()
    @State private var isAddingCalendarEvents = false
    @State private var calendarBatchSummary: EventCalendarStore.BatchAddSummary?
    @State private var cliInstallerStatus: String?
    @State private var presentedSheet: MacSettingsSheet?

    private var activeCategory: MacSettingsCategory {
        selectedCategory ?? .sync
    }

    var body: some View {
        HSplitView {
            List(selection: $selectedCategory) {
                ForEach(MacSettingsCategory.allCases) { category in
                    MacSettingsCategoryRow(category: category)
                        .tag(category)
                }
            }
            .listStyle(.sidebar)
            .frame(minWidth: 230, idealWidth: 250, maxWidth: 280)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    categoryHeader
                    categoryContent
                }
                .padding(24)
                .frame(minWidth: 560, maxWidth: .infinity, alignment: .topLeading)
            }
            .background(Color.eventBuddySystemBackground)
        }
        .background(Color.eventBuddySystemBackground)
        .task {
            await settingsStore.refreshCloudKitAccountAvailability()
            refreshCalendarAuthorization()
        }
        .onAppear {
            refreshCalendarAuthorization()
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            refreshCalendarAuthorization()
        }
        .sheet(item: $presentedSheet) { sheet in
            Group {
                switch sheet {
                case .exportData:
                    DataExportView()
                case .importData:
                    DataImportView()
                case .debugData:
                    #if DEBUG
                    DataExportTestView()
                    #else
                    EmptyView()
                    #endif
                }
            }
            .frame(minWidth: 640, minHeight: 560)
        }
    }

    private var categoryHeader: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: activeCategory.systemImage)
                .font(.title2)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.blue)
                .frame(width: 34, height: 34)
                .background(.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(activeCategory.title)
                    .font(.largeTitle.weight(.semibold))

                Text(activeCategory.subtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    @ViewBuilder
    private var categoryContent: some View {
        switch activeCategory {
        case .general:
            generalSettings
        case .sync:
            syncSettings
        case .calendar:
            calendarSettings
        case .data:
            dataSettings
        case .about:
            aboutSettings
        }
    }

    private var generalSettings: some View {
        VStack(alignment: .leading, spacing: 16) {
            MacSettingsSection(title: "Appearance", systemImage: "paintbrush") {
                VStack(alignment: .leading, spacing: 10) {
                    Text("App Theme")
                        .font(.headline)

                    Picker("App Theme", selection: Binding(
                        get: { settingsStore.settings.appTheme },
                        set: { settingsStore.settings.appTheme = $0 }
                    )) {
                        ForEach(AppTheme.allCases) { theme in
                            Label(theme.displayName, systemImage: theme.icon)
                                .tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .frame(maxWidth: 420)
                }
            }

            MacSettingsSection(title: "Share", systemImage: "square.and.arrow.up") {
                ShareLink(
                    item: URL(string: "https://apple.co/4mEeOD5")!,
                    subject: Text("Check out WWDCBuddy!"),
                    message: Text("I'm using WWDCBuddy to connect with friends at WWDC events.")
                ) {
                    Label("Share WWDCBuddy", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
            }
        }
    }

    private var syncSettings: some View {
        MacSettingsSection(title: "iCloud Sync", systemImage: "arrow.triangle.2.circlepath.icloud") {
            VStack(alignment: .leading, spacing: 14) {
                Toggle(isOn: Binding(
                    get: { settingsStore.settings.cloudKitSyncEnabled },
                    set: { settingsStore.setCloudKitSyncEnabled($0) }
                )) {
                    Label("Sync with iCloud", systemImage: "icloud")
                }
                .disabled(!settingsStore.canToggleCloudKitSync)
                .toggleStyle(.switch)

                Divider()

                MacSettingsValueRow(
                    icon: "person.crop.circle.badge.checkmark",
                    title: "iCloud Account",
                    value: settingsStore.cloudKitAccountAvailability.description
                )

                MacSettingsValueRow(
                    icon: "clock.arrow.circlepath",
                    title: "Last Synced",
                    value: settingsStore.isUpdatingCloudKitSync ? "Syncing..." : settingsStore.cloudKitLastSyncedDescription
                )

                if let cloudKitSyncError = settingsStore.cloudKitSyncError {
                    MacSettingsInlineStatus(icon: "exclamationmark.triangle.fill", message: cloudKitSyncError, tint: .red)
                }

                HStack(spacing: 10) {
                    Button {
                        Task {
                            await settingsStore.refreshCloudKitAccountAvailability()
                        }
                    } label: {
                        Label("Check Account", systemImage: "person.crop.circle.badge.questionmark")
                    }

                    Button {
                        Task {
                            await settingsStore.syncCloudKitIfEnabled()
                        }
                    } label: {
                        Label(settingsStore.isUpdatingCloudKitSync ? "Syncing" : "Sync Now", systemImage: "arrow.clockwise")
                    }
                    .disabled(!settingsStore.settings.cloudKitSyncEnabled || settingsStore.isUpdatingCloudKitSync)
                }
            }
        }
    }

    private var calendarSettings: some View {
        MacSettingsSection(title: "Calendar", systemImage: "calendar") {
            VStack(alignment: .leading, spacing: 14) {
                MacSettingsValueRow(
                    icon: "calendar.badge.checkmark",
                    title: "Access",
                    value: calendarStore.authorizationDescription
                )

                if calendarStore.hasFullAccess {
                    if calendarStore.calendars.isEmpty {
                        MacSettingsInlineStatus(
                            icon: "calendar.badge.exclamationmark",
                            message: "No writable calendars are available.",
                            tint: .orange
                        )
                    } else {
                        HStack(alignment: .center, spacing: 12) {
                            Label("Default Calendar", systemImage: "calendar")
                                .frame(width: 170, alignment: .leading)

                            Picker("Default Calendar", selection: Binding(
                                get: { calendarStore.selectedCalendarIdentifier ?? calendarStore.calendars.first?.id ?? "" },
                                set: { calendarStore.selectedCalendarIdentifier = $0.isEmpty ? nil : $0 }
                            )) {
                                ForEach(calendarStore.calendars) { calendar in
                                    Text(calendar.displayName).tag(calendar.id)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .frame(maxWidth: 320, alignment: .leading)
                        }
                    }

                    Button {
                        addAttendingEventsToCalendar()
                    } label: {
                        Label(
                            isAddingCalendarEvents ? "Adding Events" : "Add Attending Events",
                            systemImage: "calendar.badge.plus"
                        )
                    }
                    .disabled(isAddingCalendarEvents || calendarStore.calendars.isEmpty)

                    if let calendarBatchSummary {
                        MacCalendarBatchSummaryView(summary: calendarBatchSummary)
                    }
                } else {
                    Button {
                        requestCalendarAccess()
                    } label: {
                        Label("Allow Calendar Access", systemImage: "calendar.badge.plus")
                    }
                    .disabled(calendarStore.authorizationStatus == .denied || calendarStore.authorizationStatus == .restricted)

                    if calendarStore.authorizationStatus == .writeOnly {
                        MacSettingsInlineStatus(
                            icon: "info.circle",
                            message: "Full access is needed to skip events already in Calendar.",
                            tint: .secondary
                        )
                    }
                }
            }
        }
    }

    private var dataSettings: some View {
        VStack(alignment: .leading, spacing: 16) {
            MacSettingsSection(title: "Data", systemImage: "externaldrive") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        Button {
                            presentedSheet = .exportData
                        } label: {
                            Label("Export Data", systemImage: "square.and.arrow.up")
                        }

                        Button {
                            presentedSheet = .importData
                        } label: {
                            Label("Import Data", systemImage: "square.and.arrow.down")
                        }
                    }

                    #if DEBUG
                    Button {
                        presentedSheet = .debugData
                    } label: {
                        Label("Create Test Data", systemImage: "testtube.2")
                    }
                    #endif
                }
            }

            MacSettingsSection(title: "Command Line Tool", systemImage: "terminal") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        Button {
                            installCLI()
                        } label: {
                            Label("Install wwdcbuddy", systemImage: "terminal")
                        }
                        .accessibilityLabel("Install wwdcbuddy")
                        .accessibilityHint("Installs the command line shim into your shell path.")

                        Button(role: .destructive) {
                            removeCLI()
                        } label: {
                            Label("Remove wwdcbuddy", systemImage: "trash")
                        }
                        .accessibilityLabel("Remove wwdcbuddy")
                        .accessibilityHint("Removes the installed command line shim from your shell path.")
                    }

                    if let cliInstallerStatus {
                        MacSettingsInlineStatus(
                            icon: cliStatusIsSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill",
                            message: cliInstallerStatus,
                            tint: cliStatusIsSuccess ? .green : .orange
                        )
                    }
                }
            }

            MacSettingsSection(title: "Version", systemImage: "info.circle") {
                MacSettingsValueRow(
                    icon: "app.badge",
                    title: "WWDCBuddy",
                    value: "\(appVersion) (\(buildNumber))"
                )
            }
        }
    }

    private var aboutSettings: some View {
        VStack(alignment: .leading, spacing: 16) {
            MacSettingsSection(title: "Contact Harry", systemImage: "person.crop.circle") {
                VStack(spacing: 0) {
                    MacSettingsLinkRow(title: "Twitter / X", systemImage: "bird", urlString: "https://twitter.com/harryworld")
                    MacSettingsLinkRow(title: "GitHub", systemImage: "chevron.left.forwardslash.chevron.right", urlString: "https://github.com/harryworld")
                    MacSettingsLinkRow(title: "LinkedIn", systemImage: "network", urlString: "https://linkedin.com/in/harryng")
                    MacSettingsLinkRow(title: "Threads", systemImage: "text.bubble", urlString: "https://threads.net/harryworld")
                    MacSettingsLinkRow(title: "YouTube", systemImage: "play.rectangle", urlString: "https://youtube.com/harryworld")
                }
            }

            MacSettingsSection(title: "About", systemImage: "info.circle") {
                VStack(spacing: 0) {
                    MacSettingsLinkRow(title: "Build with Harry", systemImage: "hammer", urlString: "https://buildwithharry.com")
                    MacSettingsLinkRow(title: "Aida Website", systemImage: "globe", urlString: "https://useaida.app")
                    MacSettingsLinkRow(title: "Aida on App Store", systemImage: "apple.logo", urlString: "https://apps.apple.com/us/app/aida-simple-fast-daily-planner/id6757127406")
                    MacSettingsLinkRow(title: "WWDCBuddy on GitHub", systemImage: "chevron.left.forwardslash.chevron.right", urlString: "https://github.com/harryworld/EventBuddy")
                }
            }

            MacSettingsSection(title: "Credits", systemImage: "sparkles") {
                VStack(spacing: 0) {
                    MacSettingsValueRow(icon: "app.badge", title: "App Icon", value: "Codex")
                    MacSettingsLinkRow(
                        title: "twostraws/wwdc",
                        systemImage: "chevron.left.forwardslash.chevron.right",
                        urlString: "https://github.com/twostraws/wwdc"
                    )
                    .accessibilityHint("Opens the community-maintained WWDC event list on GitHub.")
                    MacSettingsLinkRow(
                        title: "CommunityKit Schedule",
                        systemImage: "calendar",
                        urlString: "https://communitykit.social/schedule/"
                    )
                    .accessibilityHint("Opens the CommunityKit WWDC schedule.")
                    MacSettingsLinkRow(
                        title: "Apple Community Events",
                        systemImage: "apple.logo",
                        urlString: "https://developer.apple.com/community/events/"
                    )
                    .accessibilityHint("Opens Apple's community event directory.")
                    MacSettingsLinkRow(
                        title: "WWDC26 Event Source Notes",
                        systemImage: "list.bullet.rectangle",
                        urlString: "https://github.com/harryworld/EventBuddy/blob/main/EventBuddy-WWDC26-EventSources.md"
                    )
                    .accessibilityHint("Opens the detailed source log for WWDC26 event data.")
                }
            }
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    private var cliStatusIsSuccess: Bool {
        guard let cliInstallerStatus else { return false }
        return cliInstallerStatus.hasPrefix("Installed")
            || cliInstallerStatus.hasPrefix("Removed")
            || cliInstallerStatus.hasPrefix("No CLI found")
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
}

private enum MacSettingsCategory: String, CaseIterable, Identifiable, Hashable {
    case general
    case sync
    case calendar
    case data
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general:
            return "General"
        case .sync:
            return "Sync"
        case .calendar:
            return "Calendar"
        case .data:
            return "Data & CLI"
        case .about:
            return "About"
        }
    }

    var subtitle: String {
        switch self {
        case .general:
            return "Appearance and sharing"
        case .sync:
            return "iCloud account and sync status"
        case .calendar:
            return "Calendar access and event export"
        case .data:
            return "Backup, restore, and command line installation"
        case .about:
            return "Links, project details, and credits"
        }
    }

    var systemImage: String {
        switch self {
        case .general:
            return "slider.horizontal.3"
        case .sync:
            return "icloud"
        case .calendar:
            return "calendar"
        case .data:
            return "externaldrive"
        case .about:
            return "info.circle"
        }
    }
}

private enum MacSettingsSheet: String, Identifiable {
    case exportData
    case importData
    case debugData

    var id: String { rawValue }
}

private struct MacSettingsCategoryRow: View {
    let category: MacSettingsCategory

    var body: some View {
        Label(category.title, systemImage: category.systemImage)
            .tag(category)
    }
}

private struct MacSettingsSection<Content: View>: View {
    let title: String
    let systemImage: String
    let content: Content

    init(title: String, systemImage: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: systemImage)
                .font(.headline)

            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.eventBuddySystemGray6, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct MacSettingsValueRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Label(title, systemImage: icon)
                .frame(width: 180, alignment: .leading)

            Text(value)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.callout)
    }
}

private struct MacSettingsInlineStatus: View {
    let icon: String
    let message: String
    let tint: Color

    var body: some View {
        Label(message, systemImage: icon)
            .font(.footnote)
            .foregroundStyle(tint)
            .textSelection(.enabled)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct MacSettingsLinkRow: View {
    let title: String
    let systemImage: String
    let urlString: String

    var body: some View {
        if let url = URL(string: urlString) {
            Link(destination: url) {
                HStack(spacing: 12) {
                    Label(title, systemImage: systemImage)
                        .foregroundStyle(.primary)

                    Spacer()

                    Image(systemName: "arrow.up.right.square")
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 7)
            }
        }
    }
}

private struct MacCalendarBatchSummaryView: View {
    let summary: EventCalendarStore.BatchAddSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            MacSettingsInlineStatus(
                icon: summary.failed > 0 ? "exclamationmark.triangle.fill" : "checkmark.circle.fill",
                message: summary.message,
                tint: summary.failed > 0 ? .orange : .secondary
            )

            if let errorMessage = summary.errorMessage {
                MacSettingsInlineStatus(icon: "xmark.octagon.fill", message: errorMessage, tint: .red)
            }
        }
    }
}
#endif
