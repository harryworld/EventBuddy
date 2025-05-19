import SwiftUI

struct AddEventView: View {
    @Environment(\.dismiss) private var dismiss
    let eventStore: EventStore
    
    @State private var name: String = ""
    @State private var dateTime: String = ""
    @State private var description: String = ""
    @State private var location: String = "Cupertino"
    @State private var day: String = ""
    @State private var requiresTicket: Bool = false
    @State private var eventType: EventType = .event
    @State private var showingDatePicker = false
    @State private var selectedDate = Date()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d'th'"
        return formatter
    }()
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        return formatter
    }()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Event Details") {
                    TextField("Event Name", text: $name)
                    
                    VStack(alignment: .leading) {
                        Button {
                            showingDatePicker.toggle()
                        } label: {
                            HStack {
                                Text("Date/Time")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(day.isEmpty ? "Select" : day)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if showingDatePicker {
                            DatePicker("", selection: $selectedDate)
                                .datePickerStyle(.graphical)
                                .onChange(of: selectedDate) { _, newValue in
                                    day = dateFormatter.string(from: newValue)
                                    dateTime = timeFormatter.string(from: newValue)
                                }
                        }
                    }
                    
                    TextField("Time (e.g., 9:00am-4:00pm)", text: $dateTime)
                    TextField("Location", text: $location)
                    
                    Picker("Event Type", selection: $eventType) {
                        ForEach(EventType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                }
                
                Section("Additional Information") {
                    TextField("Description", text: $description)
                    Toggle("Requires Ticket", isOn: $requiresTicket)
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
                        saveEvent()
                    }
                    .disabled(name.isEmpty || day.isEmpty || dateTime.isEmpty)
                }
            }
        }
    }
    
    private func saveEvent() {
        let newEvent = Event(
            name: name,
            dateTime: dateTime,
            description: description,
            requiresTicket: requiresTicket,
            location: location,
            day: day,
            type: eventType,
            isCustomEvent: true
        )
        
        eventStore.events.append(newEvent)
        dismiss()
    }
}

#Preview {
    AddEventView(eventStore: EventStore())
} 