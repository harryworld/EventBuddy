#if os(macOS)
import AppKit
import Foundation

@MainActor
enum CLIInstaller {
    static let shimName = "wwdcbuddy"

    static var defaultInstallDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
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
        try installShim(in: defaultInstallDirectory)
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

    static func chooseInstallDirectory() -> URL? {
        let panel = NSOpenPanel()
        panel.title = "Choose CLI Install Folder"
        panel.prompt = "Install"
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
}

enum CLIInstallerError: LocalizedError {
    case missingBundledCLI(String)

    var errorDescription: String? {
        switch self {
        case let .missingBundledCLI(path):
            return "The bundled CLI was not found at \(path). Rebuild WWDCBuddy and try again."
        }
    }
}
#endif
