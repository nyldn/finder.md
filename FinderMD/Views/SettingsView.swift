import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            MonitoredFoldersView()
                .tabItem {
                    Label("Folders", systemImage: "folder")
                }
            
            PreferencesView()
                .tabItem {
                    Label("Preferences", systemImage: "gearshape")
                }
            
            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 500, height: 450)
    }
}

#Preview {
    SettingsView()
}
