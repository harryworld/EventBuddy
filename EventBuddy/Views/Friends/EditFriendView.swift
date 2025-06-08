import SwiftUI
import SwiftData

struct EditFriendView: View {
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
                    TextField("Name", text: $name)
                        .autocorrectionDisabled()
                    
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    
                    TextField("Phone", text: $phone)
                        .keyboardType(.phonePad)
                }
                
                Section("Professional Info") {
                    TextField("Job Title", text: $jobTitle)
                        .autocorrectionDisabled()
                    
                    TextField("Company", text: $company)
                        .autocorrectionDisabled()
                }
                
                Section("Social Media") {
                    // Common social media platforms
                    HStack {
                        Image(systemName: "bubble.left")
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        TextField("Twitter/X", text: Binding(
                            get: { socialMediaHandles["twitter"] ?? "" },
                            set: { socialMediaHandles["twitter"] = $0.isEmpty ? nil : $0 }
                        ))
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    }
                    
                    HStack {
                        Image(systemName: "network")
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        TextField("LinkedIn", text: Binding(
                            get: { socialMediaHandles["linkedin"] ?? "" },
                            set: { socialMediaHandles["linkedin"] = $0.isEmpty ? nil : $0 }
                        ))
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    }
                    
                    HStack {
                        Image(systemName: "terminal")
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        TextField("GitHub", text: Binding(
                            get: { socialMediaHandles["github"] ?? "" },
                            set: { socialMediaHandles["github"] = $0.isEmpty ? nil : $0 }
                        ))
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                    }
                    
                    // Additional social media platforms
                    ForEach(Array(additionalSocialPlatforms.sorted()), id: \.self) { platform in
                        HStack {
                            Image(systemName: socialMediaIcon(for: platform))
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            
                            TextField(platform.capitalized, text: Binding(
                                get: { socialMediaHandles[platform] ?? "" },
                                set: { socialMediaHandles[platform] = $0.isEmpty ? nil : $0 }
                            ))
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
            .navigationTitle("Edit Friend")
            .navigationBarTitleDisplayMode(.inline)
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
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        updateFriend()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
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
    }
    
    private var additionalSocialPlatforms: Set<String> {
        let commonPlatforms: Set<String> = ["twitter", "linkedin", "github"]
        return Set(socialMediaHandles.keys).subtracting(commonPlatforms)
    }
    
    private func socialMediaIcon(for platform: String) -> String {
        switch platform.lowercased() {
        case "twitter": return "bubble.left"
        case "github": return "terminal"
        case "linkedin": return "network"
        case "instagram": return "camera"
        case "facebook": return "person.2"
        case "threads": return "at.badge.plus"
        default: return "link"
        }
    }
}

#Preview {
    EditFriendView(friend: Friend.preview)
        .modelContainer(for: Friend.self, inMemory: true)
} 