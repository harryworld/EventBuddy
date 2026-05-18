import EventKit
import Foundation

@MainActor
@Observable
final class EventCalendarStore {
    struct CalendarChoice: Identifiable, Hashable {
        let id: String
        let title: String
        let sourceTitle: String
        let isDefault: Bool

        var displayName: String {
            title
        }
    }

    enum AddOutcome: Equatable {
        case added
        case alreadyExists
        case accessDenied
        case noWritableCalendar
        case failed(String)

        var foundOrAddedEvent: Bool {
            switch self {
            case .added, .alreadyExists:
                return true
            case .accessDenied, .noWritableCalendar, .failed:
                return false
            }
        }
    }

    struct BatchAddSummary: Equatable {
        var requested = 0
        var added = 0
        var skippedExisting = 0
        var failed = 0
        var targetCalendarTitle: String?
        var errorMessage: String?

        var message: String {
            if requested == 0 {
                return "No upcoming attending events to add."
            }

            var parts: [String] = []
            if added > 0 {
                parts.append("\(added) added")
            }
            if skippedExisting > 0 {
                parts.append("\(skippedExisting) already in calendar")
            }
            if failed > 0 {
                parts.append("\(failed) failed")
            }

            let summary = parts.isEmpty ? "No events added" : parts.joined(separator: ", ")
            if let targetCalendarTitle {
                return "\(summary) to \(targetCalendarTitle)."
            }
            return "\(summary)."
        }
    }

    static let selectedCalendarIdentifierKey = "EventBuddy.EventCalendarStore.selectedCalendarIdentifier"

    @ObservationIgnored private let eventStore: EKEventStore
    @ObservationIgnored private let userDefaults: UserDefaults

    var authorizationStatus: EKAuthorizationStatus
    var calendars: [CalendarChoice] = []
    var selectedCalendarIdentifier: String? {
        didSet {
            if let selectedCalendarIdentifier {
                userDefaults.set(selectedCalendarIdentifier, forKey: Self.selectedCalendarIdentifierKey)
            } else {
                userDefaults.removeObject(forKey: Self.selectedCalendarIdentifierKey)
            }
        }
    }

    init(eventStore: EKEventStore = EKEventStore(), userDefaults: UserDefaults = .standard) {
        self.eventStore = eventStore
        self.userDefaults = userDefaults
        self.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        self.selectedCalendarIdentifier = userDefaults.string(forKey: Self.selectedCalendarIdentifierKey)
        reloadCalendarsIfAuthorized()
    }

    var hasFullAccess: Bool {
        authorizationStatus == .fullAccess
    }

    var authorizationDescription: String {
        switch authorizationStatus {
        case .notDetermined:
            return "Not Requested"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied"
        case .fullAccess:
            return "Allowed"
        case .writeOnly:
            return "Write Only"
        @unknown default:
            return "Unknown"
        }
    }

    func refreshAuthorizationStatus() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        reloadCalendarsIfAuthorized()
    }

    @discardableResult
    func requestFullAccess() async -> Bool {
        refreshAuthorizationStatus()

        if hasFullAccess {
            return true
        }

        switch authorizationStatus {
        case .notDetermined, .writeOnly:
            do {
                let granted = try await eventStore.requestFullAccessToEvents()
                refreshAuthorizationStatus()
                return granted && hasFullAccess
            } catch {
                refreshAuthorizationStatus()
                return false
            }
        case .restricted, .denied, .fullAccess:
            return hasFullAccess
        @unknown default:
            return false
        }
    }

    func eventExists(_ event: Event) -> Bool {
        guard hasFullAccess, let calendar = selectedCalendar() else {
            return false
        }
        return matchingCalendarEvent(for: event, in: calendar) != nil
    }

    func add(_ event: Event) async -> AddOutcome {
        guard await requestFullAccess() else {
            return .accessDenied
        }

        guard let calendar = selectedCalendar() else {
            return .noWritableCalendar
        }

        return addAuthorized(event, to: calendar)
    }

    func addEvents(_ events: [Event]) async -> BatchAddSummary {
        var summary = BatchAddSummary(requested: events.count)
        guard !events.isEmpty else {
            return summary
        }

        guard await requestFullAccess() else {
            summary.failed = events.count
            summary.errorMessage = "Calendar access is required before adding events."
            return summary
        }

        guard let calendar = selectedCalendar() else {
            summary.failed = events.count
            summary.errorMessage = "No writable calendar is available."
            return summary
        }

        summary.targetCalendarTitle = calendarDisplayName(for: calendar)

        for event in events {
            switch addAuthorized(event, to: calendar) {
            case .added:
                summary.added += 1
            case .alreadyExists:
                summary.skippedExisting += 1
            case .accessDenied, .noWritableCalendar:
                summary.failed += 1
            case let .failed(message):
                summary.failed += 1
                summary.errorMessage = message
            }
        }

        return summary
    }

    private func addAuthorized(_ event: Event, to calendar: EKCalendar) -> AddOutcome {
        if matchingCalendarEvent(for: event, in: calendar) != nil {
            return .alreadyExists
        }

        let calendarEvent = EKEvent(eventStore: eventStore)
        calendarEvent.title = event.title
        calendarEvent.notes = calendarNotes(for: event)
        calendarEvent.location = event.location
        calendarEvent.startDate = event.startDate
        calendarEvent.endDate = event.endDate
        calendarEvent.calendar = calendar
        if let urlString = event.url, let url = URL(string: urlString) {
            calendarEvent.url = url
        }

        do {
            try eventStore.save(calendarEvent, span: .thisEvent)
            return .added
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    private func reloadCalendarsIfAuthorized() {
        guard hasFullAccess else {
            calendars = []
            return
        }

        let defaultCalendarID = eventStore.defaultCalendarForNewEvents?.calendarIdentifier
        let writableCalendars = eventStore.calendars(for: .event)
            .filter(\.allowsContentModifications)
            .map { calendar in
                CalendarChoice(
                    id: calendar.calendarIdentifier,
                    title: calendar.title,
                    sourceTitle: calendar.source.title,
                    isDefault: calendar.calendarIdentifier == defaultCalendarID
                )
            }
            .sorted { lhs, rhs in
                lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
            }

        calendars = writableCalendars

        if let selectedCalendarIdentifier,
           writableCalendars.contains(where: { $0.id == selectedCalendarIdentifier }) {
            return
        }

        if let defaultCalendarID,
           writableCalendars.contains(where: { $0.id == defaultCalendarID }) {
            selectedCalendarIdentifier = defaultCalendarID
        } else {
            selectedCalendarIdentifier = writableCalendars.first?.id
        }
    }

    private func selectedCalendar() -> EKCalendar? {
        if let selectedCalendarIdentifier,
           let calendar = eventStore.calendar(withIdentifier: selectedCalendarIdentifier),
           calendar.allowsContentModifications {
            return calendar
        }

        if let defaultCalendar = eventStore.defaultCalendarForNewEvents,
           defaultCalendar.allowsContentModifications {
            selectedCalendarIdentifier = defaultCalendar.calendarIdentifier
            return defaultCalendar
        }

        if let calendar = eventStore.calendars(for: .event).first(where: \.allowsContentModifications) {
            selectedCalendarIdentifier = calendar.calendarIdentifier
            return calendar
        }

        return nil
    }

    private func matchingCalendarEvent(for event: Event, in calendar: EKCalendar) -> EKEvent? {
        let predicate = eventStore.predicateForEvents(
            withStart: event.startDate.addingTimeInterval(-60),
            end: event.endDate.addingTimeInterval(60),
            calendars: [calendar]
        )

        return eventStore.events(matching: predicate).first { calendarEvent in
            calendarEventMatches(calendarEvent, event: event)
        }
    }

    private func calendarEventMatches(_ calendarEvent: EKEvent, event: Event) -> Bool {
        if calendarEvent.notes?.contains(eventMarker(for: event)) == true {
            return true
        }

        guard calendarEvent.title == event.title else {
            return false
        }

        let startsAtSameTime = abs(calendarEvent.startDate.timeIntervalSince(event.startDate)) < 60
        let endsAtSameTime = abs(calendarEvent.endDate.timeIntervalSince(event.endDate)) < 60
        guard startsAtSameTime, endsAtSameTime else {
            return false
        }

        let expectedLocation = normalized(event.location)
        let existingLocation = normalized(calendarEvent.location ?? "")

        return expectedLocation.isEmpty || existingLocation.isEmpty || expectedLocation == existingLocation
    }

    private func calendarNotes(for event: Event) -> String {
        var parts: [String] = []
        if !event.eventDescription.isEmpty {
            parts.append(event.eventDescription)
        }
        if let notes = event.notes, !notes.isEmpty {
            parts.append(notes)
        }
        if let url = event.url, !url.isEmpty {
            parts.append(url)
        }
        parts.append(eventMarker(for: event))
        return parts.joined(separator: "\n\n")
    }

    private func eventMarker(for event: Event) -> String {
        "WWDCBuddy event ID: \(event.id.uuidString)"
    }

    private func normalized(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func calendarDisplayName(for calendar: EKCalendar) -> String {
        calendar.title
    }
}
