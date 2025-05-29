import SwiftUI
import SwiftData
import PhotosUI

struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var profile: Profile
    @State private var newSocialService: String = "twitter"
    @State private var newSocialUsername: String = ""
    @State private var showingSocialLinkSheet = false
    
    var onSave: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Name", text: $profile.name)
                    TextField("Email", text: Binding(
                        get: { profile.email ?? "" },
                        set: { profile.email = $0.isEmpty ? nil : $0 }
                    ))
                        .keyboardType(.emailAddress)
                    TextField("Phone", text: Binding(
                        get: { profile.phone ?? "" },
                        set: { profile.phone = $0.isEmpty ? nil : $0 }
                    ))
                        .keyboardType(.phonePad)
                    TextField("iOS Developer passionate about SwiftUI", text: $profile.bio, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Professional Information") {
                    TextField("Job Title", text: $profile.title)
                    TextField("Company", text: $profile.company)
                }
                
                Section("Avatar") {
                    Picker("Avatar", selection: $profile.avatarSystemName) {
                        ForEach(avatarOptions, id: \.self) { option in
                            Label {
                                Text(avatarNames[option] ?? "")
                            } icon: {
                                Image(systemName: option)
                            }
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                
                Section("Social Links") {
                    ForEach(Array(profile.socialMediaAccounts.keys.sorted()), id: \.self) { service in
                        if let username = profile.socialMediaAccounts[service], !username.isEmpty {
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
                        showingSocialLinkSheet = true
                    } label: {
                        Label("Add Social Link", systemImage: "plus")
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProfile()
                        onSave()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingSocialLinkSheet) {
                addSocialLinkView
            }
        }
    }
    
    private var addSocialLinkView: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Service", selection: $newSocialService) {
                        ForEach(socialServices, id: \.self) { service in
                            Label {
                                Text(service.capitalized)
                            } icon: {
                                Image(systemName: socialMediaIcon(for: service))
                            }
                            .tag(service)
                        }
                    }
                    TextField("Username (without @)", text: $newSocialUsername)
                }
                
                Section {
                    Button("Add Social Link") {
                        addSocialLink()
                        showingSocialLinkSheet = false
                    }
                    .disabled(newSocialUsername.isEmpty)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Add Social Link")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingSocialLinkSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
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
        let sortedKeys = Array(profile.socialMediaAccounts.keys.sorted())
        for index in offsets {
            let keyToRemove = sortedKeys[index]
            profile.socialMediaAccounts.removeValue(forKey: keyToRemove)
        }
    }
    
    private func addSocialLink() {
        let cleanUsername = newSocialUsername.hasPrefix("@") ? String(newSocialUsername.dropFirst()) : newSocialUsername
        profile.socialMediaAccounts[newSocialService] = cleanUsername
        newSocialUsername = ""
        newSocialService = "twitter"
    }
    
    private func saveProfile() {
        profile.markAsUpdated()
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving profile: \(error)")
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Profile.self, configurations: config)
    let context = container.mainContext
    
    let sampleProfile = Profile.preview
    context.insert(sampleProfile)
    
    return ProfileEditView(profile: sampleProfile, onSave: {})
        .modelContainer(container)
} 
