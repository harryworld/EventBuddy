import SwiftUI
import SwiftData

struct AddFriendView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var notes = ""
    @State private var twitter = ""
    @State private var linkedin = ""
    @State private var github = ""
    
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
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        addFriend()
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func addFriend() {
        // Build social media handles dictionary
        var socialMediaHandles: [String: String] = [:]
        
        if !twitter.isEmpty {
            socialMediaHandles["twitter"] = twitter
        }
        
        if !linkedin.isEmpty {
            socialMediaHandles["linkedin"] = linkedin
        }
        
        if !github.isEmpty {
            socialMediaHandles["github"] = github
        }
        
        // Create new friend
        let friend = Friend(
            name: name,
            email: email.isEmpty ? nil : email,
            phone: phone.isEmpty ? nil : phone,
            socialMediaHandles: socialMediaHandles,
            notes: notes.isEmpty ? nil : notes
        )
        
        // Save to model context
        modelContext.insert(friend)
    }
}

#Preview {
    AddFriendView()
        .modelContainer(for: Friend.self, inMemory: true)
} 