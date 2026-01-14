# finder.md

A macOS Finder Sync extension that adds **"New Markdown File..."** to Finder's right-click context menu. Create `.md` files instantly in any folder, including Google Drive and other File Provider locations.

![macOS](https://img.shields.io/badge/macOS-14.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- **Context Menu Integration** - Right-click anywhere in Finder to create markdown files
- **Works Everywhere** - Including Google Drive, iCloud, and other cloud storage folders
- **Smart Templates** - Choose between Empty or Basic Note (with title + date)
- **Conflict Handling** - Auto-suffix duplicates (File.md → File 2.md → File 3.md)
- **Editor Integration** - Open new files in your preferred markdown editor
- **After-Create Actions** - Reveal in Finder or open directly in editor
- **Open in Terminal** - Launch your preferred terminal at any folder location
- **Multi-Terminal Support** - Terminal.app, Ghostty, iTerm2, Warp, Alacritty, Kitty

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 15.0+ (for building from source)

## Installation

### From Source

1. **Clone the repository:**
   ```bash
   git clone https://github.com/nyldn/finder.md.git
   cd finder.md
   ```

2. **Open in Xcode:**
   ```bash
   open FinderMD.xcodeproj
   ```

3. **Configure signing:**
   - Select the `FinderMD` target
   - Go to **Signing & Capabilities**
   - Select your Development Team
   - Repeat for the `FinderMDSync` target

4. **Build and run** (⌘R)

5. **Enable the extension:**
   - Open **System Settings** → **Privacy & Security** → **Extensions** → **Finder Extensions**
   - Enable **FinderMD**

6. **Add monitored folders** in the FinderMD app

## Usage

### Basic Usage

1. Open any folder you've added to monitored folders
2. Right-click on the folder background (or any file/folder)
3. Select **"New Markdown File..."**
4. Enter a filename and choose a template
5. Click **Create**

### Quick Template Access

For faster workflow, use **"New Markdown from Template"** submenu to skip the dialog and create files with your default filename.

### Open in Terminal

Right-click any folder (or folder background) and select **"Open in Terminal"** to launch a terminal window at that location.

**Supported terminals:**
- **Terminal.app** (macOS default)
- **Ghostty**
- **iTerm2**
- **Warp**
- **Alacritty**
- **Kitty**

Configure your preferred terminal in FinderMD Settings → Preferences.

## Configuration

Launch the FinderMD app to configure settings:

### Monitored Folders

The context menu **only appears** in folders you explicitly add. This is a macOS Finder Sync requirement.

**Recommended folders to add:**
- `~/Desktop`
- `~/Documents`
- `~/Downloads`
- Google Drive: `~/Library/CloudStorage/GoogleDrive-yourname@gmail.com`

### Preferences

| Setting | Description |
|---------|-------------|
| **Default Filename** | Starting name for new files (default: "Untitled") |
| **Default Template** | Empty or Basic Note (title + date header) |
| **Conflict Handling** | Auto-suffix or prompt to overwrite |
| **After Create** | Do nothing, reveal in Finder, or open in editor |
| **Preferred Editor** | TextEdit, Obsidian, VS Code, BBEdit, etc. |
| **Preferred Terminal** | Terminal.app, Ghostty, iTerm2, Warp, Alacritty, Kitty |
| **Terminal Submenu** | Show all terminals in submenu or just preferred terminal |

## Project Structure

```
finder.md/
├── FinderMD/                    # Main host application
│   ├── FinderMDApp.swift        # App entry point
│   ├── ContentView.swift        # Main window
│   ├── Views/                   # Settings UI
│   │   ├── SettingsView.swift
│   │   ├── MonitoredFoldersView.swift
│   │   ├── PreferencesView.swift
│   │   └── AboutView.swift
│   ├── FinderMD.entitlements
│   └── Info.plist
├── FinderMDSync/                # Finder Sync extension
│   ├── FinderSync.swift         # Extension principal class
│   ├── FilenamePrompt.swift     # Filename dialog
│   ├── MarkdownFileCreator.swift
│   ├── FinderMDSync.entitlements
│   └── Info.plist
├── Shared/                      # Shared code (both targets)
│   ├── Constants.swift          # App group ID, keys
│   ├── Settings.swift           # Enums and types
│   ├── MarkdownTemplate.swift   # Template definitions
│   ├── SettingsManager.swift    # UserDefaults manager
│   ├── TerminalApp.swift        # Terminal app definitions
│   └── TerminalLauncher.swift   # Terminal launch logic
└── FinderMD.xcodeproj
```

## Troubleshooting

### Context menu doesn't appear

1. **Check extension is enabled:**
   - System Settings → Privacy & Security → Extensions → Finder Extensions
   - Ensure FinderMD is toggled ON

2. **Verify folder is monitored:**
   - Open FinderMD app → Folders tab
   - Ensure the folder (or a parent) is in the list

3. **Restart Finder:**
   ```bash
   killall Finder
   ```

### Extension shows "Not Enabled"

1. Open System Settings → Privacy & Security → Extensions → Finder Extensions
2. Toggle FinderMD OFF then ON
3. If still not working, try removing and re-installing the app

### Google Drive folders not working

Google Drive paths are under `~/Library/CloudStorage/`. Add the specific Google Drive folder:
1. In FinderMD, click "Add Folder..."
2. Press ⌘⇧G and paste: `~/Library/CloudStorage/`
3. Select your Google Drive folder

### Debug Information

Use **Settings → About → Copy Debug Info** to gather diagnostic information for bug reports.

## Building for Release

For distribution outside of development:

1. **Archive the project:**
   ```bash
   xcodebuild archive \
     -scheme FinderMD \
     -archivePath ./build/FinderMD.xcarchive
   ```

2. **Export for distribution:**
   ```bash
   xcodebuild -exportArchive \
     -archivePath ./build/FinderMD.xcarchive \
     -exportPath ./build/export \
     -exportOptionsPlist ExportOptions.plist
   ```

3. **Notarization** (required for distribution):
   ```bash
   xcrun notarytool submit ./build/export/FinderMD.app \
     --apple-id "your@email.com" \
     --team-id "TEAMID" \
     --password "@keychain:AC_PASSWORD"
   ```

## Roadmap

Future enhancements under consideration:

- [ ] **Custom terminal profiles** - Launch with specific terminal profiles/themes
- [ ] **Keyboard shortcuts** - Trigger actions via hotkeys
- [ ] **More templates** - Additional markdown templates (meeting notes, etc.)

## Contributing

Issues and pull requests welcome at [github.com/nyldn/finder.md](https://github.com/nyldn/finder.md)

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

- Built with Apple's [Finder Sync Extension](https://developer.apple.com/documentation/findersync) framework
- Inspired by the need to create markdown files in Google Drive folders where Quick Actions don't appear
