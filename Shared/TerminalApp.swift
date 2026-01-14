import Foundation
import AppKit

/// Represents a terminal application that can be launched
struct TerminalApp: Identifiable, Codable, Hashable {
    let id: String  // bundle identifier
    let name: String
    let launchMethod: LaunchMethod
    
    enum LaunchMethod: String, Codable {
        case appleScript       // Terminal.app, iTerm2
        case cliWorkingDir     // Ghostty, Kitty (--working-directory flag)
        case cliDirectory      // Alacritty (--working-directory)
        case warpCli           // Warp has its own CLI
        case openWithPath      // Generic fallback
    }
    
    /// All known terminal applications
    static let allTerminals: [TerminalApp] = [
        TerminalApp(
            id: "com.apple.Terminal",
            name: "Terminal",
            launchMethod: .appleScript
        ),
        TerminalApp(
            id: "com.mitchellh.ghostty",
            name: "Ghostty",
            launchMethod: .cliWorkingDir
        ),
        TerminalApp(
            id: "com.googlecode.iterm2",
            name: "iTerm",
            launchMethod: .appleScript
        ),
        TerminalApp(
            id: "dev.warp.Warp-Stable",
            name: "Warp",
            launchMethod: .warpCli
        ),
        TerminalApp(
            id: "org.alacritty",
            name: "Alacritty",
            launchMethod: .cliDirectory
        ),
        TerminalApp(
            id: "net.kovidgoyal.kitty",
            name: "Kitty",
            launchMethod: .cliWorkingDir
        ),
        TerminalApp(
            id: "co.zeit.hyper",
            name: "Hyper",
            launchMethod: .openWithPath
        ),
        TerminalApp(
            id: "com.vscodium.codium",
            name: "VSCodium",
            launchMethod: .openWithPath
        ),
    ]
    
    /// Returns only the terminal apps that are currently installed
    static var installedTerminals: [TerminalApp] {
        allTerminals.filter { terminal in
            NSWorkspace.shared.urlForApplication(withBundleIdentifier: terminal.id) != nil
        }
    }
    
    /// Returns the default terminal (Terminal.app or first installed)
    static var defaultTerminal: TerminalApp {
        // Prefer Terminal.app as default
        if let terminal = installedTerminals.first(where: { $0.id == "com.apple.Terminal" }) {
            return terminal
        }
        // Fall back to first installed
        return installedTerminals.first ?? allTerminals[0]
    }
    
    /// Check if this terminal is installed
    var isInstalled: Bool {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: id) != nil
    }
    
    /// Get the application URL
    var applicationURL: URL? {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: id)
    }
    
    /// Get the executable path inside the app bundle
    var executablePath: String? {
        guard let appURL = applicationURL else { return nil }
        let executableName = appURL.deletingPathExtension().lastPathComponent
        let path = appURL.appendingPathComponent("Contents/MacOS/\(executableName)").path
        return FileManager.default.fileExists(atPath: path) ? path : nil
    }
}
