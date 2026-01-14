import SwiftUI

struct PreferencesView: View {
    @StateObject private var viewModel = PreferencesViewModel()
    
    var body: some View {
        Form {
            // Default Filename Section
            Section {
                TextField("Filename", text: $viewModel.defaultFilename)
                    .textFieldStyle(.roundedBorder)
            } header: {
                Text("Default Filename")
            } footer: {
                Text("The .md extension will be added automatically if omitted.")
            }
            
            // Default Template Section
            Section("Default Template") {
                Picker("Template", selection: $viewModel.defaultTemplate) {
                    ForEach(MarkdownTemplate.allCases) { template in
                        VStack(alignment: .leading) {
                            Text(template.displayName)
                        }
                        .tag(template)
                    }
                }
                .pickerStyle(.radioGroup)
            }
            
            // Conflict Policy Section
            Section {
                Picker("When file already exists", selection: $viewModel.conflictPolicy) {
                    ForEach(ConflictPolicy.allCases) { policy in
                        Text(policy.displayName).tag(policy)
                    }
                }
            } header: {
                Text("Conflict Handling")
            }
            
            // After Create Action Section
            Section("After Creating File") {
                Picker("Action", selection: $viewModel.afterCreateAction) {
                    ForEach(AfterCreateAction.allCases) { action in
                        Text(action.displayName).tag(action)
                    }
                }
            }
            
            // Preferred Editor Section
            Section {
                Picker("Editor", selection: $viewModel.preferredEditorBundleID) {
                    ForEach(viewModel.availableEditors, id: \.id) { editor in
                        Text(editor.name).tag(editor.id)
                    }
                    
                    if viewModel.availableEditors.isEmpty {
                        Text("TextEdit").tag("com.apple.TextEdit")
                    }
                }
            } header: {
                Text("Preferred Editor")
            } footer: {
                Text("Used when 'Open in editor' is selected above. Only installed apps are shown.")
            }
            
            // Terminal Section
            Section {
                Picker("Terminal", selection: $viewModel.preferredTerminalBundleID) {
                    ForEach(viewModel.availableTerminals, id: \.id) { terminal in
                        Text(terminal.name).tag(terminal.id)
                    }
                }
                
                Toggle("Show terminal submenu", isOn: $viewModel.showTerminalSubmenu)
            } header: {
                Text("Terminal")
            } footer: {
                Text("Choose the terminal to open when using 'Open in Terminal'. The submenu shows all installed terminals.")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

@MainActor
class PreferencesViewModel: ObservableObject {
    private let settingsManager = SettingsManager.shared
    
    @Published var defaultFilename: String {
        didSet { settingsManager.defaultFilename = defaultFilename }
    }
    
    @Published var defaultTemplate: MarkdownTemplate {
        didSet { settingsManager.defaultTemplate = defaultTemplate }
    }
    
    @Published var conflictPolicy: ConflictPolicy {
        didSet { settingsManager.conflictPolicy = conflictPolicy }
    }
    
    @Published var afterCreateAction: AfterCreateAction {
        didSet { settingsManager.afterCreateAction = afterCreateAction }
    }
    
    @Published var preferredEditorBundleID: String {
        didSet { settingsManager.preferredEditorBundleID = preferredEditorBundleID }
    }
    
    @Published var preferredTerminalBundleID: String {
        didSet { settingsManager.preferredTerminalBundleID = preferredTerminalBundleID }
    }
    
    @Published var showTerminalSubmenu: Bool {
        didSet { settingsManager.showTerminalSubmenu = showTerminalSubmenu }
    }
    
    var availableEditors: [EditorOption] {
        // Filter to only installed editors
        EditorOption.defaults.filter { editor in
            NSWorkspace.shared.urlForApplication(withBundleIdentifier: editor.id) != nil
        }
    }
    
    var availableTerminals: [TerminalApp] {
        TerminalApp.installedTerminals
    }
    
    init() {
        defaultFilename = settingsManager.defaultFilename
        defaultTemplate = settingsManager.defaultTemplate
        conflictPolicy = settingsManager.conflictPolicy
        afterCreateAction = settingsManager.afterCreateAction
        preferredEditorBundleID = settingsManager.preferredEditorBundleID
        preferredTerminalBundleID = settingsManager.preferredTerminalBundleID
        showTerminalSubmenu = settingsManager.showTerminalSubmenu
    }
}

#Preview {
    PreferencesView()
}
