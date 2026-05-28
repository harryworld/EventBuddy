#if os(macOS)
import AppKit
import Darwin
import Foundation

@MainActor
enum CLIInstaller {
    static let shimName = "wwdcbuddy"

    static var defaultInstallDirectory: URL {
        realUserHomeDirectory
            .appendingPathComponent(".local", isDirectory: true)
            .appendingPathComponent("bin", isDirectory: true)
    }

    static var bundledCLIURL: URL {
        Bundle.main.bundleURL
            .appendingPathComponent("Contents", isDirectory: true)
            .appendingPathComponent("Helpers", isDirectory: true)
            .appendingPathComponent("wwdcbuddy")
    }

    static func installShim() throws -> URL {
        if isRunningInSandbox {
            guard let directory = chooseInstallDirectory() else {
                throw CLIInstallerError.userCancelled
            }
            return try installShim(in: directory)
        }

        return try installShim(in: defaultInstallDirectory)
    }

    static func installShim(in directory: URL) throws -> URL {
        guard FileManager.default.fileExists(atPath: bundledCLIURL.path) else {
            throw CLIInstallerError.missingBundledCLI(bundledCLIURL.path)
        }

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let destinationURL = directory.appendingPathComponent(shimName)
        let script = """
        #!/bin/sh
        exec \(shellQuoted(bundledCLIURL.path)) "$@"
        """
        try script.write(to: destinationURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: destinationURL.path
        )
        return destinationURL
    }

    static func removeShim() throws -> CLIShimRemovalResult {
        if isRunningInSandbox {
            guard let directory = chooseInstallDirectory(
                prompt: "Remove",
                message: "Choose the folder containing wwdcbuddy. The usual location is \(defaultInstallDirectory.path)."
            ) else {
                throw CLIInstallerError.userCancelled
            }
            return try removeShim(in: directory)
        }

        return try removeShim(in: defaultInstallDirectory)
    }

    static func removeShim(in directory: URL) throws -> CLIShimRemovalResult {
        let destinationURL = directory.appendingPathComponent(shimName)
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: destinationURL.path, isDirectory: &isDirectory) else {
            return .notFound(destinationURL)
        }
        guard !isDirectory.boolValue else {
            throw CLIInstallerError.installedCLIIsDirectory(destinationURL.path)
        }

        try FileManager.default.removeItem(at: destinationURL)
        return .removed(destinationURL)
    }

    static func chooseInstallDirectory() -> URL? {
        chooseInstallDirectory(
            prompt: "Install",
            message: "Choose a folder on your shell PATH. The usual location is \(defaultInstallDirectory.path)."
        )
    }

    private static func chooseInstallDirectory(prompt: String, message: String) -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Choose CLI Install Folder"
        panel.prompt = prompt
        panel.message = message
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = defaultInstallDirectory
        return panel.runModal() == .OK ? panel.url : nil
    }

    private static func shellQuoted(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }

    private static var isRunningInSandbox: Bool {
        FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL.path != realUserHomeDirectory.standardizedFileURL.path
    }

    private static var realUserHomeDirectory: URL {
        if let passwd = getpwuid(getuid()), let home = passwd.pointee.pw_dir {
            return URL(fileURLWithPath: String(cString: home), isDirectory: true)
        }

        return FileManager.default.homeDirectoryForCurrentUser
    }
}

enum CLIShimRemovalResult {
    case removed(URL)
    case notFound(URL)

    var statusMessage: String {
        switch self {
        case let .removed(url):
            return "Removed \(url.path)"
        case let .notFound(url):
            return "No CLI found at \(url.path)"
        }
    }
}

enum CLIInstallerError: LocalizedError {
    case missingBundledCLI(String)
    case installedCLIIsDirectory(String)
    case userCancelled

    var errorDescription: String? {
        switch self {
        case let .missingBundledCLI(path):
            return "The bundled CLI was not found at \(path). Rebuild WWDCBuddy and try again."
        case let .installedCLIIsDirectory(path):
            return "Cannot remove \(path) because it is a folder."
        case .userCancelled:
            return "CLI installation cancelled."
        }
    }
}
#endif
