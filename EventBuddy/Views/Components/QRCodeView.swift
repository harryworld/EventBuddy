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
    
    @State private var qrCode: PlatformImage?
    
    init(contact: CNContact, size: CGFloat = 200) {
        self.contact = contact
        self.size = size
    }
    
    var body: some View {
        Group {
            if let qrCode {
                platformImage(qrCode)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
            } else {
                ProgressView()
                    .frame(width: size, height: size)
            }
        }
        .onAppear {
            generateQRCode()
        }
    }
    
    private func generateQRCode() {
        // Create vCard data from CNContact
        let data = try? CNContactVCardSerialization.data(with: [contact])
        
        guard let data = data else {
            return
        }
        
        // Create QR code from data
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        filter.message = data
        filter.correctionLevel = "H" // High error correction
        
        guard let outputImage = filter.outputImage else {
            return
        }
        
        // Scale the QR code for better visibility
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        
        if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
            #if os(macOS)
            qrCode = NSImage(cgImage: cgImage, size: NSSize(width: size, height: size))
            #else
            qrCode = UIImage(cgImage: cgImage)
            #endif
        }
    }

    private func platformImage(_ image: PlatformImage) -> Image {
        #if os(macOS)
        Image(nsImage: image)
        #else
        Image(uiImage: image)
        #endif
    }
}
