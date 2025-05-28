import SwiftUI

struct TimezonePicker: View {
    @Binding var selectedTimezone: String
    @State private var searchText = ""
    @State private var isExpanded = false
    
    // Common timezones that users are likely to need
    private let commonTimezones = [
        "America/Los_Angeles", // Pacific Time (WWDC)
        "America/New_York",    // Eastern Time
        "America/Chicago",     // Central Time
        "America/Denver",      // Mountain Time
        "Europe/London",       // GMT/BST
        "Europe/Paris",        // CET/CEST
        "Europe/Berlin",       // CET/CEST
        "Asia/Tokyo",          // JST
        "Asia/Shanghai",       // CST
        "Asia/Kolkata",        // IST
        "Australia/Sydney",    // AEST
        "UTC"                  // UTC
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Current selection display
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Timezone")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(displayName(for: selectedTimezone))
                            .font(.body)
                            .foregroundStyle(.primary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                VStack(spacing: 0) {
                    // Search field
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                        
                        TextField("Search by city, abbreviation...", text: $searchText)
                            .textFieldStyle(.plain)
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.bottom, 8)
                    
                    // Timezone list
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredTimezones, id: \.self) { timezone in
                                TimezoneRow(
                                    timezone: timezone,
                                    isSelected: timezone == selectedTimezone
                                ) {
                                    selectedTimezone = timezone
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        isExpanded = false
                                    }
                                    searchText = ""
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
                .padding(.top, 8)
                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            }
        }
    }
    
    private var filteredTimezones: [String] {
        let allTimezones = searchText.isEmpty ? commonTimezones : TimeZone.knownTimeZoneIdentifiers.sorted()
        
        if searchText.isEmpty {
            return allTimezones
        }
        
        return allTimezones.filter { timezone in
            let displayName = self.displayName(for: timezone)
            let abbreviation = self.getAbbreviation(for: timezone)
            let cityName = timezone.components(separatedBy: "/").last?.replacingOccurrences(of: "_", with: " ") ?? timezone
            
            return displayName.localizedCaseInsensitiveContains(searchText) ||
                   timezone.localizedCaseInsensitiveContains(searchText) ||
                   abbreviation.localizedCaseInsensitiveContains(searchText) ||
                   cityName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    private func displayName(for timezoneIdentifier: String) -> String {
        guard TimeZone(identifier: timezoneIdentifier) != nil else {
            return timezoneIdentifier
        }
        
        let abbreviation = getAbbreviation(for: timezoneIdentifier)
        let cityName = timezoneIdentifier.components(separatedBy: "/").last?.replacingOccurrences(of: "_", with: " ") ?? timezoneIdentifier
        
        return "\(cityName) (\(abbreviation))"
    }
    
    private func getAbbreviation(for timezoneIdentifier: String) -> String {
        guard let timezone = TimeZone(identifier: timezoneIdentifier) else {
            return timezoneIdentifier
        }
        
        let formatter = DateFormatter()
        formatter.timeZone = timezone
        formatter.dateFormat = "zzz"
        formatter.locale = Locale(identifier: "en_US")
        
        return formatter.string(from: Date())
    }
}

struct TimezoneRow: View {
    let timezone: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(cityName)
                        .font(.body)
                        .foregroundStyle(.primary)
                    
                    Text(offsetAndAbbreviation)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                        .font(.body)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private var cityName: String {
        timezone.components(separatedBy: "/").last?.replacingOccurrences(of: "_", with: " ") ?? timezone
    }
    
    private var offsetAndAbbreviation: String {
        guard let tz = TimeZone(identifier: timezone) else {
            return timezone
        }
        
        let formatter = DateFormatter()
        formatter.timeZone = tz
        formatter.dateFormat = "zzz"
        formatter.locale = Locale(identifier: "en_US")
        
        let abbreviation = formatter.string(from: Date())
        
        // Calculate offset
        let offsetSeconds = tz.secondsFromGMT()
        let offsetHours = offsetSeconds / 3600
        let offsetMinutes = abs(offsetSeconds % 3600) / 60
        
        let offsetString: String
        if offsetMinutes == 0 {
            offsetString = String(format: "GMT%+d", offsetHours)
        } else {
            offsetString = String(format: "GMT%+d:%02d", offsetHours, offsetMinutes)
        }

        if abbreviation == offsetString {
            return offsetString
        } else {
            return "\(abbreviation) • \(offsetString)"
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedTimezone = TimeZone.current.identifier
        
        var body: some View {
            Form {
                Section("Timezone Selection") {
                    TimezonePicker(selectedTimezone: $selectedTimezone)
                }
                
                Section("Selected") {
                    Text("Selected: \(selectedTimezone)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    return PreviewWrapper()
} 
