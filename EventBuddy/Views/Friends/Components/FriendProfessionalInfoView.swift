import SwiftUI

struct FriendProfessionalInfoView: View {
    let friend: Friend
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Professional Information")
                .font(.headline)
            
            if let jobTitle = friend.jobTitle, !jobTitle.isEmpty {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "briefcase.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Job Title")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                        
                        Text(jobTitle)
                            .font(.body)
                    }
                }
            }
            
            if let company = friend.company, !company.isEmpty {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "building.2.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Company")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                        
                        Text(company)
                            .font(.body)
                    }
                }
            }
        }
    }
} 