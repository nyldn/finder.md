import Foundation
import os.log

/// Manages shared settings between the main app and the Finder Sync extension
/// Uses App Group UserDefaults for cross-process communication
final class SettingsManager {
    /// Shared singleton instance
    static let shared = SettingsManager()
    
    /// UserDefaults instance backed by App Group container
    private let defaults: UserDefaults
    
    /// Logger for debugging
    private let logger = Logger(subsystem: AppConstants.mainAppBundleID, category: "Settings")
    
    private init() {
        guard let defaults = UserDefaults(suiteName: AppConstants.appGroupID) else {
            fatalError("Failed to create shared UserDefaults with suite: \(AppConstants.appGroupID)")
        }
        self.defaults = defaults
        logger.info("SettingsManager initialized with App Group: \(AppConstants.appGroupID)")
    }
    
    // MARK: - Monitored Folders (Security-Scoped Bookmarks)
    
    /// Raw bookmark data for monitored folders
    var monitoredFolderBookmarks: [Data] {
        get {
            defaults.array(forKey: AppConstants.Keys.monitoredFolderBookmarks) as? [Data] ?? []
        }
        set {
            defaults.set(newValue, forKey: AppConstants.Keys.monitoredFolderBookmarks)
            defaults.synchronize()
        }
    }
    
    /// Resolves all stored bookmarks to URLs
    /// - Returns: Array of resolved URLs (invalid bookmarks are filtered out)
    func resolveMonitoredFolders() -> [URL] {
        var urls: [URL] = []
        var validBookmarks: [Data] = []
        var needsUpdate = false
        
        for bookmark in monitoredFolderBookmarks {
            var isStale = false
            do {
                let url = try URL(
                    resolvingBookmarkData: bookmark,
                    options: [.withSecurityScope],
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )
                
                if isStale {
                    logger.warning("Bookmark is stale, attempting to refresh: \(url.path)")
                    // Try to refresh the bookmark
                    if let newBookmark = try? url.bookmarkData(
                        options: [.withSecurityScope],
                        includingResourceValuesForKeys: nil,
                        relativeTo: nil
                    ) {
                        validBookmarks.append(newBookmark)
                        needsUpdate = true
                    } else {
                        logger.error("Failed to refresh stale bookmark for: \(url.path)")
                        needsUpdate = true
                    }
                } else {
                    validBookmarks.append(bookmark)
                }
                urls.append(url)
            } catch {
                logger.error("Failed to resolve bookmark: \(error.localizedDescription)")
                needsUpdate = true
            }
        }
        
        // Update stored bookmarks if any were stale or invalid
        if needsUpdate {
            monitoredFolderBookmarks = validBookmarks
        }
        
        return urls
    }
    
    /// Adds a folder to the monitored list
    /// - Parameter url: URL of the folder to add (typically from NSOpenPanel)
    /// - Returns: true if successful, false otherwise
    @discardableResult
    func addMonitoredFolder(_ url: URL) -> Bool {
        do {
            let bookmark = try url.bookmarkData(
                options: [.withSecurityScope],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            var bookmarks = monitoredFolderBookmarks
            
            // Check if already exists
            let existingURLs = resolveMonitoredFolders()
            if existingURLs.contains(where: { $0.path == url.path }) {
                logger.info("Folder already monitored: \(url.path)")
                return true
            }
            
            bookmarks.append(bookmark)
            monitoredFolderBookmarks = bookmarks
            logger.info("Added monitored folder: \(url.path)")
            return true
        } catch {
            logger.error("Failed to create bookmark for \(url.path): \(error.localizedDescription)")
            return false
        }
    }
    
    /// Removes a monitored folder at the specified index
    /// - Parameter index: Index of the folder to remove
    func removeMonitoredFolder(at index: Int) {
        var bookmarks = monitoredFolderBookmarks
        guard index >= 0 && index < bookmarks.count else {
            logger.warning("Invalid index for removal: \(index)")
            return
        }
        bookmarks.remove(at: index)
        monitoredFolderBookmarks = bookmarks
        logger.info("Removed monitored folder at index: \(index)")
    }
    
    /// Removes all monitored folders
    func removeAllMonitoredFolders() {
        monitoredFolderBookmarks = []
        logger.info("Removed all monitored folders")
    }
    
    // MARK: - Preferences
    
    /// Default filename for new markdown files
    var defaultFilename: String {
        get {
            defaults.string(forKey: AppConstants.Keys.defaultFilename) ?? AppConstants.defaultFilename
        }
        set {
            defaults.set(newValue, forKey: AppConstants.Keys.defaultFilename)
            defaults.synchronize()
        }
    }
    
    /// Default template for new markdown files
    var defaultTemplate: MarkdownTemplate {
        get {
            guard let raw = defaults.string(forKey: AppConstants.Keys.defaultTemplate),
                  let template = MarkdownTemplate(rawValue: raw) else {
                return .empty
            }
            return template
        }
        set {
            defaults.set(newValue.rawValue, forKey: AppConstants.Keys.defaultTemplate)
            defaults.synchronize()
        }
    }
    
    /// Policy for handling filename conflicts
    var conflictPolicy: ConflictPolicy {
        get {
            guard let raw = defaults.string(forKey: AppConstants.Keys.conflictPolicy),
                  let policy = ConflictPolicy(rawValue: raw) else {
                return .autoSuffix
            }
            return policy
        }
        set {
            defaults.set(newValue.rawValue, forKey: AppConstants.Keys.conflictPolicy)
            defaults.synchronize()
        }
    }
    
    /// Action to perform after creating a file
    var afterCreateAction: AfterCreateAction {
        get {
            guard let raw = defaults.string(forKey: AppConstants.Keys.afterCreateAction),
                  let action = AfterCreateAction(rawValue: raw) else {
                return .none
            }
            return action
        }
        set {
            defaults.set(newValue.rawValue, forKey: AppConstants.Keys.afterCreateAction)
            defaults.synchronize()
        }
    }
    
    /// Bundle identifier of the preferred markdown editor
    var preferredEditorBundleID: String {
        get {
            defaults.string(forKey: AppConstants.Keys.preferredEditorBundleID) ?? "com.apple.TextEdit"
        }
        set {
            defaults.set(newValue, forKey: AppConstants.Keys.preferredEditorBundleID)
            defaults.synchronize()
        }
    }
    
    // MARK: - Terminal Preferences
    
    /// Bundle identifier of the preferred terminal app
    var preferredTerminalBundleID: String {
        get {
            defaults.string(forKey: AppConstants.Keys.preferredTerminalBundleID) ?? "com.apple.Terminal"
        }
        set {
            defaults.set(newValue, forKey: AppConstants.Keys.preferredTerminalBundleID)
            defaults.synchronize()
        }
    }
    
    /// Whether to show the terminal submenu with all installed terminals
    var showTerminalSubmenu: Bool {
        get {
            // Default to true if not set
            if defaults.object(forKey: AppConstants.Keys.showTerminalSubmenu) == nil {
                return true
            }
            return defaults.bool(forKey: AppConstants.Keys.showTerminalSubmenu)
        }
        set {
            defaults.set(newValue, forKey: AppConstants.Keys.showTerminalSubmenu)
            defaults.synchronize()
        }
    }
    
    /// Returns the preferred terminal app, falling back to Terminal.app
    var preferredTerminal: TerminalApp {
        let bundleID = preferredTerminalBundleID
        if let terminal = TerminalApp.allTerminals.first(where: { $0.id == bundleID }), terminal.isInstalled {
            return terminal
        }
        return TerminalApp.defaultTerminal
    }
}
