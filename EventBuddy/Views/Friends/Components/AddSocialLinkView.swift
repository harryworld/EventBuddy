import SwiftUI

struct AddSocialLinkView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var platform: String
    @Binding var username: String
    let onSave: () -> Void
    
    private let availablePlatforms = ["twitter", "linkedin", "github", "instagram", "facebook", "threads"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Social Media Platform") {
                    Picker("Platform", selection: $platform) {
                        Text("Select Platform").tag("")
                        ForEach(availablePlatforms, id: \.self) { platformName in
                            Text(platformName.capitalized).tag(platformName)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Username") {
                    TextField(placeholderText, text: $username)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
            }
            .navigationTitle("Add Social Link")
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
                    .disabled(platform.isEmpty || username.isEmpty)
                }
            }
        }
    }
    
    private var placeholderText: String {
        switch platform {
        case "twitter": return "e.g. johndoe (without @)"
        case "linkedin": return "e.g. johndoe"
        case "github": return "e.g. johndoe"
        case "instagram": return "e.g. johndoe (without @)"
        case "facebook": return "e.g. john.doe"
        case "threads": return "e.g. johndoe (without @)"
        default: return "Username"
        }
    }
} 