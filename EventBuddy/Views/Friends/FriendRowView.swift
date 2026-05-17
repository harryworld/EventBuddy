//
//  FriendRowView.swift
//  EventBuddy
//
//  Created by Harry Ng on 22/5/2025.
//

import SwiftUI

struct FriendRowView: View {
    let name: String
    let email: String?
    let phone: String?
    let jobTitle: String?
    let company: String?
    let isFavorite: Bool

    init(friend: Friend) {
        self.name = friend.name
        self.email = friend.email
        self.phone = friend.phone
        self.jobTitle = friend.jobTitle
        self.company = friend.company
        self.isFavorite = friend.isFavorite
    }

    init(friendRow: StoredFriend) {
        self.name = friendRow.name
        self.email = friendRow.email
        self.phone = friendRow.phone
        self.jobTitle = friendRow.jobTitle
        self.company = friendRow.company
        self.isFavorite = friendRow.isFavorite
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(name)
                        .font(.headline)
                    
                    if isFavorite {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                }
                
                if !friendProfessionalInfo.isEmpty {
                    Text(friendProfessionalInfo)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Contact buttons
            HStack(spacing: 16) {
                if phone != nil {
                    Button {
                        // Phone action
                    } label: {
                        Image(systemName: "phone")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }
                
                if email != nil {
                    Button {
                        // Email action
                    } label: {
                        Image(systemName: "envelope")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // Build professional info from job title and company
    private var friendProfessionalInfo: String {
        let hasJobTitle = jobTitle != nil && !jobTitle!.isEmpty
        let hasCompany = company != nil && !company!.isEmpty
        
        if hasJobTitle && hasCompany {
            return "\(jobTitle!) at \(company!)"
        } else if hasJobTitle {
            return jobTitle!
        } else if hasCompany {
            return company!
        } else {
            return ""
        }
    }
}

#Preview {
    FriendRowView(friend: Friend.preview)
        .padding()
}
