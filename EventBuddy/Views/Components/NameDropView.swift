import SwiftUI
import Contacts

struct NameDropView: View {
    let contact: CNContact
    @State private var isSharing = false
    @State private var statusMessage = "Ready to share contact via NameDrop"
    @State private var errorMessage: String?
    @State private var shareTimer: Timer?
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 24) {
            // Header with close button
            HStack {
                Spacer()
                Button {
                    stopSharing()
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            
            Spacer()
            
            // Animation and status
            VStack(spacing: 16) {
                ZStack {
                    // Background circle
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 200, height: 200)
                    
                    // Ripple effects
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(Color.blue.opacity(0.5), lineWidth: 2)
                            .frame(width: 150 + CGFloat(i * 30), height: 150 + CGFloat(i * 30))
                            .scaleEffect(isSharing ? 1.2 : 0.8)
                            .opacity(isSharing ? 0.0 : 0.8)
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true)
                                    .delay(0.3 * Double(i)),
                                value: isSharing
                            )
                    }
                    
                    // Contact avatar
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .foregroundColor(.blue)
                }
                
                Text(formatName(contact))
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(statusMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top, 8)
                }
            }
            
            Spacer()
            
            // Instructions
            VStack(spacing: 8) {
                Text("Hold your iPhone close to another iPhone")
                    .font(.headline)
                
                Text("Your contact info will be shared automatically")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Button {
                    // Alternative sharing method
                    shareContact()
                } label: {
                    Text("Or use standard sharing instead")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.top, 12)
                }
            }
            .padding(.bottom, 48)
        }
        .onAppear {
            // Start sharing when view appears
            startSharing()
        }
        .onDisappear {
            // Stop sharing when view disappears
            stopSharing()
        }
    }
    
    private func formatName(_ contact: CNContact) -> String {
        var name = ""
        
        if !contact.givenName.isEmpty {
            name += contact.givenName
        }
        
        if !contact.familyName.isEmpty {
            if !name.isEmpty {
                name += " "
            }
            name += contact.familyName
        }
        
        return name.isEmpty ? "Contact" : name
    }
    
    private func startSharing() {
        // Simulate NameDrop experience with status updates
        isSharing = true
        
        // Set up a timer to simulate the various states of NameDrop
        shareTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            let states = [
                "Ready to share contact via NameDrop",
                "Searching for nearby devices...",
                "Hold your iPhone near another device",
                "Waiting for acceptance...",
                "Device detected nearby!"
            ]
            
            statusMessage = states.randomElement() ?? states[0]
        }
    }
    
    private func stopSharing() {
        shareTimer?.invalidate()
        shareTimer = nil
        isSharing = false
    }
    
    private func shareContact() {
        #if os(iOS)
        // Here we would implement the actual sharing
        // This is just a placeholder since the real implementation
        // would require a UIViewControllerRepresentable
        statusMessage = "Contact shared via system sheet"
        
        // Simulate a delay then dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
        #endif
    }
}

#Preview {
    let contact = CNMutableContact()
    contact.givenName = "John"
    contact.familyName = "Appleseed"
    
    return NameDropView(contact: contact)
} 