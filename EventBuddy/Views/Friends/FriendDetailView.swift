import SwiftUI
import SwiftData

struct FriendDetailView: View {
    let friend: Friend
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    
    @State private var showDeleteConfirmation = false
    @State private var showEditSheet = false
    @State private var showAddSocialSheet = false
    @State private var newSocialPlatform = ""
    @State private var newSocialUsername = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header with profile info
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text(friend.name)
                            .font(.largeTitle)
                            .bold()
                        
                        Spacer()
                        
                        Button {
                            friend.toggleFavorite()
                            try? modelContext.save()
                        } label: {
                            Image(systemName: friend.isFavorite ? "star.fill" : "star")
                                .font(.title)
                                .foregroundColor(friend.isFavorite ? .yellow : .gray)
                        }
                    }
                    
                    if let companyInfo = friendCompanyInfo, !companyInfo.isEmpty {
                        Text(companyInfo)
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                // Professional Information section
                if friend.jobTitle != nil || friend.company != nil {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Professional Information")
                            .font(.headline)
                        
                        if let jobTitle = friend.jobTitle, !jobTitle.isEmpty {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "briefcase.fill")
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Job Title")
                                        .foregroundColor(.secondary)
                                        .font(.subheadline)
                                    
                                    Text(jobTitle)
                                        .font(.body)
                                }
                            }
                        }
                        
                        if let company = friend.company, !company.isEmpty {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "building.2.fill")
                                    .foregroundColor(.blue)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Company")
                                        .foregroundColor(.secondary)
                                        .font(.subheadline)
                                    
                                    Text(company)
                                        .font(.body)
                                }
                            }
                        }
                    }
                    
                    Divider()
                }
                
                // Contact Information section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Contact Information")
                        .font(.headline)
                    
                    if let phone = friend.phone {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "phone.fill")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Phone")
                                    .foregroundColor(.secondary)
                                    .font(.subheadline)
                                
                                Text(phone)
                                    .font(.body)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if let phoneURL = URL(string: "tel:\(phone.replacingOccurrences(of: " ", with: ""))") {
                                openURL(phoneURL)
                            }
                        }
                    }
                    
                    if let email = friend.email {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.blue)
                                .frame(width: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Email")
                                    .foregroundColor(.secondary)
                                    .font(.subheadline)
                                
                                Text(email)
                                    .font(.body)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if let emailURL = URL(string: "mailto:\(email)") {
                                openURL(emailURL)
                            }
                        }
                    }
                }
                
                Divider()
                
                // Social Media section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Social Media")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button {
                            showAddSocialSheet = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title2)
                        }
                    }
                    
                    if friend.socialMediaHandles.isEmpty {
                        Text("No social media accounts added yet")
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    } else {
                        ForEach(Array(friend.socialMediaHandles.keys.sorted()), id: \.self) { key in
                            Button {
                                openSocialProfile(platform: key, username: friend.socialMediaHandles[key] ?? "")
                            } label: {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: socialMediaIcon(for: key))
                                        .foregroundColor(.blue)
                                        .frame(width: 24)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(key.capitalized)
                                            .foregroundColor(.secondary)
                                            .font(.subheadline)
                                        
                                        Text("@" + (friend.socialMediaHandles[key] ?? ""))
                                            .font(.body)
                                            .foregroundColor(.primary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "arrow.up.right.square")
                                        .foregroundColor(.blue)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete(perform: deleteSocialLinks)
                    }
                }
                
                Divider()
                
                // Attended Events section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Attended Events")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("\(friend.events.count) events")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    if friend.events.isEmpty {
                        Text("No events attended yet")
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    } else {
                        ForEach(friend.events) { event in
                            NavigationLink(destination: EventDetailView(event: event)) {
                                HStack(alignment: .top, spacing: 12) {
                                    // Calendar icon with date
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.blue.opacity(0.1))
                                            .frame(width: 44, height: 44)
                                        
                                        VStack(spacing: 2) {
                                            Text(event.startDate, format: .dateTime.month(.abbreviated))
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.blue)
                                            
                                            Text(event.startDate, format: .dateTime.day())
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.primary)
                                        }
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(event.title)
                                            .font(.headline)
                                            .lineLimit(1)
                                        
                                        HStack {
                                            Image(systemName: "mappin")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                            
                                            Text(event.location)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }
                                        
                                        HStack {
                                            Image(systemName: "clock")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                            
                                            Text(event.startDate, format: .dateTime.hour().minute())
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .padding(.top, 8)
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                Divider()
                
                // Want to Meet section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Want to Meet")
                            .font(.headline)
                        
                        Spacer()
                        
                        Text("\(friend.wishEvents.count) events")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    if friend.wishEvents.isEmpty {
                        Text("No one wanted to meet at events yet")
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    } else {
                        ForEach(friend.wishEvents) { event in
                            NavigationLink(destination: EventDetailView(event: event)) {
                                HStack(alignment: .top, spacing: 12) {
                                    // Calendar icon with date (orange theme for wishes)
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.orange.opacity(0.1))
                                            .frame(width: 44, height: 44)
                                        
                                        VStack(spacing: 2) {
                                            Text(event.startDate, format: .dateTime.month(.abbreviated))
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.orange)
                                            
                                            Text(event.startDate, format: .dateTime.day())
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.primary)
                                        }
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(event.title)
                                            .font(.headline)
                                            .lineLimit(1)
                                        
                                        HStack {
                                            Image(systemName: "mappin")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                            
                                            Text(event.location)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                                .lineLimit(1)
                                        }
                                        
                                        HStack {
                                            Image(systemName: "clock")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                            
                                            Text(event.startDate, format: .dateTime.hour().minute())
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        // Want to meet indicator
                                        HStack {
                                            Image(systemName: "star.fill")
                                                .font(.caption2)
                                                .foregroundColor(.orange)
                                            
                                            Text("Want to meet")
                                                .font(.caption)
                                                .foregroundColor(.orange)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                        .padding(.top, 8)
                                }
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Friend Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showEditSheet = true
                } label: {
                    Text("Edit")
                }
            }
        }
        .confirmationDialog("Are you sure you want to delete this friend?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                deleteFriend()
                dismiss()
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditFriendView(friend: friend)
        }
        .sheet(isPresented: $showAddSocialSheet) {
            AddSocialLinkView(
                platform: $newSocialPlatform,
                username: $newSocialUsername,
                onSave: addSocialLink
            )
        }
    }
    
    private func openSocialProfile(platform: String, username: String) {
        var urlString: String?
        
        // Strip @ from username if it exists
        let cleanUsername = username.hasPrefix("@") ? String(username.dropFirst()) : username
        
        switch platform.lowercased() {
        case "twitter":
            urlString = "https://twitter.com/\(cleanUsername)"
        case "github":
            urlString = "https://github.com/\(cleanUsername)"
        case "linkedin":
            urlString = "https://linkedin.com/in/\(cleanUsername)"
        case "instagram":
            urlString = "https://instagram.com/\(cleanUsername)"
        case "facebook":
            urlString = "https://facebook.com/\(cleanUsername)"
        case "threads":
            urlString = "https://threads.net/@\(cleanUsername)"
        default:
            if username.contains("://") {
                urlString = username
            } else {
                urlString = "https://\(username)"
            }
        }
        
        if let urlString = urlString, let url = URL(string: urlString) {
            openURL(url)
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
    
    private var friendCompanyInfo: String? {
        var components: [String] = []
        
        if let jobTitle = friend.jobTitle, !jobTitle.isEmpty {
            components.append(jobTitle)
        }
        
        if let company = friend.company, !company.isEmpty {
            components.append("at \(company)")
        }
        
        return components.isEmpty ? nil : components.joined(separator: " ")
    }
    
    private func deleteFriend() {
        modelContext.delete(friend)
    }
    
    private func addSocialLink() {
        guard !newSocialPlatform.isEmpty && !newSocialUsername.isEmpty else { return }
        
        friend.socialMediaHandles[newSocialPlatform.lowercased()] = newSocialUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        friend.updatedAt = Date()
        
        try? modelContext.save()
        
        // Reset form
        newSocialPlatform = ""
        newSocialUsername = ""
        showAddSocialSheet = false
    }
    
    private func deleteSocialLinks(at offsets: IndexSet) {
        for index in offsets {
            let platform = Array(friend.socialMediaHandles.keys.sorted())[index]
            friend.socialMediaHandles.removeValue(forKey: platform.lowercased())
        }
        friend.updatedAt = Date()
        try? modelContext.save()
    }
}

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

#Preview {
    NavigationStack {
        FriendDetailView(friend: Friend.preview)
    }
    .modelContainer(for: [Friend.self, Event.self], inMemory: true)
} 
