import SwiftUI

struct FriendDetailView: View {
    let friend: Friend
    
    @Environment(EventPersistenceService.self) private var eventPersistenceService: EventPersistenceService?
    @Environment(\.dismiss) private var dismiss
    
    @State private var showDeleteConfirmation = false
    @State private var showEditSheet = false
    @State private var showAddSocialSheet = false
    @State private var newSocialPlatform = ""
    @State private var newSocialUsername = ""
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                FriendHeaderView(friend: friend, eventPersistenceService: eventPersistenceService)
                
                Divider()
                
                if friend.jobTitle != nil || friend.company != nil {
                    FriendProfessionalInfoView(friend: friend)
                    Divider()
                }
                
                FriendContactInfoView(friend: friend)
                
                Divider()
                
                FriendSocialMediaView(
                    friend: friend,
                    eventPersistenceService: eventPersistenceService,
                    showAddSocialSheet: $showAddSocialSheet
                )
                
                Divider()
                
                FriendAttendedEventsView(friend: friend)
                
                Divider()
                
                FriendWishEventsView(friend: friend)
                
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
                onSave: addSocialLink,
                existingPlatforms: Set(friend.socialMediaHandles.keys)
            )
        }
        .onChange(of: showAddSocialSheet) { _, isShowing in
            if isShowing {
                // Reset form when sheet opens
                newSocialPlatform = ""
                newSocialUsername = ""
            }
        }
        .navigationDestination(for: Event.self) { event in
            EventDetailView(event: event)
        }
    }
    
    private func deleteFriend() {
        eventPersistenceService?.delete(friend)
    }
    
    private func addSocialLink() {
        guard !newSocialPlatform.isEmpty && !newSocialUsername.isEmpty else { return }
        
        friend.socialMediaHandles[newSocialPlatform.lowercased()] = newSocialUsername.trimmingCharacters(in: .whitespacesAndNewlines)
        friend.updatedAt = Date()
        
        eventPersistenceService?.save(friend)
        
        // Reset form
        newSocialPlatform = ""
        newSocialUsername = ""
        showAddSocialSheet = false
    }
}

#Preview {
    NavigationStack {
        FriendDetailView(friend: Friend.preview)
    }
}
