import SwiftUI

struct MonitoredFoldersView: View {
    @StateObject private var viewModel = MonitoredFoldersViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Monitored Folders")
                    .font(.headline)
                
                Text("The context menu only appears in these folders and their subfolders.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Folder list
            List {
                if viewModel.folders.isEmpty {
                    ContentUnavailableView {
                        Label("No Folders", systemImage: "folder.badge.questionmark")
                    } description: {
                        Text("Add folders to enable the Finder context menu.")
                    }
                } else {
                    ForEach(Array(viewModel.folders.enumerated()), id: \.offset) { index, folder in
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundStyle(.blue)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(folder.lastPathComponent)
                                    .font(.body)
                                    .lineLimit(1)
                                Text(folder.path)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                            
                            Spacer()
                            
                            Button(role: .destructive) {
                                viewModel.removeFolder(at: index)
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
            .frame(minHeight: 200)
            
            // Action buttons
            HStack {
                Button {
                    viewModel.addFolder()
                } label: {
                    Label("Add Folder...", systemImage: "plus")
                }
                
                Spacer()
                
                Menu {
                    ForEach(viewModel.commonFolders, id: \.name) { folder in
                        if let url = folder.url {
                            Button(folder.name) {
                                viewModel.addCommonFolder(url)
                            }
                        }
                    }
                } label: {
                    Text("Add Common Folder")
                }
            }
            
            // Google Drive hint
            if !viewModel.hasGoogleDrive {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.blue)
                    Text("Google Drive folders are typically under ~/Library/CloudStorage/")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding()
        .onAppear {
            viewModel.loadFolders()
        }
    }
}

@MainActor
class MonitoredFoldersViewModel: ObservableObject {
    @Published var folders: [URL] = []
    
    private let settingsManager = SettingsManager.shared
    private let fileManager = FileManager.default
    
    struct CommonFolder {
        let name: String
        let url: URL?
    }
    
    var commonFolders: [CommonFolder] {
        var folders: [CommonFolder] = [
            CommonFolder(name: "Desktop", url: fileManager.urls(for: .desktopDirectory, in: .userDomainMask).first),
            CommonFolder(name: "Documents", url: fileManager.urls(for: .documentDirectory, in: .userDomainMask).first),
            CommonFolder(name: "Downloads", url: fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first),
        ]
        
        // Add Google Drive if it exists
        let cloudStoragePath = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/CloudStorage")
        
        if let contents = try? fileManager.contentsOfDirectory(at: cloudStoragePath, includingPropertiesForKeys: nil) {
            for url in contents where url.lastPathComponent.hasPrefix("GoogleDrive") {
                folders.append(CommonFolder(name: url.lastPathComponent, url: url))
            }
        }
        
        return folders.filter { $0.url != nil }
    }
    
    var hasGoogleDrive: Bool {
        folders.contains { $0.path.contains("GoogleDrive") }
    }
    
    func loadFolders() {
        folders = settingsManager.resolveMonitoredFolders()
    }
    
    func addFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.message = "Select a folder to monitor for Markdown file creation"
        panel.prompt = "Add Folder"
        
        if panel.runModal() == .OK, let url = panel.url {
            if settingsManager.addMonitoredFolder(url) {
                loadFolders()
            }
        }
    }
    
    func addCommonFolder(_ url: URL) {
        if settingsManager.addMonitoredFolder(url) {
            loadFolders()
        }
    }
    
    func removeFolder(at index: Int) {
        settingsManager.removeMonitoredFolder(at: index)
        loadFolders()
    }
}

#Preview {
    MonitoredFoldersView()
}
