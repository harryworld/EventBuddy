import SwiftUI
import Contacts
import UIKit

struct ProfileView: View {
    let userStore: UserStore
    
    @State private var showingShareSheet = false
    @State private var contactData: Data?
    @State private var showingEditSheet = false
    @State private var qrCodeContact: CNContact
    @State private var qrCodeRefreshTrigger = UUID()
    @State private var isShowingRefreshFeedback = false
    
    init(userStore: UserStore = UserStore()) {
        self.userStore = userStore
        _qrCodeContact = State(initialValue: userStore.currentUser.createContact())
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
                    Menu {
                        Button {
                            showingEditSheet = true
                        } label: {
                            Label("Edit Profile", systemImage: "pencil")
                        }
                        
                        Button {
                            shareContact()
                        } label: {
                            Label("Share Contact", systemImage: "square.and.arrow.up")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let data = contactData {
                    ShareSheet(items: [data])
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                ProfileEditView(user: userStore.currentUser, onSave: {
                    refreshQRCode()
                })
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
    }
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            Image(systemName: userStore.currentUser.avatarSystemName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)
                .padding()
                .background(Circle().fill(Color.blue.opacity(0.1)))
            
            Text(userStore.currentUser.name)
                .font(.title2)
                .fontWeight(.bold)
            
            if !userStore.currentUser.title.isEmpty || !userStore.currentUser.company.isEmpty {
                Text("\(userStore.currentUser.title)\(userStore.currentUser.title.isEmpty || userStore.currentUser.company.isEmpty ? "" : " at ")\(userStore.currentUser.company)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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
            
            QRCodeView(contact: qrCodeContact, size: 220)
                .id(qrCodeRefreshTrigger)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                )
            
            Text("Scan to add me to contacts")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical)
    }
    
    private var contactInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Contact Information")
                .font(.headline)
            
            contactInfoRow(icon: "envelope.fill", title: "Email", value: userStore.currentUser.email)
            contactInfoRow(icon: "phone.fill", title: "Phone", value: userStore.currentUser.phone)
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
            
            if userStore.currentUser.socialLinks.isEmpty {
                Text("No social links added")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical)
                
                Button {
                    showingEditSheet = true
                } label: {
                    Label("Add Social Links", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
            } else {
                ForEach(userStore.currentUser.socialLinks) { link in
                    socialLinkRow(link: link)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func socialLinkRow(link: SocialLink) -> some View {
        HStack(spacing: 12) {
            Image(systemName: link.service.icon)
                .foregroundColor(.blue)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(link.service.displayName)
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
        qrCodeContact = userStore.currentUser.createContact()
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
    
    private func shareContact() {
        let contact = userStore.currentUser.createContact()
        contactData = try? CNContactVCardSerialization.data(with: [contact])
        
        if contactData != nil {
            showingShareSheet = true
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ProfileView()
} 