import SwiftUI

struct FriendContactInfoView: View {
    let friend: Friend
    
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Contact Information")
                .font(.headline)
            
            if let phone = friend.phone {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Phone")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                        
                        Text(phone)
                            .font(.body)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if let phoneURL = URL(string: "tel:\(phone.replacingOccurrences(of: " ", with: ""))") {
                        openURL(phoneURL)
                    }
                }
            }
            
            if let email = friend.email {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Email")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                        
                        Text(email)
                            .font(.body)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if let emailURL = URL(string: "mailto:\(email)") {
                        openURL(emailURL)
                    }
                }
            }
        }
    }
} 