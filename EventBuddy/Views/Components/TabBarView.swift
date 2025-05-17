import SwiftUI

struct TabBarView: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            TabButton(
                title: "Events",
                iconName: "calendar",
                isSelected: selectedTab == 0
            ) {
                selectedTab = 0
            }
            
            TabButton(
                title: "Friends",
                iconName: "person.2",
                isSelected: selectedTab == 1
            ) {
                selectedTab = 1
            }
            
            TabButton(
                title: "Profile",
                iconName: "person.crop.circle",
                isSelected: selectedTab == 2
            ) {
                selectedTab = 2
            }
            
            TabButton(
                title: "Settings",
                iconName: "clock",
                isSelected: selectedTab == 3
            ) {
                selectedTab = 3
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.systemGray4)),
            alignment: .top
        )
    }
}

struct TabButton: View {
    let title: String
    let iconName: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: iconName)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .blue : .gray)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TabBarView(selectedTab: .constant(0))
} 