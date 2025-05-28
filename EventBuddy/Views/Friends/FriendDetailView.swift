import SwiftUI
import SwiftData

struct FriendDetailView: View {
    let friend: Friend
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    
    @State private var showDeleteConfirmation = false
    @State private var showEditSheet = false
    
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
                if !friend.socialMediaHandles.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Social Media")
                            .font(.headline)
                        
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
                    }
                    
                    Divider()
                }
                
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
        if let notes = friend.notes {
            if notes.hasPrefix("Works at ") {
                return String(notes.dropFirst("Works at ".count))
            } else if notes.contains("Developer") || notes.contains("Dev") {
                return notes
            }
        }
        return nil
    }
    
    private func deleteFriend() {
        modelContext.delete(friend)
    }
}

#Preview {
    NavigationStack {
        FriendDetailView(friend: Friend.preview)
    }
    .modelContainer(for: [Friend.self, Event.self], inMemory: true)
} 
