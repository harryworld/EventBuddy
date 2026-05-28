import SwiftUI

struct EditFriendView: View {
    @Environment(EventPersistenceService.self) private var eventPersistenceService: EventPersistenceService?
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var friend: Friend
    
    @State private var name: String
    @State private var email: String
    @State private var phone: String
    @State private var jobTitle: String
    @State private var company: String
    @State private var notes: String
    @State private var socialMediaHandles: [String: String]
    @State private var showAddSocialSheet = false
    @State private var newPlatform = ""
    @State private var newUsername = ""
    
    init(friend: Friend) {
        self.friend = friend
        
        // Initialize state variables from friend
        _name = State(initialValue: friend.name)
        _email = State(initialValue: friend.email ?? "")
        _phone = State(initialValue: friend.phone ?? "")
        _jobTitle = State(initialValue: friend.jobTitle ?? "")
        _company = State(initialValue: friend.company ?? "")
        _notes = State(initialValue: friend.notes ?? "")
        
        // Extract social media handles
        _socialMediaHandles = State(initialValue: friend.socialMediaHandles)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    ClearableTextField("Name", text: $name)
                        .autocorrectionDisabled()
                    
                    ClearableTextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    
                    ClearableTextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                }
                
                Section("Professional Info") {
                    ClearableTextField("Job Title", text: $jobTitle)
                        .autocorrectionDisabled()
                    
                    ClearableTextField("Company", text: $company)
                        .autocorrectionDisabled()
                }
                
                Section("Social Media") {
                    // Common social media platforms
                    socialMediaRow(platform: "twitter", title: "Twitter/X")
                    socialMediaRow(platform: "linkedin", title: "LinkedIn")
                    socialMediaRow(platform: "github", title: "GitHub")
                    socialMediaRow(platform: "mastodon", title: "Mastodon")
                    
                    // Additional social media platforms
                    ForEach(Array(additionalSocialPlatforms.sorted()), id: \.self) { platform in
                        HStack {
                            Image(systemName: SocialPlatform.icon(for: platform))
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            
                            ClearableTextField(
                                SocialPlatform.displayName(for: platform),
                                text: socialMediaBinding(for: platform)
                            )
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            
                            Button {
                                socialMediaHandles.removeValue(forKey: platform)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    // Add new social media button
                    Button {
                        newPlatform = "" // Reset platform selection
                        newUsername = "" // Reset username
                        showAddSocialSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            Text("Add Social Media")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .eventBuddyPopupFormStyle()
            .navigationTitle("Edit Friend")
            .eventBuddyInlineNavigationTitle()
            .sheet(isPresented: $showAddSocialSheet) {
                AddSocialLinkView(
                    platform: $newPlatform,
                    username: $newUsername,
                    onSave: {
                        if !newPlatform.isEmpty && !newUsername.isEmpty {
                            socialMediaHandles[newPlatform] = newUsername
                            newPlatform = ""
                            newUsername = ""
                        }
                    },
                    existingPlatforms: Set(socialMediaHandles.keys)
                )
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .eventBuddyPopupCancelAction()
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        updateFriend()
                        dismiss()
                    }
                    .disabled(!canSave)
                    .eventBuddyPopupPrimaryAction()
                }
            }
        }
        .eventBuddyPopupFormLayout(width: 600, minHeight: 560)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func updateFriend() {
        // Update basic properties
        friend.name = name
        friend.email = email.isEmpty ? nil : email
        friend.phone = phone.isEmpty ? nil : phone
        friend.jobTitle = jobTitle.isEmpty ? nil : jobTitle
        friend.company = company.isEmpty ? nil : company
        friend.notes = notes.isEmpty ? nil : notes
        friend.updatedAt = Date()

        // Update social media handles - filter out empty values
        friend.socialMediaHandles = socialMediaHandles.compactMapValues { value in
            value.isEmpty ? nil : value
        }

        eventPersistenceService?.save(friend)
    }
    
    private var additionalSocialPlatforms: Set<String> {
        let commonPlatforms = Set(SocialPlatform.coreServices)
        return Set(socialMediaHandles.keys).subtracting(commonPlatforms)
    }

    private func socialMediaRow(platform: String, title: String) -> some View {
        HStack {
            Image(systemName: SocialPlatform.icon(for: platform))
                .foregroundColor(.blue)
                .frame(width: 30)

            ClearableTextField(title, text: socialMediaBinding(for: platform))
                .autocapitalization(.none)
                .autocorrectionDisabled()
        }
    }

    private func socialMediaBinding(for platform: String) -> Binding<String> {
        Binding(
            get: { socialMediaHandles[platform] ?? "" },
            set: {
                let cleanUsername = SocialPlatform.storageUsername($0, for: platform)
                socialMediaHandles[platform] = cleanUsername.isEmpty ? nil : cleanUsername
            }
        )
    }
}

#Preview {
    EditFriendView(friend: Friend.preview)
}
