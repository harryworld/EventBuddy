import SwiftUI
import SwiftData

struct EditEventView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Bindable var event: Event
    
    @State private var title: String
    @State private var eventDescription: String
    @State private var location: String
    @State private var address: String
    @State private var countryCode: String
    @State private var countryFlag: String
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var eventType: String
    @State private var notes: String
    @State private var requiresTicket: Bool
    @State private var requiresRegistration: Bool
    @State private var url: String
    
    // Validation states
    @State private var isFormValid = false
    @State private var showValidationAlert = false
    
    // Country selection
    let countries = [
        ("US", "🇺🇸", "United States"),
        ("CA", "🇨🇦", "Canada"),
        ("GB", "🇬🇧", "United Kingdom"),
        ("DE", "🇩🇪", "Germany"),
        ("FR", "🇫🇷", "France"),
        ("JP", "🇯🇵", "Japan"),
        ("IN", "🇮🇳", "India"),
        ("IL", "🇮🇱", "Israel"),
        ("AU", "🇦🇺", "Australia"),
        ("BR", "🇧🇷", "Brazil"),
        ("CN", "🇨🇳", "China"),
        ("KR", "🇰🇷", "South Korea"),
        ("IT", "🇮🇹", "Italy"),
        ("ES", "🇪🇸", "Spain"),
        ("NL", "🇳🇱", "Netherlands"),
        ("SG", "🇸🇬", "Singapore"),
        ("SE", "🇸🇪", "Sweden")
    ]
    
    init(event: Event) {
        self.event = event
        self._title = State(initialValue: event.title)
        self._eventDescription = State(initialValue: event.eventDescription)
        self._location = State(initialValue: event.location)
        self._address = State(initialValue: event.address ?? "")
        self._countryCode = State(initialValue: event.countryCode ?? "US")
        self._countryFlag = State(initialValue: event.countryFlag ?? "🇺🇸")
        self._startDate = State(initialValue: event.startDate)
        self._endDate = State(initialValue: event.endDate)
        self._eventType = State(initialValue: event.eventType)
        self._notes = State(initialValue: event.notes ?? "")
        self._requiresTicket = State(initialValue: event.requiresTicket)
        self._requiresRegistration = State(initialValue: event.requiresRegistration)
        self._url = State(initialValue: event.url ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Event Details") {
                    TextField("Title", text: $title)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Description", text: $eventDescription, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                    
                    Picker("Event Type", selection: $eventType) {
                        ForEach(EventType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type.rawValue)
                        }
                    }
                }
                
                Section("Location") {
                    TextField("Location", text: $location)
                        .textInputAutocapitalization(.words)
                    
                    TextField("Address", text: $address)
                        .textInputAutocapitalization(.words)
                    
                    Picker("Country", selection: $countryCode) {
                        ForEach(countries, id: \.0) { code, flag, name in
                            HStack {
                                Text(flag)
                                Text(name)
                            }
                            .tag(code)
                        }
                    }
                    .onChange(of: countryCode) { oldValue, newValue in
                        if let countryData = countries.first(where: { $0.0 == newValue }) {
                            countryFlag = countryData.1
                        }
                    }
                }
                
                Section("Date & Time") {
                    DatePicker("Start Date", selection: $startDate)
                        .datePickerStyle(.compact)
                    
                    DatePicker("End Date", selection: $endDate)
                        .datePickerStyle(.compact)
                }
                
                Section("Additional Information") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                    
                    TextField("URL", text: $url)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                Section("Requirements") {
                    Toggle("Requires Ticket", isOn: $requiresTicket)
                        .toggleStyle(.switch)
                    
                    Toggle("Requires Registration", isOn: $requiresRegistration)
                        .toggleStyle(.switch)
                }
            }
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if validateForm() {
                            saveChanges()
                            dismiss()
                        } else {
                            showValidationAlert = true
                        }
                    }
                }
            }
            .alert("Invalid Form", isPresented: $showValidationAlert) {
                Button("OK") { }
            } message: {
                Text("Please fill out all required fields and ensure end date is after start date.")
            }
            .onChange(of: title) { validateForm() }
            .onChange(of: eventDescription) { validateForm() }
            .onChange(of: location) { validateForm() }
            .onChange(of: startDate) { validateForm() }
            .onChange(of: endDate) { validateForm() }
        }
    }
    
    private func validateForm() -> Bool {
        // Check required fields
        guard !title.isEmpty,
              !eventDescription.isEmpty,
              !location.isEmpty,
              endDate > startDate else {
            isFormValid = false
            return false
        }
        
        isFormValid = true
        return true
    }
    
    private func saveChanges() {
        event.title = title
        event.eventDescription = eventDescription
        event.location = location
        event.address = address.isEmpty ? nil : address
        event.startDate = startDate
        event.endDate = endDate
        event.eventType = eventType
        event.notes = notes.isEmpty ? nil : notes
        event.countryCode = countryCode
        event.countryFlag = countryFlag
        event.requiresTicket = requiresTicket
        event.requiresRegistration = requiresRegistration
        event.url = url.isEmpty ? nil : url
        event.updatedAt = Date()
        
        try? modelContext.save()
    }
}

#Preview {
    let event = Event.preview
    event.isCustomEvent = true
    
    return EditEventView(event: event)
        .modelContainer(for: Event.self, inMemory: true)
} 