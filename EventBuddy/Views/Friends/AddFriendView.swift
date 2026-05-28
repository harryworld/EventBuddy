import SwiftUI

struct AddFriendView: View {
    let eventPersistenceService: EventPersistenceService?
    @Environment(EventPersistenceService.self) private var fallbackEventPersistenceService: EventPersistenceService?
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var jobTitle = ""
    @State private var company = ""
    @State private var notes = ""
    @State private var twitter = ""
    @State private var linkedin = ""
    @State private var github = ""
    @State private var mastodon = ""
    @State private var showSaveError = false
    @State private var saveErrorMessage = ""

    private var persistenceService: EventPersistenceService? {
        eventPersistenceService ?? fallbackEventPersistenceService
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
                    HStack {
                        Image(systemName: "bubble.left")
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        ClearableTextField("Twitter/X", text: $twitter)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }
                    
                    HStack {
                        Image(systemName: "network")
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        ClearableTextField("LinkedIn", text: $linkedin)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }
                    
                    HStack {
                        Image(systemName: "terminal")
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        ClearableTextField("GitHub", text: $github)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }
                    
                    HStack {
                        Image(systemName: SocialPlatform.icon(for: "mastodon"))
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        ClearableTextField("Mastodon", text: $mastodon)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .eventBuddyPopupFormStyle()
            .navigationTitle("Add Friend")
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
                        addFriend()
                    }
                    .disabled(!canSave)
                    .eventBuddyPopupPrimaryAction()
                }
            }
            .alert("Unable to Save Friend", isPresented: $showSaveError) {
                Button("OK") { }
            } message: {
                Text(saveErrorMessage)
            }
        }
        .eventBuddyPopupFormLayout(width: 600, minHeight: 560)
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func addFriend() {
        guard let persistenceService else {
            saveErrorMessage = "Friend storage service is not available."
            showSaveError = true
            return
        }

        // Build social media handles dictionary
        var socialMediaHandles: [String: String] = [:]
        
        if !twitter.isEmpty {
            socialMediaHandles["twitter"] = SocialPlatform.storageUsername(twitter, for: "twitter")
        }
        
        if !linkedin.isEmpty {
            socialMediaHandles["linkedin"] = SocialPlatform.storageUsername(linkedin, for: "linkedin")
        }
        
        if !github.isEmpty {
            socialMediaHandles["github"] = SocialPlatform.storageUsername(github, for: "github")
        }

        if !mastodon.isEmpty {
            socialMediaHandles["mastodon"] = SocialPlatform.storageUsername(mastodon, for: "mastodon")
        }
        
        // Create new friend
        let friend = Friend(
            name: name,
            email: email.isEmpty ? nil : email,
            phone: phone.isEmpty ? nil : phone,
            jobTitle: jobTitle.isEmpty ? nil : jobTitle,
            company: company.isEmpty ? nil : company,
            socialMediaHandles: socialMediaHandles,
            notes: notes.isEmpty ? nil : notes
        )
        
        persistenceService.save(friend)
        dismiss()
    }
}

#Preview {
    AddFriendView(eventPersistenceService: EventPersistenceService())
}
