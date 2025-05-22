import SwiftUI
import SwiftData

struct EditFriendView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var friend: Friend
    
    @State private var name: String
    @State private var email: String
    @State private var phone: String
    @State private var notes: String
    @State private var twitter: String
    @State private var linkedin: String
    @State private var github: String
    
    init(friend: Friend) {
        self.friend = friend
        
        // Initialize state variables from friend
        _name = State(initialValue: friend.name)
        _email = State(initialValue: friend.email ?? "")
        _phone = State(initialValue: friend.phone ?? "")
        _notes = State(initialValue: friend.notes ?? "")
        
        // Extract social media handles
        _twitter = State(initialValue: friend.socialMediaHandles["twitter"] ?? "")
        _linkedin = State(initialValue: friend.socialMediaHandles["linkedin"] ?? "")
        _github = State(initialValue: friend.socialMediaHandles["github"] ?? "")
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
                
                Section("Social Media") {
                    HStack {
                        Image(systemName: "bubble.left")
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        TextField("Twitter/X", text: $twitter)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }
                    
                    HStack {
                        Image(systemName: "network")
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        TextField("LinkedIn", text: $linkedin)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }
                    
                    HStack {
                        Image(systemName: "terminal")
                            .foregroundColor(.blue)
                            .frame(width: 30)
                        TextField("GitHub", text: $github)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
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
        friend.notes = notes.isEmpty ? nil : notes
        friend.updatedAt = Date()
        
        // Update social media handles
        var updatedHandles: [String: String] = [:]
        
        if !twitter.isEmpty {
            updatedHandles["twitter"] = twitter
        }
        
        if !linkedin.isEmpty {
            updatedHandles["linkedin"] = linkedin
        }
        
        if !github.isEmpty {
            updatedHandles["github"] = github
        }
        
        friend.socialMediaHandles = updatedHandles
    }
}

#Preview {
    EditFriendView(friend: Friend.preview)
        .modelContainer(for: Friend.self, inMemory: true)
} 