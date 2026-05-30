#if os(macOS)
import AppKit
import Foundation

@MainActor
enum RaycastExtensionInstaller {
    static let folderName = "wwdcbuddy-raycast"
    private static let containerSubdirectory = "RaycastExtension"

    /// The prebuilt extension bundled inside the app (compiled JS + manifest + assets).
    static var bundledExtensionURL: URL? {
        guard let resourceURL = Bundle.main.resourceURL else { return nil }
        let url = resourceURL.appendingPathComponent(folderName, isDirectory: true)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }

    /// The destination inside the shared App Group container. The app can write
    /// here without a folder prompt, and Raycast can read it when the import
    /// command runs.
    static var installURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: EventBuddyStorageConfiguration.appGroupIdentifier)?
            .appendingPathComponent(containerSubdirectory, isDirectory: true)
            .appendingPathComponent(folderName, isDirectory: true)
    }

    /// Copies the bundled extension into the App Group container. Returns the
    /// folder Raycast should import.
    @discardableResult
    static func install() throws -> URL {
        guard let source = bundledExtensionURL else {
            throw RaycastExtensionInstallerError.missingBundledExtension
        }
        guard let destination = installURL else {
            throw RaycastExtensionInstallerError.missingContainer
        }

        try FileManager.default.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: source, to: destination)
        return destination
    }

    /// Opens Raycast's Import Extension command and passes the installed folder.
    static func openRaycastImport(at folder: URL) {
        if let raycastImport = raycastImportURL(for: folder),
           NSWorkspace.shared.open(raycastImport) {
            return
        }

        if let raycastImport = URL(string: "raycast://extensions/raycast/developer/import-extension") {
            NSWorkspace.shared.open(raycastImport)
        }
    }

    private static func raycastImportURL(for folder: URL) -> URL? {
        let payload = ["path": folder.path]
        guard let payloadData = try? JSONSerialization.data(withJSONObject: payload),
              let payloadString = String(data: payloadData, encoding: .utf8) else {
            return nil
        }

        var components = URLComponents()
        components.scheme = "raycast"
        components.host = "extensions"
        components.path = "/raycast/developer/import-extension"
        components.queryItems = [
            URLQueryItem(name: "arguments", value: payloadString),
            URLQueryItem(name: "context", value: payloadString),
            URLQueryItem(name: "fallbackText", value: folder.path)
        ]
        return components.url
    }
}

enum RaycastExtensionInstallerError: LocalizedError {
    case missingBundledExtension
    case missingContainer

    var errorDescription: String? {
        switch self {
        case .missingBundledExtension:
            return "The bundled Raycast extension was not found in the app. Rebuild WWDCBuddy and try again."
        case .missingContainer:
            return "Could not access the shared app container to install the Raycast extension."
        }
    }
}
#endif
