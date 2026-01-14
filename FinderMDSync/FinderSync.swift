import Cocoa
import FinderSync
import os.log

/// Main Finder Sync extension class
/// Provides context menu for creating markdown files in monitored directories
class FinderSync: FIFinderSync {
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: AppConstants.extensionBundleID, category: "FinderSync")
    private let settingsManager = SettingsManager.shared
    private let fileCreator = MarkdownFileCreator()
    private let terminalLauncher = TerminalLauncher.shared
    
    /// URLs currently being accessed with security scope
    private var accessedURLs: Set<URL> = []
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        logger.info("FinderSync extension initialized")
        
        updateMonitoredDirectories()
        
        // Observe UserDefaults changes for live updates when settings change
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDefaultsDidChange),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
    }
    
    deinit {
        // Stop accessing all security-scoped resources
        for url in accessedURLs {
            url.stopAccessingSecurityScopedResource()
        }
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Directory Monitoring
    
    @objc private func userDefaultsDidChange() {
        updateMonitoredDirectories()
    }
    
    private func updateMonitoredDirectories() {
        // Stop accessing previous URLs
        for url in accessedURLs {
            url.stopAccessingSecurityScopedResource()
        }
        accessedURLs.removeAll()
        
        // Resolve bookmarks and start accessing
        let urls = settingsManager.resolveMonitoredFolders()
        
        for url in urls {
            if url.startAccessingSecurityScopedResource() {
                accessedURLs.insert(url)
            } else {
                logger.warning("Failed to start accessing: \(url.path)")
            }
        }
        
        // Update Finder Sync controller
        FIFinderSyncController.default().directoryURLs = Set(urls)
        logger.info("Monitoring \(urls.count) directories")
    }
    
    // MARK: - FIFinderSync Protocol
    
    override func beginObservingDirectory(at url: URL) {
        logger.debug("Begin observing: \(url.path)")
    }
    
    override func endObservingDirectory(at url: URL) {
        logger.debug("End observing: \(url.path)")
    }
    
    // MARK: - Context Menu
    
    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        let menu = NSMenu(title: "")
        
        switch menuKind {
        case .contextualMenuForContainer, .contextualMenuForItems:
            // Main menu item with dialog
            let createItem = NSMenuItem(
                title: "New Markdown File...",
                action: #selector(createMarkdownFileWithPrompt(_:)),
                keyEquivalent: ""
            )
            createItem.image = NSImage(systemSymbolName: "doc.text", accessibilityDescription: "Markdown file")
            createItem.target = self
            menu.addItem(createItem)
            
            // Submenu for quick template access
            let templateMenu = NSMenu(title: "Templates")
            for (index, template) in MarkdownTemplate.allCases.enumerated() {
                let item = NSMenuItem(
                    title: template.displayName,
                    action: #selector(createMarkdownFileWithTemplate(_:)),
                    keyEquivalent: ""
                )
                item.tag = index
                item.target = self
                templateMenu.addItem(item)
            }
            
            let templateItem = NSMenuItem(title: "New Markdown from Template", action: nil, keyEquivalent: "")
            templateItem.submenu = templateMenu
            menu.addItem(templateItem)
            
            // Separator before terminal items
            menu.addItem(NSMenuItem.separator())
            
            // Terminal menu items
            addTerminalMenuItems(to: menu)
            
        case .contextualMenuForSidebar:
            // Simplified menu for sidebar
            let createItem = NSMenuItem(
                title: "New Markdown File...",
                action: #selector(createMarkdownFileWithPrompt(_:)),
                keyEquivalent: ""
            )
            createItem.target = self
            menu.addItem(createItem)
            
            // Add terminal option for sidebar too
            menu.addItem(NSMenuItem.separator())
            
            let terminalItem = NSMenuItem(
                title: "Open in Terminal",
                action: #selector(openInPreferredTerminal(_:)),
                keyEquivalent: ""
            )
            terminalItem.image = NSImage(systemSymbolName: "terminal", accessibilityDescription: "Terminal")
            terminalItem.target = self
            menu.addItem(terminalItem)
            
        default:
            return nil
        }
        
        return menu
    }
    
    // MARK: - Target Folder Resolution
    
    /// Determines the target folder based on the current Finder context
    /// - Returns: URL of the folder where the new file should be created, or nil if undetermined
    private func resolveTargetFolder() -> URL? {
        let controller = FIFinderSyncController.default()
        
        // Get the targeted URL (what user right-clicked on)
        guard let targetedURL = controller.targetedURL() else {
            logger.warning("No targeted URL available")
            return nil
        }
        
        // Get selected items if any
        let selectedItems = controller.selectedItemURLs() ?? []
        
        // If no selection, we're right-clicking the container background
        if selectedItems.isEmpty {
            return targetedURL
        }
        
        // Check first selected item
        if let firstSelected = selectedItems.first {
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: firstSelected.path, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    // Selected a folder - create inside it
                    return firstSelected
                } else {
                    // Selected a file - use its parent
                    return firstSelected.deletingLastPathComponent()
                }
            }
        }
        
        return targetedURL
    }
    
    // MARK: - Menu Actions
    
    @objc func createMarkdownFileWithPrompt(_ sender: NSMenuItem) {
        guard let targetFolder = resolveTargetFolder() else {
            showError("Could not determine target folder")
            return
        }
        
        let defaultName = settingsManager.defaultFilename
        let defaultTemplate = settingsManager.defaultTemplate
        
        FilenamePromptController.promptForFilename(
            defaultName: defaultName,
            defaultTemplate: defaultTemplate
        ) { [weak self] result in
            guard let self = self, let result = result else { return }
            
            self.performFileCreation(
                in: targetFolder,
                filename: result.filename,
                template: result.template
            )
        }
    }
    
    @objc func createMarkdownFileWithTemplate(_ sender: NSMenuItem) {
        guard let targetFolder = resolveTargetFolder() else {
            showError("Could not determine target folder")
            return
        }
        
        let templateIndex = sender.tag
        guard templateIndex >= 0 && templateIndex < MarkdownTemplate.allCases.count else {
            showError("Invalid template selection")
            return
        }
        
        let template = MarkdownTemplate.allCases[templateIndex]
        let filename = settingsManager.defaultFilename
        
        performFileCreation(in: targetFolder, filename: filename, template: template)
    }
    
    // MARK: - File Creation
    
    private func performFileCreation(in folder: URL, filename: String, template: MarkdownTemplate) {
        do {
            let createdURL = try fileCreator.createFile(
                in: folder,
                filename: filename,
                template: template,
                conflictPolicy: settingsManager.conflictPolicy
            )
            
            logger.info("Created file: \(createdURL.path)")
            
            // Perform after-create action
            performAfterCreateAction(for: createdURL)
            
        } catch let error as FileCreationError {
            showError(error.localizedDescription)
        } catch {
            showError("Failed to create file: \(error.localizedDescription)")
        }
    }
    
    private func performAfterCreateAction(for url: URL) {
        switch settingsManager.afterCreateAction {
        case .none:
            break
            
        case .revealInFinder:
            NSWorkspace.shared.activateFileViewerSelecting([url])
            
        case .openInEditor:
            let editorBundleID = settingsManager.preferredEditorBundleID
            
            if let editorURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: editorBundleID) {
                let config = NSWorkspace.OpenConfiguration()
                NSWorkspace.shared.open([url], withApplicationAt: editorURL, configuration: config) { [weak self] _, error in
                    if let error = error {
                        self?.logger.error("Failed to open editor '\(editorBundleID)': \(error.localizedDescription)")
                        // Fallback to default app
                        NSWorkspace.shared.open(url)
                    }
                }
            } else {
                // Editor not found, use default app
                logger.warning("Editor '\(editorBundleID)' not found, using default")
                NSWorkspace.shared.open(url)
            }
        }
    }
    
    // MARK: - Terminal Menu
    
    private func addTerminalMenuItems(to menu: NSMenu) {
        let installedTerminals = TerminalApp.installedTerminals
        
        guard !installedTerminals.isEmpty else {
            logger.warning("No terminal apps found")
            return
        }
        
        // Main "Open in Terminal" item (uses preferred terminal)
        let preferredTerminal = settingsManager.preferredTerminal
        let terminalItem = NSMenuItem(
            title: "Open in \(preferredTerminal.name)",
            action: #selector(openInPreferredTerminal(_:)),
            keyEquivalent: ""
        )
        terminalItem.image = NSImage(systemSymbolName: "terminal", accessibilityDescription: "Terminal")
        terminalItem.target = self
        menu.addItem(terminalItem)
        
        // Submenu with all installed terminals (if enabled and more than one terminal)
        if settingsManager.showTerminalSubmenu && installedTerminals.count > 1 {
            let terminalSubmenu = NSMenu(title: "Terminals")
            
            for (index, terminal) in installedTerminals.enumerated() {
                let item = NSMenuItem(
                    title: terminal.name,
                    action: #selector(openInSpecificTerminal(_:)),
                    keyEquivalent: ""
                )
                item.tag = index
                item.target = self
                
                // Add checkmark for preferred terminal
                if terminal.id == preferredTerminal.id {
                    item.state = .on
                }
                
                terminalSubmenu.addItem(item)
            }
            
            let submenuItem = NSMenuItem(title: "Open in Terminal", action: nil, keyEquivalent: "")
            submenuItem.submenu = terminalSubmenu
            menu.addItem(submenuItem)
        }
    }
    
    // MARK: - Terminal Actions
    
    @objc func openInPreferredTerminal(_ sender: NSMenuItem) {
        guard let targetFolder = resolveTargetFolder() else {
            showError("Could not determine target folder")
            return
        }
        
        let terminal = settingsManager.preferredTerminal
        if !terminalLauncher.openTerminal(terminal, at: targetFolder) {
            showError("Failed to open \(terminal.name)")
        }
    }
    
    @objc func openInSpecificTerminal(_ sender: NSMenuItem) {
        guard let targetFolder = resolveTargetFolder() else {
            showError("Could not determine target folder")
            return
        }
        
        let installedTerminals = TerminalApp.installedTerminals
        let index = sender.tag
        
        guard index >= 0 && index < installedTerminals.count else {
            showError("Invalid terminal selection")
            return
        }
        
        let terminal = installedTerminals[index]
        if !terminalLauncher.openTerminal(terminal, at: targetFolder) {
            showError("Failed to open \(terminal.name)")
        }
    }
    
    // MARK: - Error Handling
    
    private func showError(_ message: String) {
        logger.error("Error: \(message)")
        
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "FinderMD Error"
            alert.informativeText = message
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
}
