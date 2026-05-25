import SwiftUI
import PhotosUI

struct ProfileEditView: View {
    @Environment(EventPersistenceService.self) private var eventPersistenceService
    @Environment(\.dismiss) private var dismiss
    
    let profile: Profile
    @State private var name: String
    @State private var bio: String
    @State private var email: String
    @State private var phone: String
    @State private var title: String
    @State private var company: String
    @State private var avatarSystemName: String
    @State private var socialMediaAccounts: [String: String]
    @State private var newSocialService: String = "twitter"
    @State private var newSocialUsername: String = ""
    @State private var showingSocialLinkSheet = false
    
    var onSave: () -> Void

    init(profile: Profile, onSave: @escaping () -> Void) {
        self.profile = profile
        self.onSave = onSave
        _name = State(initialValue: profile.name)
        _bio = State(initialValue: profile.bio)
        _email = State(initialValue: profile.email ?? "")
        _phone = State(initialValue: profile.phone ?? "")
        _title = State(initialValue: profile.title)
        _company = State(initialValue: profile.company)
        _avatarSystemName = State(initialValue: profile.avatarSystemName)
        _socialMediaAccounts = State(initialValue: profile.socialMediaAccounts)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Name", text: $name)
                    TextField("Email", text: Binding(
                        get: { email },
                        set: { email = Profile.normalizedEmail($0) ?? "" }
                    ))
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Phone", text: Binding(
                        get: { phone },
                        set: { phone = $0 }
                    ))
                        .keyboardType(.phonePad)
                    TextField("Bio", text: $bio, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Professional Information") {
                    TextField("Job Title", text: $title)
                    TextField("Company", text: $company)
                }
                
                Section("Avatar") {
                    Picker("Avatar", selection: $avatarSystemName) {
                        ForEach(avatarOptions, id: \.self) { option in
                            Label {
                                Text(avatarNames[option] ?? "")
                            } icon: {
                                Image(systemName: option)
                            }
                        }
                    }
                    #if os(iOS)
                    .pickerStyle(.navigationLink)
                    #else
                    .pickerStyle(.menu)
                    #endif
                }
                
                Section("Social Links") {
                    ForEach(Array(socialMediaAccounts.keys.sorted()), id: \.self) { service in
                        if let username = socialMediaAccounts[service], !username.isEmpty {
                            HStack {
                                Image(systemName: socialMediaIcon(for: service))
                                    .foregroundColor(.blue)
                                Text(service.capitalized)
                                Spacer()
                                Text("@\(username)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: deleteSocialLink)
                    
                    Button {
                        newSocialService = ""
                        newSocialUsername = ""
                        showingSocialLinkSheet = true
                    } label: {
                        Label("Add Social Link", systemImage: "plus")
                    }
                    .disabled(availableSocialServices.isEmpty)
                }
            }
            .eventBuddyPopupFormStyle()
            .navigationTitle("Edit Profile")
            .eventBuddyInlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .eventBuddyPopupCancelAction()
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProfile()
                        onSave()
                        dismiss()
                    }
                    .disabled(!canSave)
                    .eventBuddyPopupPrimaryAction()
                }
            }
            .sheet(isPresented: $showingSocialLinkSheet) {
                AddSocialLinkView(
                    platform: $newSocialService,
                    username: $newSocialUsername,
                    onSave: addSocialLink,
                    existingPlatforms: Set(socialMediaAccounts.keys),
                    availablePlatforms: socialServices
                )
            }
        }
        .eventBuddyPopupFormLayout(width: 620, minHeight: 620)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var availableSocialServices: [String] {
        socialServices.filter { !socialMediaAccounts.keys.contains($0) }
    }
    
    private let avatarOptions: [String] = [
        "person.crop.circle.fill",
        "person.crop.circle.fill.badge.checkmark",
        "person.crop.circle.fill.badge.plus",
        "person.crop.circle.badge.questionmark.fill",
        "person.crop.circle.badge.exclamationmark.fill",
        "person.2.crop.square.stack.fill",
        "face.smiling.fill",
        "brain.head.profile",
        "graduationcap.fill",
        "briefcase.fill"
    ]
    
    private let avatarNames: [String: String] = [
        "person.crop.circle.fill": "Default",
        "person.crop.circle.fill.badge.checkmark": "Verified",
        "person.crop.circle.fill.badge.plus": "New",
        "person.crop.circle.badge.questionmark.fill": "Anonymous",
        "person.crop.circle.badge.exclamationmark.fill": "Important",
        "person.2.crop.square.stack.fill": "Team",
        "face.smiling.fill": "Friendly",
        "brain.head.profile": "Thinker",
        "graduationcap.fill": "Graduate",
        "briefcase.fill": "Professional"
    ]
    
    private let socialServices = [
        "twitter", "linkedin", "github", "instagram",
        "facebook", "threads", "youtube"
    ]
    
    private func socialMediaIcon(for service: String) -> String {
        switch service.lowercased() {
        case "twitter": return "bird"
        case "linkedin": return "network"
        case "github": return "chevron.left.forwardslash.chevron.right"
        case "instagram": return "camera"
        case "facebook": return "person.2.fill"
        case "threads": return "text.bubble"
        case "youtube": return "play.rectangle"
        default: return "link"
        }
    }
    
    private func deleteSocialLink(at offsets: IndexSet) {
        let sortedKeys = Array(socialMediaAccounts.keys.sorted())
        for index in offsets {
            let keyToRemove = sortedKeys[index]
            socialMediaAccounts.removeValue(forKey: keyToRemove)
        }
    }
    
    private func addSocialLink() {
        let cleanUsername = newSocialUsername.hasPrefix("@") ? String(newSocialUsername.dropFirst()) : newSocialUsername
        socialMediaAccounts[newSocialService] = cleanUsername
        newSocialUsername = ""
        newSocialService = "twitter"
    }
    
    private func saveProfile() {
        profile.name = name
        profile.bio = bio
        profile.email = email.isEmpty ? nil : Profile.normalizedEmail(email)
        profile.phone = phone.isEmpty ? nil : phone
        profile.title = title
        profile.company = company
        profile.avatarSystemName = avatarSystemName
        profile.socialMediaAccounts = socialMediaAccounts
        profile.markAsUpdated()
        
        do {
            try eventPersistenceService.persist(profile)
        } catch {
            print("Error saving profile: \(error)")
        }
    }
}

#Preview {
    return ProfileEditView(profile: Profile.preview, onSave: {})
        .environment(EventPersistenceService())
}
