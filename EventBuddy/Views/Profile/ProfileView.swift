import SwiftUI
import Contacts
import UIKit
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [Profile]
    
    @State private var showingEditSheet = false
    @State private var qrCodeContact: CNContact?
    @State private var qrCodeRefreshTrigger = UUID()
    @State private var isShowingRefreshFeedback = false
    @State private var isShowingNameDrop = false
    
    private var currentProfile: Profile {
        profiles.first ?? createDefaultProfile()
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile header
                    profileHeader
                    
                    Divider()
                    
                    // QR Code Section
                    qrCodeSection
                    
                    Divider()
                    
                    // Contact Information
                    contactInfoSection
                    
                    Divider()
                    
                    // Social Links
                    socialLinksSection
                }
                .padding()
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Image(systemName: "pencil")
                    }
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                ProfileEditView(profile: currentProfile, onSave: {
                    refreshQRCode()
                })
            }
            .sheet(isPresented: $isShowingNameDrop) {
                if let contact = qrCodeContact {
                    NameDropView(contact: contact)
                }
            }
            .overlay {
                if isShowingRefreshFeedback {
                    VStack {
                        Text("QR Code Updated")
                            .font(.subheadline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.blue.opacity(0.9))
                            )
                            .foregroundColor(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                    .animation(.easeInOut, value: isShowingRefreshFeedback)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.top, 100)
                }
            }
        }
        .onAppear {
            refreshQRCode()
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            Image(systemName: currentProfile.avatarSystemName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
                .padding()
                .background(Circle().fill(Color.blue.opacity(0.1)))
            
            Text(currentProfile.name)
                .font(.title2)
                .fontWeight(.bold)
            
            if !currentProfile.title.isEmpty || !currentProfile.company.isEmpty {
                Text("\(currentProfile.title)\(currentProfile.title.isEmpty || currentProfile.company.isEmpty ? "" : " at ")\(currentProfile.company)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            if !currentProfile.bio.isEmpty {
                Text(currentProfile.bio)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button {
                showingEditSheet = true
            } label: {
                Label("Edit Profile", systemImage: "pencil")
                    .font(.footnote)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)
            }
        }
    }
    
    private var qrCodeSection: some View {
        VStack(spacing: 16) {
            Text("My Contact Card")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if let contact = qrCodeContact {
                QRCodeView(contact: contact, size: 220)
                    .id(qrCodeRefreshTrigger)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    )
            } else {
                ProgressView()
                    .frame(width: 220, height: 220)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                    )
            }
            
            Text("Scan to add me to contacts")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            // NameDrop button
            Button {
                startNameDrop()
            } label: {
                HStack {
                    Image(systemName: "wave.3.right.circle.fill")
                        .font(.title2)
                    Text("Share via NameDrop")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .padding(.top, 8)
            
            // Share Contact link
            if let contact = qrCodeContact,
               let contactData = try? CNContactVCardSerialization.data(with: [contact]) {
                ShareLink(item: contactData, preview: SharePreview("Contact Card", image: Image(systemName: "person.crop.rectangle"))) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                            .font(.callout)
                        Text("Share Contact")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical)
    }
    
    private var contactInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Contact Information")
                .font(.headline)
            
            if let email = currentProfile.email, !email.isEmpty {
                contactInfoRow(icon: "envelope.fill", title: "Email", value: email)
            }
            
            if let phone = currentProfile.phone, !phone.isEmpty {
                contactInfoRow(icon: "phone.fill", title: "Phone", value: phone)
            }
            
            if (currentProfile.email?.isEmpty ?? true) && (currentProfile.phone?.isEmpty ?? true) {
                Text("No contact information added")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical)
                
                Button {
                    showingEditSheet = true
                } label: {
                    Label("Add Contact Info", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func contactInfoRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.body)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var socialLinksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Social Links")
                .font(.headline)
            
            if currentProfile.socialLinks.isEmpty {
                Text("No social links added")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical)
            } else {
                ForEach(currentProfile.socialLinks) { link in
                    socialLinkRow(link: link)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func socialLinkRow(link: SocialLinkInfo) -> some View {
        HStack(spacing: 12) {
            Image(systemName: link.icon)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(link.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("@\(link.username)")
                    .font(.body)
            }
            
            Spacer()
            
            Link(destination: URL(string: link.url)!) {
                Image(systemName: "arrow.up.forward.app")
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func refreshQRCode() {
        qrCodeContact = currentProfile.createContact()
        qrCodeRefreshTrigger = UUID() // Force view to refresh
        
        // Show feedback toast
        withAnimation {
            isShowingRefreshFeedback = true
        }
        
        // Hide feedback after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                isShowingRefreshFeedback = false
            }
        }
    }
    
    private func startNameDrop() {
        // Show the NameDrop sheet which will handle the interaction
        isShowingNameDrop = true
    }
    
    private func createDefaultProfile() -> Profile {
        let defaultProfile = Profile(
            name: "Your Name",
            bio: "Add your bio here",
            email: nil,
            phone: nil,
            profileImage: nil,
            socialMediaAccounts: [:],
            preferences: [
                "darkMode": false,
                "notificationsEnabled": true,
                "shareLocation": false
            ],
            title: "",
            company: "",
            avatarSystemName: "person.crop.circle.fill"
        )
        
        modelContext.insert(defaultProfile)
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving default profile: \(error)")
        }
        
        return defaultProfile
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Profile.self, configurations: config)
    let context = container.mainContext
    
    let sampleProfile = Profile.preview
    context.insert(sampleProfile)
    
    return ProfileView()
        .modelContainer(container)
} 