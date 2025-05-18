import SwiftUI
@_exported import Foundation // Needed to access Friend and FriendStore models

struct FriendDetailView: View {
    let friend: Friend
    let store: FriendStore
    let eventStore: EventStore
    @State private var eventFriendService: EventFriendService
    @Environment(\.dismiss) private var dismiss
    
    @State private var editedFriend: Friend
    @State private var isEditing: Bool
    let startInEditMode: Bool
    let returnToEvent: Bool
    
    // Standard initializer
    init(friend: Friend, store: FriendStore, eventStore: EventStore = EventStore()) {
        self.friend = friend
        self.store = store
        self.eventStore = eventStore
        self._editedFriend = State(initialValue: friend)
        self._isEditing = State(initialValue: false)
        self.startInEditMode = false
        self.returnToEvent = false
        self._eventFriendService = State(initialValue: EventFriendService(eventStore: eventStore, friendStore: store))
    }
    
    // Initializer for creating a new friend from an event that starts in edit mode
    init(friend: Friend, store: FriendStore, eventStore: EventStore = EventStore(), startInEditMode: Bool, returnToEvent: Bool) {
        self.friend = friend
        self.store = store
        self.eventStore = eventStore
        self._editedFriend = State(initialValue: friend)
        self._isEditing = State(initialValue: startInEditMode)
        self.startInEditMode = startInEditMode
        self.returnToEvent = returnToEvent
        self._eventFriendService = State(initialValue: EventFriendService(eventStore: eventStore, friendStore: store))
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
                
                // Attended Events section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Attended Events")
                        .font(.headline)
                    
                    let attendedEvents = eventFriendService.getEventsForFriend(friend: friend)
                    
                    if attendedEvents.isEmpty {
                        Text("No events attended yet")
                            .foregroundStyle(.secondary)
                            .padding()
                    } else {
                        ForEach(attendedEvents) { event in
                            NavigationLink(destination: EventDetailView(event: event, eventStore: eventStore, friendStore: store)) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(event.name)
                                            .font(.headline)
                                        
                                        Text(event.day)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.secondary)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.1))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Divider()
                
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
                if returnToEvent && startInEditMode {
                    // If coming from an event and was in edit mode, return to event on dismiss
                    dismiss()
                }
            } content: {
                NavigationStack {
                    EditFriendView(friend: editedFriend, store: store, onSave: {
                        saveFriendEdits()
                        isEditing = false
                        if returnToEvent && startInEditMode {
                            dismiss()
                        }
                    }, onCancel: {
                        isEditing = false
                        if returnToEvent && startInEditMode {
                            dismiss()
                        }
                    })
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                isEditing = false
                                if returnToEvent && startInEditMode {
                                    dismiss()
                                }
                            }
                        }
                        
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                saveFriendEdits()
                                isEditing = false
                                if returnToEvent && startInEditMode {
                                    dismiss()
                                }
                            }
                        }
                    }
                    .navigationTitle("Edit Friend")
                }
                .presentationDetents([.large])
            }
            .onAppear {
                if startInEditMode && !isEditing {
                    isEditing = true
                }
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
    var onSave: (() -> Void)?
    var onCancel: (() -> Void)?
    
    init(friend: Friend, store: FriendStore, onSave: (() -> Void)? = nil, onCancel: (() -> Void)? = nil) {
        self.friend = friend
        self.store = store
        self.onSave = onSave
        self.onCancel = onCancel
    }
    
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
                         store: FriendStore(),
                         eventStore: EventStore())
    }
} 