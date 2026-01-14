import SwiftUI
import FinderSync

struct AboutView: View {
    @State private var copiedDebugInfo = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // App icon
            Image(systemName: "doc.text.fill")
                .font(.system(size: 56))
                .foregroundStyle(.blue.gradient)
            
            // App name and version
            VStack(spacing: 4) {
                Text("FinderMD")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Version 1.0.0")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Divider()
                .frame(width: 180)
            
            // Description
            Text("A Finder Sync extension for creating Markdown files directly from Finder's context menu.")
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
                .foregroundStyle(.secondary)
            
            // Links
            VStack(spacing: 8) {
                Link(destination: URL(string: "https://github.com/nyldn/finder.md")!) {
                    HStack {
                        Image(systemName: "link")
                        Text("View on GitHub")
                    }
                }
                
                Link(destination: URL(string: "https://github.com/nyldn/finder.md/issues")!) {
                    HStack {
                        Image(systemName: "exclamationmark.bubble")
                        Text("Report an Issue")
                    }
                }
            }
            .font(.callout)
            
            Spacer()
            
            // Debug info
            Divider()
                .frame(width: 180)
            
            Button {
                copyDebugInfo()
            } label: {
                HStack {
                    Image(systemName: copiedDebugInfo ? "checkmark" : "doc.on.clipboard")
                    Text(copiedDebugInfo ? "Copied!" : "Copy Debug Info")
                }
            }
            .buttonStyle(.link)
            .font(.caption)
            
            Text("Include debug info when reporting issues")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
    }
    
    private func copyDebugInfo() {
        let settings = SettingsManager.shared
        let isEnabled = FIFinderSyncController.isExtensionEnabled
        
        let info = """
        FinderMD Debug Info
        ===================
        Version: 1.0.0
        macOS: \(ProcessInfo.processInfo.operatingSystemVersionString)
        Extension Enabled: \(isEnabled)
        Monitored Folders: \(settings.monitoredFolderBookmarks.count)
        Default Filename: \(settings.defaultFilename)
        Default Template: \(settings.defaultTemplate.rawValue)
        Conflict Policy: \(settings.conflictPolicy.rawValue)
        After Create: \(settings.afterCreateAction.rawValue)
        Preferred Editor: \(settings.preferredEditorBundleID)
        App Group: \(AppConstants.appGroupID)
        """
        
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(info, forType: .string)
        
        withAnimation {
            copiedDebugInfo = true
        }
        
        // Reset after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                copiedDebugInfo = false
            }
        }
    }
}

#Preview {
    AboutView()
}
