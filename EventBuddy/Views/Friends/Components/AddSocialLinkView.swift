import SwiftUI

struct AddSocialLinkView: View {
    @Environment(\.dismiss) private var dismiss
    
    @Binding var platform: String
    @Binding var username: String
    let onSave: () -> Void
    let existingPlatforms: Set<String>
    
    private let availablePlatforms: [String]
    
    init(
        platform: Binding<String>,
        username: Binding<String>,
        onSave: @escaping () -> Void,
        existingPlatforms: Set<String> = [],
        availablePlatforms: [String] = SocialPlatform.allServices
    ) {
        self._platform = platform
        self._username = username
        self.onSave = onSave
        self.existingPlatforms = existingPlatforms
        self.availablePlatforms = availablePlatforms
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Social Media Platform") {
                    Picker("Platform", selection: $platform) {
                        Text("Select Platform").tag("")
                        ForEach(availableUnusedPlatforms, id: \.self) { platformName in
                            Text(SocialPlatform.displayName(for: platformName)).tag(platformName)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section("Username") {
                    ClearableTextField(placeholderText, text: $username)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
            }
            .eventBuddyPopupFormStyle()
            .navigationTitle("Add Social Link")
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
                        onSave()
                        dismiss()
                    }
                    .disabled(!canSave)
                    .eventBuddyPopupPrimaryAction()
                }
            }
        }
        .eventBuddyPopupFormLayout(width: 420, minHeight: 240, maxHeight: 320)
        .onAppear {
            // Pre-select the first available platform if none is selected
            if platform.isEmpty, let firstAvailablePlatform = availableUnusedPlatforms.first {
                platform = firstAvailablePlatform
            }
        }
    }

    private var canSave: Bool {
        !platform.isEmpty && !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private var availableUnusedPlatforms: [String] {
        return availablePlatforms.filter { !existingPlatforms.contains($0) }
    }
    
    private var placeholderText: String {
        SocialPlatform.placeholder(for: platform)
    }
}
