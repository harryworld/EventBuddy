#if os(macOS)
import Contacts
import SQLiteData
import SwiftUI

struct MacProfileWorkspace: View {
    @Environment(EventPersistenceService.self) private var eventPersistenceService
    @FetchAll(StoredProfile.all, animation: .default)
    private var storedProfiles: [StoredProfile]
    @FetchAll(StoredFriend.order(by: \.name), animation: .default)
    private var storedFriends: [StoredFriend]
    @FetchAll(StoredEvent.order(by: \.startDate), animation: .default)
    private var storedEvents: [StoredEvent]

    @State private var showingEditSheet = false
    @State private var qrCodeContact: CNContact?
    @State private var qrCodeRefreshTrigger = UUID()

    private var currentProfile: Profile {
        if let profile = eventPersistenceService.currentProfile(from: storedProfiles) {
            return profile
        }
        return createDefaultProfile()
    }

    private var profileSnapshot: MacProfileContactSnapshot {
        MacProfileContactSnapshot(profile: currentProfile)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 22) {
                        profileSummary
                            .frame(width: 300)

                        mainColumn
                    }

                    VStack(alignment: .leading, spacing: 18) {
                        profileSummary
                        mainColumn
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(Color.eventBuddySystemBackground)
        .sheet(isPresented: $showingEditSheet) {
            ProfileEditView(profile: currentProfile) {
                refreshQRCode()
            }
            .frame(minWidth: 520, minHeight: 560)
        }
        .onAppear {
            refreshQRCode(showFeedback: false)
        }
        .onChange(of: profileSnapshot) { _, _ in
            refreshQRCode(showFeedback: false)
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Profile")
                    .font(.largeTitle.weight(.semibold))

                Text("Contact card and WWDC networking identity")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                showingEditSheet = true
            } label: {
                Label("Edit Profile", systemImage: "pencil")
            }
            .controlSize(.large)
            .keyboardShortcut("e", modifiers: [.command])
        }
    }

    private var profileSummary: some View {
        MacProfilePanel {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .center, spacing: 14) {
                    Image(systemName: currentProfile.avatarSystemName)
                        .resizable()
                        .scaledToFit()
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.blue)
                        .frame(width: 58, height: 58)
                        .padding(12)
                        .background(.blue.opacity(0.12), in: Circle())

                    VStack(alignment: .leading, spacing: 4) {
                        Text(currentProfile.name)
                            .font(.title2.weight(.semibold))
                            .lineLimit(2)

                        if !professionalLine.isEmpty {
                            Text(professionalLine)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                }

                if !currentProfile.bio.isEmpty {
                    Text(currentProfile.bio)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Divider()

                VStack(alignment: .leading, spacing: 12) {
                    MacProfileMetricRow(
                        icon: "person.2.fill",
                        title: "Friends",
                        value: storedFriends.count.formatted()
                    )
                    MacProfileMetricRow(
                        icon: "star.fill",
                        title: "Favorite Friends",
                        value: storedFriends.filter(\.isFavorite).count.formatted()
                    )
                    MacProfileMetricRow(
                        icon: "calendar.badge.checkmark",
                        title: "Attending",
                        value: attendingEventCount.formatted()
                    )
                    MacProfileMetricRow(
                        icon: "clock.arrow.circlepath",
                        title: "Updated",
                        value: currentProfile.updatedAt.formatted(date: .abbreviated, time: .shortened)
                    )
                }
            }
        }
    }

    private var mainColumn: some View {
        VStack(alignment: .leading, spacing: 18) {
            qrCodePanel
            contactPanel
            socialPanel
        }
        .frame(minWidth: 440, maxWidth: .infinity, alignment: .topLeading)
    }

    private var qrCodePanel: some View {
        MacProfilePanel(title: "Contact Card", systemImage: "qrcode") {
            HStack(alignment: .center, spacing: 20) {
                if let contact = qrCodeContact {
                    QRCodeView(contact: contact, size: 188)
                        .id(qrCodeRefreshTrigger)
                        .padding(12)
                        .background(.white, in: RoundedRectangle(cornerRadius: 8))
                } else {
                    ProgressView()
                        .frame(width: 212, height: 212)
                        .background(.white, in: RoundedRectangle(cornerRadius: 8))
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Scan to add this contact card.")
                        .font(.headline)

                    Text(contactSummary)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 10) {
                        Button {
                            refreshQRCode()
                        } label: {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }

                        if let contact = qrCodeContact,
                           let contactData = try? CNContactVCardSerialization.data(with: [contact]) {
                            ShareLink(
                                item: contactData,
                                preview: SharePreview("Contact Card", image: Image(systemName: "person.crop.rectangle"))
                            ) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var contactPanel: some View {
        MacProfilePanel(title: "Contact", systemImage: "person.crop.rectangle") {
            VStack(spacing: 0) {
                if hasContactDetails {
                    if let email = currentProfile.email, !email.isEmpty {
                        MacProfileInfoRow(icon: "envelope.fill", title: "Email", value: email)
                    }

                    if let phone = currentProfile.phone, !phone.isEmpty {
                        MacProfileInfoRow(icon: "phone.fill", title: "Phone", value: phone)
                    }
                } else {
                    MacProfileEmptyState(
                        icon: "person.text.rectangle",
                        title: "No contact details",
                        message: "Add an email or phone number to make the QR card useful."
                    )
                }
            }
        }
    }

    private var socialPanel: some View {
        MacProfilePanel(title: "Social Links", systemImage: "link") {
            VStack(spacing: 0) {
                if currentProfile.socialLinks.isEmpty {
                    MacProfileEmptyState(
                        icon: "link.badge.plus",
                        title: "No social links",
                        message: "Add GitHub, LinkedIn, or other handles from Edit Profile."
                    )
                } else {
                    ForEach(currentProfile.socialLinks.sorted { $0.displayName < $1.displayName }, id: \.url) { link in
                        MacProfileSocialRow(link: link)
                    }
                }
            }
        }
    }

    private var professionalLine: String {
        switch (currentProfile.title, currentProfile.company) {
        case let (title, company) where !title.isEmpty && !company.isEmpty:
            return "\(title) at \(company)"
        case let (title, _) where !title.isEmpty:
            return title
        case let (_, company) where !company.isEmpty:
            return company
        default:
            return ""
        }
    }

    private var attendingEventCount: Int {
        storedEvents.filter { $0.isAttending }.count
    }

    private var contactSummary: String {
        let parts = [
            currentProfile.email,
            currentProfile.phone,
            professionalLine.isEmpty ? nil : professionalLine
        ].compactMap { value in
            value?.isEmpty == false ? value : nil
        }
        return parts.isEmpty ? "Edit your profile to include contact details." : parts.joined(separator: "\n")
    }

    private var hasContactDetails: Bool {
        currentProfile.email?.isEmpty == false || currentProfile.phone?.isEmpty == false
    }

    private func refreshQRCode(showFeedback: Bool = true) {
        qrCodeContact = currentProfile.createContact()
        qrCodeRefreshTrigger = UUID()
    }

    private func createDefaultProfile() -> Profile {
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
            try eventPersistenceService.persist(defaultProfile)
        } catch {
            print("Error saving default profile: \(error)")
        }

        return defaultProfile
    }
}

private struct MacProfilePanel<Content: View>: View {
    private let title: String?
    private let systemImage: String?
    private let content: Content

    init(
        title: String? = nil,
        systemImage: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let title, let systemImage {
                Label(title, systemImage: systemImage)
                    .font(.headline)
            }

            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color.eventBuddySystemGray6, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct MacProfileMetricRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 20)

            Text(title)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.medium)
                .multilineTextAlignment(.trailing)
        }
        .font(.callout)
    }
}

private struct MacProfileInfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 20)

            Text(title)
                .foregroundStyle(.secondary)
                .frame(width: 78, alignment: .leading)

            Text(value)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.callout)
        .padding(.vertical, 8)
    }
}

private struct MacProfileSocialRow: View {
    let link: SocialLinkInfo

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: link.icon)
                .foregroundStyle(.blue)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(link.displayName)
                    .font(.callout.weight(.medium))

                Text("@\(link.username)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }

            Spacer()

            if let url = URL(string: link.url) {
                Link(destination: url) {
                    Image(systemName: "arrow.up.forward.app")
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 8)
    }
}

private struct MacProfileEmptyState: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.callout.weight(.medium))

                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }
}

private struct MacProfileContactSnapshot: Equatable {
    let id: UUID
    let name: String
    let bio: String
    let email: String?
    let phone: String?
    let socialMediaAccounts: [String: String]
    let updatedAt: Date
    let title: String
    let company: String
    let avatarSystemName: String

    init(profile: Profile) {
        self.id = profile.id
        self.name = profile.name
        self.bio = profile.bio
        self.email = profile.email
        self.phone = profile.phone
        self.socialMediaAccounts = profile.socialMediaAccounts
        self.updatedAt = profile.updatedAt
        self.title = profile.title
        self.company = profile.company
        self.avatarSystemName = profile.avatarSystemName
    }
}
#endif
