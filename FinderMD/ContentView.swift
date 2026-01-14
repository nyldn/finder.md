import SwiftUI
import FinderSync

struct ContentView: View {
    @State private var isExtensionEnabled = false
    @State private var monitoredFoldersCount = 0
    
    var body: some View {
        VStack(spacing: 24) {
            // App icon and title
            Image(systemName: "doc.text.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue.gradient)
            
            Text("FinderMD")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Right-click in Finder to create Markdown files")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Divider()
                .frame(width: 200)
            
            // Extension status
            VStack(spacing: 12) {
                HStack {
                    Circle()
                        .fill(isExtensionEnabled ? Color.green : Color.orange)
                        .frame(width: 12, height: 12)
                    
                    Text(isExtensionEnabled ? "Extension Enabled" : "Extension Not Enabled")
                        .font(.headline)
                }
                
                Text("\(monitoredFoldersCount) folder(s) monitored")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if !isExtensionEnabled {
                    Text("Enable the FinderMD extension in System Settings → Privacy & Security → Extensions → Finder Extensions")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 280)
                }
            }
            .padding()
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            
            Divider()
                .frame(width: 200)
            
            // Quick links
            VStack(spacing: 12) {
                Button("Open Settings...") {
                    openSettings()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Open Extensions Preferences") {
                    openExtensionPreferences()
                }
                .buttonStyle(.link)
            }
            
            Spacer()
            
            // Footer
            HStack {
                Link("GitHub", destination: URL(string: "https://github.com/nyldn/finder.md")!)
                Text("•")
                    .foregroundStyle(.secondary)
                Text("v1.0.0")
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
        }
        .padding(32)
        .frame(width: 450, height: 500)
        .onAppear(perform: checkStatus)
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            checkStatus()
        }
    }
    
    private func checkStatus() {
        isExtensionEnabled = FIFinderSyncController.isExtensionEnabled
        monitoredFoldersCount = SettingsManager.shared.monitoredFolderBookmarks.count
    }
    
    private func openSettings() {
        if #available(macOS 14.0, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }
    
    private func openExtensionPreferences() {
        // Deep link to System Settings → Extensions
        if let url = URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences") {
            NSWorkspace.shared.open(url)
        }
    }
}

#Preview {
    ContentView()
}
