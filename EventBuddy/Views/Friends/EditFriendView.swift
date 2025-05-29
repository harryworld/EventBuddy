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
                    ForEach(Array(socialMediaHandles.keys.sorted()), id: \.self) { platform in
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
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Edit Friend")
            .navigationBarTitleDisplayMode(.inline)
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
    
    private func socialMediaIcon(for platform: String) -> String {
        switch platform.lowercased() {
        case "twitter": return "bird"
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