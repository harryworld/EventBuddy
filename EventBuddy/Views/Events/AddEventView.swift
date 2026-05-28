import SwiftUI

struct AddEventView: View {
    @Environment(EventPersistenceService.self) private var eventPersistenceService: EventPersistenceService?
    @Environment(\.dismiss) private var dismiss
    
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
                    ClearableTextField("Title", text: $title)
                        .textInputAutocapitalization(.words)
                    
                    ClearableTextField("Description", text: $eventDescription, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                    
                    Picker("Event Type", selection: $eventType) {
                        ForEach(EventType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type.rawValue)
                        }
                    }
                }
                
                Section("Location") {
                    ClearableTextField("Location", text: $location)
                        .textInputAutocapitalization(.words)
                    
                    ClearableTextField("Address", text: $address)
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
                    ClearableTextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                    
                    ClearableTextField("URL", text: $url)
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
            .eventBuddyPopupFormStyle()
            .navigationTitle("Add Event")
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
                        if validateForm() {
                            saveEvent()
                            dismiss()
                        } else {
                            showValidationAlert = true
                        }
                    }
                    .disabled(!canSave)
                    .eventBuddyPopupPrimaryAction()
                }
            }
            .alert("Invalid Form", isPresented: $showValidationAlert) {
                Button("OK") { }
            } message: {
                Text("Please enter a title and ensure end date is after start date.")
            }
            .onChange(of: title) { _ = validateForm() }
            .onChange(of: startDate) { _ = validateForm() }
            .onChange(of: endDate) { _ = validateForm() }
        }
        .eventBuddyPopupFormLayout(width: 680, minHeight: 620)
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && endDate > startDate
    }
    
    private func validateForm() -> Bool {
        // Check required fields - only title and proper date ordering are required
        guard canSave else {
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
        
        eventPersistenceService?.save(newEvent)
    }
}

#Preview {
    AddEventView()
}
