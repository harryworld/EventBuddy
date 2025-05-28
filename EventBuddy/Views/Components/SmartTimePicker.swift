import SwiftUI

struct SmartTimePicker: View {
    @Binding var startDate: Date
    @Binding var endDate: Date
    var timezone: TimeZone = TimeZone.current
    
    var body: some View {
        VStack(spacing: 16) {
            // Start Date & Time
            VStack(alignment: .leading, spacing: 8) {
                DatePicker("Start Date", selection: Binding(
                    get: { startDate },
                    set: { newValue in
                        handleStartDateChange(newValue)
                    }
                ), displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
                .environment(\.timeZone, timezone)
            }
            
            // End Date & Time
            VStack(alignment: .leading, spacing: 8) {
                DatePicker("End Date", selection: Binding(
                    get: { endDate },
                    set: { newValue in
                        handleEndDateChange(newValue)
                    }
                ), displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(.compact)
                .environment(\.timeZone, timezone)
            }
            
            // Duration display
            HStack {
                Image(systemName: "clock")
                    .foregroundStyle(.secondary)
                Text("Duration: \(formattedDuration)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding(.vertical, 8)
    }
    
    private var formattedDuration: String {
        let duration = endDate.timeIntervalSince(startDate)
        
        // Handle negative duration
        guard duration > 0 else {
            return "0m"
        }
        
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func handleStartDateChange(_ newStartDate: Date) {
        let adjustedStartDate = roundToNearestFiveMinutes(newStartDate)
        
        // Always ensure start date is set first
        startDate = adjustedStartDate
        
        // If start time goes past end time, update end time to be one hour after start time
        if adjustedStartDate >= endDate {
            endDate = adjustedStartDate.addingTimeInterval(3600) // Add 1 hour
        }
    }
    
    private func handleEndDateChange(_ newEndDate: Date) {
        let adjustedEndDate = roundToNearestFiveMinutes(newEndDate)
        
        // If end time goes before start time, update start time to be the same as end time
        if adjustedEndDate <= startDate {
            startDate = adjustedEndDate
        }
        
        endDate = adjustedEndDate
    }
    
    private func roundToNearestFiveMinutes(_ date: Date) -> Date {
        var calendar = Calendar.current
        calendar.timeZone = timezone
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        
        guard let minute = components.minute else { return date }
        
        // Round to nearest 5 minutes
        let roundedMinute = (minute / 5) * 5
        
        var newComponents = components
        newComponents.minute = roundedMinute
        newComponents.second = 0
        newComponents.nanosecond = 0
        
        return calendar.date(from: newComponents) ?? date
    }
}

// Helper functions for creating smart default times
extension Date {
    static func nextHour(in timezone: TimeZone = TimeZone.current) -> Date {
        var calendar = Calendar.current
        calendar.timeZone = timezone
        let now = Date()
        let components = calendar.dateComponents([.year, .month, .day, .hour], from: now)
        
        var newComponents = components
        newComponents.hour = (components.hour ?? 0) + 1
        newComponents.minute = 0
        newComponents.second = 0
        newComponents.nanosecond = 0
        
        return calendar.date(from: newComponents) ?? now.addingTimeInterval(3600)
    }
    
    static func nextHourPlusOne(in timezone: TimeZone = TimeZone.current) -> Date {
        return nextHour(in: timezone).addingTimeInterval(3600)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var startDate = Date.nextHour()
        @State private var endDate = Date.nextHourPlusOne()
        
        var body: some View {
            Form {
                Section("Smart Time Picker") {
                    SmartTimePicker(startDate: $startDate, endDate: $endDate)
                }
                
                Section("Selected Times") {
                    Text("Start: \(startDate.formatted(date: .abbreviated, time: .shortened))")
                    Text("End: \(endDate.formatted(date: .abbreviated, time: .shortened))")
                }
            }
        }
    }
    
    return PreviewWrapper()
} 
