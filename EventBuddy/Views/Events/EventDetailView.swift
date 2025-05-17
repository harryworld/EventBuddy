import SwiftUI

struct EventDetailView: View {
    let event: Event
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Event header
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        HStack(spacing: 8) {
                            Text(event.type.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.bottom, 10)
                    
                    // Date & Time section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Date & Time")
                            .font(.headline)
                        
                        HStack {
                            HStack(spacing: 12) {
                                Image(systemName: "calendar")
                                    .frame(width: 24, height: 24)
                                    .foregroundStyle(.blue)
                                    .background(Color(.systemGray6))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                
                                VStack(alignment: .leading) {
                                    Text("\(formatDay(event.day)), \(formatYear(event.day))")
                                        .fontWeight(.medium)
                                    Text(event.dateTime)
                                        .foregroundStyle(.secondary)
                                        .font(.subheadline)
                                }
                            }
                            
                            Spacer()
                            
                            Button("Add") {
                                // Add to calendar
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.vertical, 10)
                    
                    // Location section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Location")
                            .font(.headline)
                        
                        HStack {
                            HStack(spacing: 12) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.red)
                                
                                Text(event.location)
                                    .fontWeight(.medium)
                            }
                            
                            Spacer()
                            
                            Button("Map") {
                                // Open map
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.vertical, 10)
                    
                    // Description section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Description")
                            .font(.headline)
                        
                        Text(event.description)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 10)
                    
                    Spacer()
                }
                .padding()
            }
            
            // Tab bar
            TabBarView(selectedTab: $selectedTab)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Event Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // Share action
                }) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }
    
    // Helper functions to format date strings
    private func formatDay(_ fullDay: String) -> String {
        if let commaIndex = fullDay.firstIndex(of: ",") {
            let dayName = fullDay[..<commaIndex]
            return String(dayName)
        }
        return fullDay
    }
    
    private func formatYear(_ fullDay: String) -> String {
        if let startIndex = fullDay.range(of: "June")?.lowerBound {
            return String(fullDay[startIndex...])
        }
        return ""
    }
}

#Preview {
    NavigationStack {
        EventDetailView(event: EventStore().events.first!)
    }
} 
