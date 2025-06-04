import WidgetKit
import SwiftUI
import SwiftData
import Contacts

// MARK: - QR Code Widget Entry
struct QRCodeWidgetEntry: TimelineEntry {
    let date: Date
    let profile: Profile?
}

// MARK: - QR Code Timeline Provider
struct QRCodeTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> QRCodeWidgetEntry {
        QRCodeWidgetEntry(date: Date(), profile: nil)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (QRCodeWidgetEntry) -> Void) {
        Task {
            let entry = await createEntry()
            completion(entry)
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<QRCodeWidgetEntry>) -> Void) {
        Task {
            let entry = await createEntry()
            
            // Refresh every 24 hours since profile data doesn't change frequently
            let nextUpdate = Calendar.current.date(byAdding: .hour, value: 24, to: Date()) ?? Date()
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            completion(timeline)
        }
    }
    
    @MainActor
    private func createEntry() async -> QRCodeWidgetEntry {
        let provider = WidgetDataProvider.shared
        let profile = provider.getCurrentProfile()
        
        return QRCodeWidgetEntry(
            date: Date(),
            profile: profile
        )
    }
}

// MARK: - QR Code Widget Entry View
struct QRCodeWidgetEntryView: View {
    var entry: QRCodeWidgetEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallQRCodeWidgetView(entry: entry)
        case .systemMedium:
            MediumQRCodeWidgetView(entry: entry)
        default:
            SmallQRCodeWidgetView(entry: entry)
        }
    }
}

// MARK: - Small QR Code Widget View
struct SmallQRCodeWidgetView: View {
    let entry: QRCodeWidgetEntry
    
    var body: some View {
        VStack(spacing: 8) {
            if let profile = entry.profile {
                QRCodeView(contact: profile.createContact(), size: 100)
                
                Text("My Contact")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("Setup Profile")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "eventbuddy://profile"))
    }
}

// MARK: - Medium QR Code Widget View
struct MediumQRCodeWidgetView: View {
    let entry: QRCodeWidgetEntry
    
    var body: some View {
        HStack(spacing: 16) {
            if let profile = entry.profile {
                // QR Code on the left
                QRCodeView(contact: profile.createContact(), size: 120)
                
                // Profile info on the right
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(profile.name)
                            .font(.headline)
                            .fontWeight(.bold)
                            .lineLimit(1)
                        
                        if !profile.title.isEmpty || !profile.company.isEmpty {
                            Text("\(profile.title)\(profile.title.isEmpty || profile.company.isEmpty ? "" : " at ")\(profile.company)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 2) {
                        if let email = profile.email, !email.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "envelope.fill")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                                Text(email)
                                    .font(.caption2)
                                    .lineLimit(1)
                            }
                        }
                        
                        if let phone = profile.phone, !phone.isEmpty {
                            HStack(spacing: 4) {
                                Image(systemName: "phone.fill")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                                Text(phone)
                                    .font(.caption2)
                                    .lineLimit(1)
                            }
                        }
                    }
                    
                    Text("Tap to Open Profile")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "qrcode")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 4) {
                        Text("QR Contact Sharing")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        Text("Tap to setup your profile and generate a QR code for easy contact sharing")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(4)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(16)
        .widgetURL(URL(string: "eventbuddy://profile"))
    }
}

// MARK: - QR Code Widget Configuration
struct QRCodeWidget: Widget {
    let kind: String = "QRCodeWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: QRCodeTimelineProvider()
        ) { entry in
            QRCodeWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("QR Contact")
        .description("Quick access to your contact QR code for easy sharing.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Previews
#Preview("Small Widget - With Profile", as: .systemSmall) {
    QRCodeWidget()
} timeline: {
    QRCodeWidgetEntry(date: .now, profile: Profile.preview)
}

#Preview("Small Widget - No Profile", as: .systemSmall) {
    QRCodeWidget()
} timeline: {
    QRCodeWidgetEntry(date: .now, profile: nil)
}

#Preview("Medium Widget - With Profile", as: .systemMedium) {
    QRCodeWidget()
} timeline: {
    QRCodeWidgetEntry(date: .now, profile: Profile.preview)
}

#Preview("Medium Widget - No Profile", as: .systemMedium) {
    QRCodeWidget()
} timeline: {
    QRCodeWidgetEntry(date: .now, profile: nil)
} 