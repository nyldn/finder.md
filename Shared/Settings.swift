import Foundation

/// Policy for handling filename conflicts when creating new files
enum ConflictPolicy: String, Codable, CaseIterable, Identifiable {
    case autoSuffix = "autoSuffix"
    case promptOverwrite = "promptOverwrite"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .autoSuffix:
            return "Auto-suffix (File 2.md)"
        case .promptOverwrite:
            return "Prompt to overwrite"
        }
    }
}

/// Action to perform after creating a new markdown file
enum AfterCreateAction: String, Codable, CaseIterable, Identifiable {
    case none = "none"
    case revealInFinder = "reveal"
    case openInEditor = "open"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .none:
            return "Do nothing"
        case .revealInFinder:
            return "Reveal in Finder"
        case .openInEditor:
            return "Open in editor"
        }
    }
}

/// Supported markdown editors
struct EditorOption: Identifiable, Codable, Hashable {
    let id: String  // bundle identifier
    let name: String
    
    /// Default list of commonly used editors
    static let defaults: [EditorOption] = [
        EditorOption(id: "com.apple.TextEdit", name: "TextEdit"),
        EditorOption(id: "md.obsidian", name: "Obsidian"),
        EditorOption(id: "com.barebones.bbedit", name: "BBEdit"),
        EditorOption(id: "com.microsoft.VSCode", name: "VS Code"),
        EditorOption(id: "com.sublimetext.4", name: "Sublime Text"),
        EditorOption(id: "com.typora.Typora", name: "Typora"),
        EditorOption(id: "abnerworks.Typora", name: "Typora (App Store)"),
        EditorOption(id: "com.apple.dt.Xcode", name: "Xcode"),
    ]
}
