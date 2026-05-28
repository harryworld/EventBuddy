import SwiftUI

struct FriendSocialMediaView: View {
    let friend: Friend
    let eventPersistenceService: EventPersistenceService?
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
                                Text(SocialPlatform.displayName(for: key))
                                    .foregroundColor(.secondary)
                                    .font(.subheadline)
                                
                                Text(SocialPlatform.displayHandle(for: key, username: friend.socialMediaHandles[key] ?? ""))
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
        let urlString = SocialPlatform.urlString(for: platform, username: username)
        
        if let url = URL(string: urlString) {
            openURL(url)
        }
    }
    
    private func socialMediaIcon(for platform: String) -> String {
        SocialPlatform.icon(for: platform)
    }
    
    private func deleteSocialLinks(at offsets: IndexSet) {
        for index in offsets {
            let platform = Array(friend.socialMediaHandles.keys.sorted())[index]
            friend.socialMediaHandles.removeValue(forKey: platform.lowercased())
        }
        friend.updatedAt = Date()
        eventPersistenceService?.save(friend)
    }
}
