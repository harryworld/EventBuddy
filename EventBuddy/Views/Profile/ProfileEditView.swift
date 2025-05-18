import SwiftUI

struct ProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var user: User
    @State private var newSocialService: SocialService = .twitter
    @State private var newSocialUsername: String = ""
    @State private var showingSocialLinkSheet = false
    var onSave: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Name", text: $user.name)
                    TextField("Email", text: $user.email)
                        .keyboardType(.emailAddress)
                    TextField("Phone", text: $user.phone)
                        .keyboardType(.phonePad)
                }
                
                Section("Professional Information") {
                    TextField("Job Title", text: $user.title)
                    TextField("Company", text: $user.company)
                }
                
                Section("Avatar") {
                    Picker("Avatar", selection: $user.avatarSystemName) {
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
                    ForEach(user.socialLinks) { link in
                        HStack {
                            Image(systemName: link.service.icon)
                                .foregroundColor(.blue)
                            Text(link.service.displayName)
                            Spacer()
                            Text("@\(link.username)")
                                .foregroundStyle(.secondary)
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
                        ForEach(SocialService.allCases) { service in
                            Label {
                                Text(service.displayName)
                            } icon: {
                                Image(systemName: service.icon)
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
    
    private func deleteSocialLink(at offsets: IndexSet) {
        user.socialLinks.remove(atOffsets: offsets)
    }
    
    private func addSocialLink() {
        guard !newSocialUsername.isEmpty else { return }
        let newLink = SocialLink(
            service: newSocialService,
            username: newSocialUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        user.socialLinks.append(newLink)
        newSocialUsername = ""
    }
}

#Preview {
    ProfileEditView(user: UserStore().currentUser, onSave: {})
} 