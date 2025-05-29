import SwiftUI
import SwiftData

struct FriendHeaderView: View {
    let friend: Friend
    let modelContext: ModelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(friend.name)
                    .font(.largeTitle)
                    .bold()
                
                Spacer()
                
                Button {
                    friend.toggleFavorite()
                    try? modelContext.save()
                } label: {
                    Image(systemName: friend.isFavorite ? "star.fill" : "star")
                        .font(.title)
                        .foregroundColor(friend.isFavorite ? .yellow : .gray)
                }
            }
            
            if let companyInfo = friendCompanyInfo, !companyInfo.isEmpty {
                Text(companyInfo)
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var friendCompanyInfo: String? {
        var components: [String] = []
        
        if let jobTitle = friend.jobTitle, !jobTitle.isEmpty {
            components.append(jobTitle)
        }
        
        if let company = friend.company, !company.isEmpty {
            components.append("at \(company)")
        }
        
        return components.isEmpty ? nil : components.joined(separator: " ")
    }
} 