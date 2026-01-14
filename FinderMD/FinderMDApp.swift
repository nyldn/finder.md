import SwiftUI

@main
struct FinderMDApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 450, height: 500)
        
        Settings {
            SettingsView()
        }
    }
}
