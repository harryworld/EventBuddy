#if os(macOS)
import Foundation

@MainActor
final class EventBuddyCLICommandProcessor {
    private let persistenceService: EventPersistenceService
    private var processingTask: Task<Void, Never>?
    private let fileManager = FileManager.default

    init(persistenceService: EventPersistenceService) {
        self.persistenceService = persistenceService
    }

    func start() {
        guard processingTask == nil else { return }

        processingTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                await self?.processPendingCommands()
                try? await Task.sleep(for: .milliseconds(750))
            }
        }
    }

    func stop() {
        processingTask?.cancel()
        processingTask = nil
    }

    private func processPendingCommands() async {
        do {
            let inbox = try commandDirectory(named: "inbox")
            let commandURLs = try fileManager
                .contentsOfDirectory(
                    at: inbox,
                    includingPropertiesForKeys: [.creationDateKey],
                    options: [.skipsHiddenFiles]
                )
                .filter { $0.pathExtension == "json" }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }

            for commandURL in commandURLs {
                await processCommand(at: commandURL)
            }
        } catch {
            print("EventBuddy CLI command scan failed: \(error)")
        }
    }

    private func processCommand(at commandURL: URL) async {
        let commandID = commandURL.deletingPathExtension().lastPathComponent

        do {
            let data = try Data(contentsOf: commandURL)
            let command = try JSONDecoder().decode(CLICommandEnvelope.self, from: data)
            let responsePayload = try await handle(command)
            try writeResponse(
                CLICommandResponse(
                    id: command.id,
                    status: "success",
                    message: "Saved in WWDCBuddy and pushed to iCloud if sync is enabled.",
                    payload: responsePayload
                ),
                commandID: command.id
            )
            try fileManager.removeItem(at: commandURL)
        } catch {
            try? writeResponse(
                CLICommandResponse(
                    id: commandID,
                    status: "error",
                    message: error.localizedDescription,
                    payload: nil
                ),
                commandID: commandID
            )
            try? fileManager.removeItem(at: commandURL)
        }
    }

    private func handle(_ command: CLICommandEnvelope) async throws -> CLICommandResponsePayload? {
        switch command.kind {
        case "updateFriend":
            guard let friendID = command.payload.friendID else {
                throw CLICommandError.missingField("friendID")
            }
            guard let changes = command.payload.changes else {
                throw CLICommandError.missingField("changes")
            }
            guard let friend = persistenceService.friend(for: friendID) else {
                throw CLICommandError.notFound("Friend \(friendID.uuidString) was not found")
            }

            var socialMediaHandles = friend.socialMediaHandles
            var shouldUpdateSocialMediaHandles = false
            if changes.clearSocial == true {
                socialMediaHandles = [:]
                shouldUpdateSocialMediaHandles = true
            }
            if let changedHandles = changes.socialMediaHandles {
                for (platform, handle) in changedHandles {
                    socialMediaHandles[platform] = handle
                }
                shouldUpdateSocialMediaHandles = true
            }

            friend.update(
                name: changes.name,
                email: changes.email,
                phone: changes.phone,
                jobTitle: changes.jobTitle,
                company: changes.company,
                socialMediaHandles: shouldUpdateSocialMediaHandles ? socialMediaHandles : nil,
                notes: changes.notes,
                isFavorite: changes.isFavorite
            )

            try persistenceService.persist(friend)
            await CloudKitSyncPusher.pushLocalChanges()
            return .friend(CLIFriendPayload(friend: friend))

        case "linkFriendToEvent", "unlinkFriendFromEvent":
            guard let eventID = command.payload.eventID else {
                throw CLICommandError.missingField("eventID")
            }
            guard let friendID = command.payload.friendID else {
                throw CLICommandError.missingField("friendID")
            }
            guard let relationship = command.payload.relationship else {
                throw CLICommandError.missingField("relationship")
            }
            guard let event = persistenceService.event(for: eventID) else {
                throw CLICommandError.notFound("Event \(eventID.uuidString) was not found")
            }
            guard let friend = persistenceService.friend(for: friendID) else {
                throw CLICommandError.notFound("Friend \(friendID.uuidString) was not found")
            }

            let shouldLink = command.kind == "linkFriendToEvent"
            switch (relationship, shouldLink) {
            case (.attending, true):
                event.addFriend(friend)
            case (.attending, false):
                event.removeFriend(friendID)
            case (.wish, true):
                event.addFriendWish(friend)
            case (.wish, false):
                event.removeFriendWish(friendID)
            }

            try persistenceService.persist(event)
            await CloudKitSyncPusher.pushLocalChanges()
            return .relationship(
                CLIRelationshipPayload(
                    eventID: event.id,
                    friendID: friend.id,
                    relationship: relationship
                )
            )

        default:
            throw CLICommandError.unsupportedCommand(command.kind)
        }
    }

    private func commandDirectory(named name: String) throws -> URL {
        guard let groupURL = fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: EventBuddyStorageConfiguration.appGroupIdentifier
        ) else {
            throw CLICommandError.missingAppGroup
        }

        let directory = groupURL
            .appendingPathComponent("CLICommands", isDirectory: true)
            .appendingPathComponent(name, isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    private func writeResponse(_ response: CLICommandResponse, commandID: String) throws {
        let outbox = try commandDirectory(named: "outbox")
        let responseURL = outbox.appendingPathComponent("\(commandID).json")
        let temporaryURL = outbox.appendingPathComponent("\(commandID).json.tmp")
        let data = try JSONEncoder.eventBuddyCLI.encode(response)
        try data.write(to: temporaryURL, options: .atomic)
        if fileManager.fileExists(atPath: responseURL.path) {
            try fileManager.removeItem(at: responseURL)
        }
        try fileManager.moveItem(at: temporaryURL, to: responseURL)
    }
}

private struct CLICommandEnvelope: Decodable {
    let id: String
    let kind: String
    let payload: CLICommandPayload
}

private struct CLICommandPayload: Decodable {
    let friendID: UUID?
    let eventID: UUID?
    let relationship: CLIRelationshipKind?
    let changes: CLIFriendChanges?
}

private struct CLIFriendChanges: Decodable {
    let name: String?
    let email: String?
    let phone: String?
    let jobTitle: String?
    let company: String?
    let notes: String?
    let isFavorite: Bool?
    let socialMediaHandles: [String: String]?
    let clearSocial: Bool?
}

private enum CLIRelationshipKind: String, Codable {
    case attending
    case wish
}

private struct CLICommandResponse: Encodable {
    let id: String
    let status: String
    let message: String
    let payload: CLICommandResponsePayload?
}

private enum CLICommandResponsePayload: Encodable {
    case friend(CLIFriendPayload)
    case relationship(CLIRelationshipPayload)

    func encode(to encoder: Encoder) throws {
        switch self {
        case let .friend(payload):
            try payload.encode(to: encoder)
        case let .relationship(payload):
            try payload.encode(to: encoder)
        }
    }
}

private struct CLIFriendPayload: Encodable {
    let id: UUID
    let name: String
    let email: String?
    let phone: String?
    let jobTitle: String?
    let company: String?
    let socialMediaHandles: [String: String]
    let notes: String?
    let updatedAt: Date
    let isFavorite: Bool

    init(friend: Friend) {
        self.id = friend.id
        self.name = friend.name
        self.email = friend.email
        self.phone = friend.phone
        self.jobTitle = friend.jobTitle
        self.company = friend.company
        self.socialMediaHandles = friend.socialMediaHandles
        self.notes = friend.notes
        self.updatedAt = friend.updatedAt
        self.isFavorite = friend.isFavorite
    }
}

private struct CLIRelationshipPayload: Encodable {
    let eventID: UUID
    let friendID: UUID
    let relationship: CLIRelationshipKind
}

private enum CLICommandError: LocalizedError {
    case missingAppGroup
    case missingField(String)
    case notFound(String)
    case unsupportedCommand(String)

    var errorDescription: String? {
        switch self {
        case .missingAppGroup:
            return "The EventBuddy app group container is unavailable."
        case let .missingField(field):
            return "Missing CLI command field: \(field)"
        case let .notFound(message):
            return message
        case let .unsupportedCommand(command):
            return "Unsupported CLI command: \(command)"
        }
    }
}

private extension JSONEncoder {
    static var eventBuddyCLI: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}
#endif
