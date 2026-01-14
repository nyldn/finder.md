import Cocoa

/// Controller for presenting filename prompt dialogs
class FilenamePromptController {
    
    /// Result from the filename prompt dialog
    struct Result {
        let filename: String
        let template: MarkdownTemplate
    }
    
    /// Presents a dialog to prompt the user for a filename and template selection
    /// - Parameters:
    ///   - defaultName: Default filename to show in the text field
    ///   - defaultTemplate: Default template selection
    ///   - completion: Callback with the result (nil if cancelled)
    static func promptForFilename(
        defaultName: String,
        defaultTemplate: MarkdownTemplate,
        completion: @escaping (Result?) -> Void
    ) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "New Markdown File"
            alert.informativeText = "Enter a name for the new file:"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Create")
            alert.addButton(withTitle: "Cancel")
            
            // Create accessory view with text field and template picker
            let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 320, height: 70))
            
            // Filename text field
            let textField = NSTextField(frame: NSRect(x: 0, y: 40, width: 320, height: 24))
            textField.stringValue = defaultName
            textField.placeholderString = "Untitled.md"
            textField.bezelStyle = .roundedBezel
            containerView.addSubview(textField)
            
            // Template label
            let templateLabel = NSTextField(labelWithString: "Template:")
            templateLabel.frame = NSRect(x: 0, y: 8, width: 65, height: 20)
            templateLabel.alignment = .right
            containerView.addSubview(templateLabel)
            
            // Template picker
            let templatePopup = NSPopUpButton(frame: NSRect(x: 70, y: 5, width: 250, height: 26))
            templatePopup.bezelStyle = .rounded
            for template in MarkdownTemplate.allCases {
                templatePopup.addItem(withTitle: template.displayName)
                templatePopup.lastItem?.toolTip = template.description
            }
            if let defaultIndex = MarkdownTemplate.allCases.firstIndex(of: defaultTemplate) {
                templatePopup.selectItem(at: defaultIndex)
            }
            containerView.addSubview(templatePopup)
            
            alert.accessoryView = containerView
            alert.window.initialFirstResponder = textField
            
            // Select all text for easy replacement
            textField.selectText(nil)
            
            let response = alert.runModal()
            
            if response == .alertFirstButtonReturn {
                let filename = textField.stringValue.trimmingCharacters(in: .whitespaces)
                
                guard !filename.isEmpty else {
                    // Show error and re-prompt
                    let errorAlert = NSAlert()
                    errorAlert.messageText = "Invalid Filename"
                    errorAlert.informativeText = "Please enter a valid filename."
                    errorAlert.alertStyle = .warning
                    errorAlert.addButton(withTitle: "OK")
                    errorAlert.runModal()
                    
                    // Re-show the prompt
                    promptForFilename(defaultName: defaultName, defaultTemplate: defaultTemplate, completion: completion)
                    return
                }
                
                let templateIndex = templatePopup.indexOfSelectedItem
                let template = MarkdownTemplate.allCases[templateIndex]
                
                completion(Result(filename: filename, template: template))
            } else {
                completion(nil)
            }
        }
    }
}
