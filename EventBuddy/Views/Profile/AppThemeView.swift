import SwiftUI

struct AppThemeView: View {
    let settingsStore: SettingsStore
    
    var body: some View {
        List {
            ForEach(AppTheme.allCases) { theme in
                Button {
                    settingsStore.settings.appTheme = theme
                } label: {
                    HStack {
                        Label(theme.displayName, systemImage: theme.icon)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        if theme == settingsStore.settings.appTheme {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("App Theme")
    }
}

#Preview {
    NavigationStack {
        AppThemeView(settingsStore: SettingsStore())
    }
} 