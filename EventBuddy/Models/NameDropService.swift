import Foundation
import Contacts
import SwiftUI

@Observable class NameDropService: NSObject {
    var isSharing = false
    var errorMessage: String?
    var statusMessage: String?
    
    private var contactToShare: CNContact?
    private var shareTimer: Timer?
    
    // Start sharing contact data via NameDrop simulation
    func startSharing(contact: CNContact) {
        #if os(iOS)
        self.contactToShare = contact
        
        // Create vCard data from CNContact
        do {
            let _ = try CNContactVCardSerialization.data(with: [contact])
            startNameDropSimulation()
        } catch {
            errorMessage = "Failed to create contact data: \(error.localizedDescription)"
        }
        #else
        errorMessage = "NameDrop is only available on iOS devices"
        #endif
    }
    
    // Stop sharing contact data
    func stopSharing() {
        shareTimer?.invalidate()
        shareTimer = nil
        isSharing = false
        statusMessage = "Sharing stopped"
    }
    
    private func startNameDropSimulation() {
        // Simulate the NameDrop experience with status updates
        isSharing = true
        statusMessage = "Ready to share contact via NameDrop"
        
        // Set up a timer to simulate the various states of NameDrop
        shareTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            
            let states = [
                "Ready to share contact via NameDrop",
                "Searching for nearby devices...",
                "Hold your iPhone near another device",
                "Waiting for acceptance...",
                "Device detected nearby!"
            ]
            
            let randomState = states.randomElement() ?? states[0]
            self.statusMessage = randomState
        }
    }
    
    // Method to share contact via standard share sheet (fallback)
    func shareViaSheet() {
        #if os(iOS)
        guard let contact = contactToShare,
              let contactData = try? CNContactVCardSerialization.data(with: [contact]) else {
            errorMessage = "Could not prepare contact data"
            return
        }
        
        // Here we would implement the actual sharing via the system share sheet
        // but for simplicity in this simulation, we'll just update the status
        statusMessage = "Contact shared via system sheet"
        #endif
    }
} 