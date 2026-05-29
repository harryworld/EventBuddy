import Foundation
import Contacts
import CoreImage
import CoreImage.CIFilterBuiltins
import ImageIO
import UniformTypeIdentifiers

/// Generating QR codes inside the widget extension does not render reliably on
/// physical devices (WidgetKit snapshots the view before Core Image work
/// finishes, and the extension runs under a tight memory budget). To work
/// around this, the app pre-renders the profile QR code to a PNG in the shared
/// app group container whenever the profile changes, and the widget simply
/// loads that image.
enum ProfileQRCodeCache {
    static let fileName = "ProfileQRCode.png"

    static var cacheURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: EventBuddyStorageConfiguration.appGroupIdentifier)?
            .appendingPathComponent(fileName)
    }

    /// Returns the cached QR code PNG data, if present.
    static func cachedData() -> Data? {
        guard let cacheURL else { return nil }
        return try? Data(contentsOf: cacheURL)
    }

    /// Regenerates the cached QR PNG for the given profile. Passing `nil`
    /// removes any existing cache (e.g. when no profile exists).
    @discardableResult
    static func update(for profile: Profile?) -> Bool {
        guard let cacheURL else { return false }

        guard let profile, let data = makeQRCodePNGData(for: profile) else {
            try? FileManager.default.removeItem(at: cacheURL)
            return false
        }

        do {
            try data.write(to: cacheURL, options: .atomic)
            return true
        } catch {
            print("Failed to cache profile QR code: \(error)")
            return false
        }
    }

    /// Renders the profile's contact vCard into a QR code PNG.
    static func makeQRCodePNGData(for profile: Profile) -> Data? {
        let contact = profile.createContact()
        guard let vCardData = try? CNContactVCardSerialization.data(with: [contact]) else {
            return nil
        }

        let filter = CIFilter.qrCodeGenerator()
        filter.message = vCardData
        filter.correctionLevel = "H"

        guard let outputImage = filter.outputImage else { return nil }

        // Scale up so the rendered PNG stays crisp at widget sizes.
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))

        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }

        return pngData(from: cgImage)
    }

    private static func pngData(from cgImage: CGImage) -> Data? {
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            return nil
        }

        CGImageDestinationAddImage(destination, cgImage, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return mutableData as Data
    }
}
