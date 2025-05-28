import SwiftUI
import SwiftData

struct AddEventView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var title = ""
    @State private var eventDescription = ""
    @State private var location = ""
    @State private var address = ""
    @State private var startDate = Date.nextHour()
    @State private var endDate = Date.nextHourPlusOne()
    @State private var eventType = EventType.meetup.rawValue
    @State private var notes = ""
    @State private var requiresTicket = false
    @State private var requiresRegistration = false
    @State private var url = ""
    @State private var selectedTimezone = TimeZone.current.identifier
    
    // Validation states
    @State private var isFormValid = false
    @State private var showValidationAlert = false
    

    
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
                }
                
                Section("Date & Time") {
                    SmartTimePicker(
                        startDate: $startDate, 
                        endDate: $endDate,
                        timezone: TimeZone(identifier: selectedTimezone) ?? TimeZone.current
                    )
                    
                    TimezonePicker(selectedTimezone: $selectedTimezone)
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
            .navigationTitle("Add Event")
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
                            saveEvent()
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
            .onChange(of: title) { _ = validateForm() }
            .onChange(of: eventDescription) { _ = validateForm() }
            .onChange(of: location) { _ = validateForm() }
            .onChange(of: startDate) { _ = validateForm() }
            .onChange(of: endDate) { _ = validateForm() }
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
    
    private func saveEvent() {
        let newEvent = Event(
            title: title,
            eventDescription: eventDescription,
            location: location,
            address: address.isEmpty ? nil : address,
            startDate: startDate,
            endDate: endDate,
            eventType: eventType,
            notes: notes.isEmpty ? nil : notes,
            requiresTicket: requiresTicket,
            requiresRegistration: requiresRegistration,
            url: url.isEmpty ? nil : url,
            originalTimezoneIdentifier: selectedTimezone
        )
        
        modelContext.insert(newEvent)
    }
}

#Preview {
    AddEventView()
        .modelContainer(for: Event.self, inMemory: true)
} 
