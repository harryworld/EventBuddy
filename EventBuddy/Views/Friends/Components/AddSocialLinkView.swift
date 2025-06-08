import SwiftUI

struct AddSocialLinkView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var platform: String
    @Binding var username: String
    let onSave: () -> Void
    let existingPlatforms: Set<String>
    
    private let availablePlatforms = ["twitter", "linkedin", "github", "instagram", "facebook", "threads"]
    
    init(platform: Binding<String>, username: Binding<String>, onSave: @escaping () -> Void, existingPlatforms: Set<String> = []) {
        self._platform = platform
        self._username = username
        self.onSave = onSave
        self.existingPlatforms = existingPlatforms
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Social Media Platform") {
                    Picker("Platform", selection: $platform) {
                        Text("Select Platform").tag("")
                        ForEach(availableUnusedPlatforms, id: \.self) { platformName in
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
        .onAppear {
            // Pre-select the first available platform if none is selected
            if platform.isEmpty && !availableUnusedPlatforms.isEmpty {
                platform = availableUnusedPlatforms.first!
            }
        }
    }
    
    private var availableUnusedPlatforms: [String] {
        return availablePlatforms.filter { !existingPlatforms.contains($0) }
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