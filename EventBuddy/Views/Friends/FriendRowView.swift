//
//  FriendRowView.swift
//  EventBuddy
//
//  Created by Harry Ng on 22/5/2025.
//

import SwiftUI

struct FriendRowView: View {
    let friend: Friend
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(friend.name)
                        .font(.headline)
                    
                    if friend.isFavorite {
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
                if friend.phone != nil {
                    Button {
                        // Phone action
                    } label: {
                        Image(systemName: "phone")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                }
                
                if friend.email != nil {
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
        let hasJobTitle = friend.jobTitle != nil && !friend.jobTitle!.isEmpty
        let hasCompany = friend.company != nil && !friend.company!.isEmpty
        
        if hasJobTitle && hasCompany {
            return "\(friend.jobTitle!) at \(friend.company!)"
        } else if hasJobTitle {
            return friend.jobTitle!
        } else if hasCompany {
            return friend.company!
        } else {
            return ""
        }
    }
}

#Preview {
    FriendRowView(friend: Friend.preview)
        .padding()
}
