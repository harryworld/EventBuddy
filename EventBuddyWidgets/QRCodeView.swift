import SwiftUI
import CoreImage.CIFilterBuiltins
import Contacts

#if os(macOS)
import AppKit
private typealias PlatformImage = NSImage
#else
import UIKit
private typealias PlatformImage = UIImage
#endif

struct QRCodeView: View {
    let contact: CNContact
    let size: CGFloat

    init(contact: CNContact, size: CGFloat = 200) {
        self.contact = contact
        self.size = size
    }

    var body: some View {
        // Prefer the image the app pre-rendered to the shared app group. The
        // widget extension cannot reliably render a QR code on-device, so the
        // cached PNG is the source of truth. Live generation is only a fallback
        // for the rare case where the cache has not been written yet.
        Group {
            if let image = cachedImage() ?? generatedImage() {
                platformImage(image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
            } else {
                Image(systemName: "qrcode")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
                    .frame(width: size, height: size)
            }
        }
    }

    private func cachedImage() -> PlatformImage? {
        guard let data = ProfileQRCodeCache.cachedData() else { return nil }
        return PlatformImage(data: data)
    }

    private func generatedImage() -> PlatformImage? {
        guard let data = try? CNContactVCardSerialization.data(with: [contact]) else {
            return nil
        }

        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = data
        filter.correctionLevel = "H" // High error correction

        guard let outputImage = filter.outputImage else { return nil }

        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }

        #if os(macOS)
        return NSImage(cgImage: cgImage, size: NSSize(width: size, height: size))
        #else
        return UIImage(cgImage: cgImage)
        #endif
    }

    private func platformImage(_ image: PlatformImage) -> Image {
        #if os(macOS)
        Image(nsImage: image)
        #else
        Image(uiImage: image)
        #endif
    }
}
