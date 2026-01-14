import Foundation
import AppKit
import os.log

/// Handles launching terminal applications at specific directories
class TerminalLauncher {
    
    private let logger = Logger(subsystem: AppConstants.mainAppBundleID, category: "TerminalLauncher")
    
    /// Shared instance
    static let shared = TerminalLauncher()
    
    private init() {}
    
    /// Opens the specified terminal at the given directory
    /// - Parameters:
    ///   - terminal: The terminal app to launch
    ///   - directory: The directory to open in the terminal
    /// - Returns: true if launch was successful
    @discardableResult
    func openTerminal(_ terminal: TerminalApp, at directory: URL) -> Bool {
        logger.info("Opening \(terminal.name) at \(directory.path)")
        
        guard terminal.isInstalled else {
            logger.error("\(terminal.name) is not installed")
            return false
        }
        
        let escapedPath = escapePathForShell(directory.path)
        
        switch terminal.launchMethod {
        case .appleScript:
            return openWithAppleScript(terminal: terminal, path: escapedPath)
            
        case .cliWorkingDir:
            return openWithCLI(terminal: terminal, path: directory.path, flag: "--working-directory")
            
        case .cliDirectory:
            return openWithCLI(terminal: terminal, path: directory.path, flag: "--working-directory")
            
        case .warpCli:
            return openWarp(at: directory)
            
        case .openWithPath:
            return openGeneric(terminal: terminal, at: directory)
        }
    }
    
    // MARK: - AppleScript Method (Terminal.app, iTerm2)
    
    private func openWithAppleScript(terminal: TerminalApp, path: String) -> Bool {
        let script: String
        
        switch terminal.id {
        case "com.apple.Terminal":
            script = """
            tell application "Terminal"
                do script "cd \(path)"
                activate
            end tell
            """
            
        case "com.googlecode.iterm2":
            script = """
            tell application "iTerm"
                create window with default profile
                tell current session of current window
                    write text "cd \(path)"
                end tell
                activate
            end tell
            """
            
        default:
            // Generic AppleScript fallback
            script = """
            tell application "\(terminal.name)"
                activate
            end tell
            """
        }
        
        return executeAppleScript(script)
    }
    
    private func executeAppleScript(_ source: String) -> Bool {
        guard let script = NSAppleScript(source: source) else {
            logger.error("Failed to create AppleScript")
            return false
        }
        
        var errorInfo: NSDictionary?
        script.executeAndReturnError(&errorInfo)
        
        if let error = errorInfo {
            logger.error("AppleScript error: \(error)")
            return false
        }
        
        return true
    }
    
    // MARK: - CLI Method (Ghostty, Kitty, Alacritty)
    
    private func openWithCLI(terminal: TerminalApp, path: String, flag: String) -> Bool {
        guard let executablePath = terminal.executablePath else {
            logger.error("Could not find executable for \(terminal.name)")
            // Fall back to generic open
            return openGeneric(terminal: terminal, at: URL(fileURLWithPath: path))
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = ["\(flag)=\(path)"]
        
        // Detach from parent process
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        
        do {
            try process.run()
            logger.info("Launched \(terminal.name) via CLI")
            return true
        } catch {
            logger.error("Failed to launch \(terminal.name): \(error.localizedDescription)")
            // Fall back to generic open
            return openGeneric(terminal: terminal, at: URL(fileURLWithPath: path))
        }
    }
    
    // MARK: - Warp-specific
    
    private func openWarp(at directory: URL) -> Bool {
        // Warp supports opening with a path argument
        // Try CLI first, then fall back to AppleScript
        
        let warpPath = "/Applications/Warp.app/Contents/MacOS/stable"
        if FileManager.default.fileExists(atPath: warpPath) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: warpPath)
            process.currentDirectoryURL = directory
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice
            
            do {
                try process.run()
                return true
            } catch {
                logger.warning("Warp CLI failed, trying AppleScript")
            }
        }
        
        // AppleScript fallback for Warp
        let script = """
        tell application "Warp"
            activate
        end tell
        delay 0.5
        tell application "System Events"
            keystroke "cd \(escapePathForShell(directory.path))"
            key code 36
        end tell
        """
        
        return executeAppleScript(script)
    }
    
    // MARK: - Generic Fallback
    
    private func openGeneric(terminal: TerminalApp, at directory: URL) -> Bool {
        guard let appURL = terminal.applicationURL else {
            logger.error("Could not find \(terminal.name)")
            return false
        }
        
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        
        // For generic terminals, we just open the app and hope for the best
        // Some terminals will pick up the working directory from the launch context
        
        var didLaunch = false
        let semaphore = DispatchSemaphore(value: 0)
        
        NSWorkspace.shared.openApplication(at: appURL, configuration: config) { app, error in
            if let error = error {
                self.logger.error("Failed to open \(terminal.name): \(error.localizedDescription)")
            } else {
                didLaunch = true
            }
            semaphore.signal()
        }
        
        // Wait briefly for the app to launch
        _ = semaphore.wait(timeout: .now() + 2.0)
        
        if didLaunch {
            // Try to send cd command via System Events (accessibility)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.sendCdCommand(to: terminal, path: directory.path)
            }
        }
        
        return didLaunch
    }
    
    private func sendCdCommand(to terminal: TerminalApp, path: String) {
        let script = """
        tell application "\(terminal.name)" to activate
        delay 0.3
        tell application "System Events"
            keystroke "cd \(escapePathForShell(path))"
            key code 36
        end tell
        """
        _ = executeAppleScript(script)
    }
    
    // MARK: - Helpers
    
    /// Escapes a path for use in shell commands
    private func escapePathForShell(_ path: String) -> String {
        // Escape single quotes by ending the quote, adding escaped quote, starting new quote
        let escaped = path.replacingOccurrences(of: "'", with: "'\\''")
        return "'\(escaped)'"
    }
}
