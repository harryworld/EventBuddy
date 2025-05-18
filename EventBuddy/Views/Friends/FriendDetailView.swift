import SwiftUI
@_exported import Foundation // Needed to access Friend and FriendStore models

struct FriendDetailView: View {
    let friend: Friend
    let store: FriendStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var editedFriend: Friend
    @State private var isEditing = false
    
    init(friend: Friend, store: FriendStore) {
        self.friend = friend
        self.store = store
        self._editedFriend = State(initialValue: friend)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Friend header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(friend.name)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            if friend.isFavorite {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                            }
                        }
                        
                        if let company = friend.company {
                            Text(company)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button {
                        store.toggleFavorite(friend)
                    } label: {
                        Image(systemName: friend.isFavorite ? "star.fill" : "star")
                            .font(.system(size: 24))
                            .foregroundStyle(friend.isFavorite ? .yellow : .gray)
                    }
                    .buttonStyle(.plain)
                }
                
                Divider()
                
                // Contact information section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Contact Information")
                        .font(.headline)
                    
                    if let phoneNumber = friend.phoneNumber {
                        ContactRow(icon: "phone", title: "Phone", value: phoneNumber)
                    }
                    
                    if let email = friend.email {
                        ContactRow(icon: "envelope", title: "Email", value: email)
                    }
                }
                
                Divider()
                
                // Meeting information
                if friend.meetLocation != nil || friend.meetTime != nil {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Meeting Information")
                            .font(.headline)
                        
                        if let location = friend.meetLocation {
                            ContactRow(icon: "mappin.and.ellipse", title: "Location", value: location)
                        }
                        
                        if let meetTime = friend.meetTime {
                            ContactRow(icon: "clock", title: "Time", value: meetTime.formatted(date: .long, time: .shortened))
                        }
                    }
                    
                    Divider()
                }
                
                // Notes section
                if let notes = friend.notes {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Notes")
                            .font(.headline)
                        
                        Text(notes)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isEditing = true
                    }) {
                        Text("Edit")
                    }
                }
            }
            .sheet(isPresented: $isEditing) {
                NavigationStack {
                    EditFriendView(friend: editedFriend, store: store)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Cancel") {
                                    isEditing = false
                                }
                            }
                            
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Save") {
                                    saveFriendEdits()
                                    isEditing = false
                                }
                            }
                        }
                        .navigationTitle("Edit Friend")
                }
                .presentationDetents([.large])
            }
        }
        .navigationTitle("Friend Details")
    }
    
    private func saveFriendEdits() {
        if let index = store.friends.firstIndex(where: { $0.id == friend.id }) {
            store.friends[index] = editedFriend
        }
    }
}

struct ContactRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 30)
                .foregroundStyle(.blue)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
            }
        }
    }
}

struct EditFriendView: View {
    @Bindable var friend: Friend
    let store: FriendStore
    
    var body: some View {
        Form {
            Section("Basic Information") {
                TextField("Name", text: $friend.name)
                TextField("Company", text: Binding(
                    get: { friend.company ?? "" },
                    set: { friend.company = $0.isEmpty ? nil : $0 }
                ))
            }
            
            Section("Contact") {
                TextField("Phone Number", text: Binding(
                    get: { friend.phoneNumber ?? "" },
                    set: { friend.phoneNumber = $0.isEmpty ? nil : $0 }
                ))
                TextField("Email", text: Binding(
                    get: { friend.email ?? "" },
                    set: { friend.email = $0.isEmpty ? nil : $0 }
                ))
            }
            
            Section("Meeting Details") {
                TextField("Meet Location", text: Binding(
                    get: { friend.meetLocation ?? "" },
                    set: { friend.meetLocation = $0.isEmpty ? nil : $0 }
                ))
                DatePicker("Meet Time", selection: Binding(
                    get: { friend.meetTime ?? Date() },
                    set: { friend.meetTime = $0 }
                ), displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
            }
            
            Section("Notes") {
                TextEditor(text: Binding(
                    get: { friend.notes ?? "" },
                    set: { friend.notes = $0.isEmpty ? nil : $0 }
                ))
                .frame(minHeight: 100)
            }
            
            Section {
                Toggle("Favorite", isOn: $friend.isFavorite)
            }
        }
    }
}

#Preview {
    NavigationStack {
        FriendDetailView(friend: Friend(name: "John Appleseed", 
                                        phoneNumber: "555-123-4567", 
                                        email: "john@apple.com", 
                                        company: "Apple", 
                                        isFavorite: true, 
                                        notes: "Met at WWDC Keynote",
                                        meetLocation: "Apple Park"), 
                         store: FriendStore())
    }
} 