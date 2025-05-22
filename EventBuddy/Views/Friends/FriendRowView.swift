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
                
                Text(friendCompanyInfo)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
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
    
    // Extract company info from notes
    private var friendCompanyInfo: String {
        if let notes = friend.notes, notes.hasPrefix("Works at ") {
            return String(notes.dropFirst("Works at ".count))
        } else if let notes = friend.notes, notes.contains("Developer") {
            return notes
        } else if let notes = friend.notes, notes.contains("Dev") {
            return notes
        }
        return ""
    }
}

#Preview {
    FriendRowView(friend: Friend.preview)
        .padding()
}
