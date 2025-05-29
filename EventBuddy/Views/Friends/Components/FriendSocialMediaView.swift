import SwiftUI
import SwiftData

struct FriendSocialMediaView: View {
    let friend: Friend
    let modelContext: ModelContext
    @Binding var showAddSocialSheet: Bool
    
    @Environment(\.openURL) private var openURL
    
    var body: some View {
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
    
    private func deleteSocialLinks(at offsets: IndexSet) {
        for index in offsets {
            let platform = Array(friend.socialMediaHandles.keys.sorted())[index]
            friend.socialMediaHandles.removeValue(forKey: platform.lowercased())
        }
        friend.updatedAt = Date()
        try? modelContext.save()
    }
} 