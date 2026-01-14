import Foundation

/// Shared constants used by both the main app and the Finder Sync extension
enum AppConstants {
    /// App Group identifier for shared UserDefaults and container
    static let appGroupID = "group.com.nyldn.FinderMD"
    
    /// Bundle identifiers
    static let mainAppBundleID = "com.nyldn.FinderMD"
    static let extensionBundleID = "com.nyldn.FinderMD.FinderMDSync"
    
    /// Default values
    static let defaultFilename = "Untitled"
    static let fileExtension = "md"
    
    /// UserDefaults keys for shared preferences
    enum Keys {
        static let monitoredFolderBookmarks = "monitoredFolderBookmarks"
        static let defaultFilename = "defaultFilename"
        static let defaultTemplate = "defaultTemplate"
        static let conflictPolicy = "conflictPolicy"
        static let afterCreateAction = "afterCreateAction"
        static let preferredEditorBundleID = "preferredEditorBundleID"
    }
}
