# Nexus Browser - Agent Instructions for Future Self

## Project Overview

Nexus Browser is a next-generation web browser built on Electron/Chromium with full Chrome Web Store extension compatibility. The goal is to compete with Chrome, Firefox, Edge, and Brave while offering unique features.

## Project Structure

```
nexus-browser/
├── package.json                    # Project config, dependencies, build scripts
├── src/
│   ├── main.js                     # Electron main process entry point
│   ├── preload.js                  # Preload script for secure IPC
│   ├── ui/
│   │   ├── browser.html            # Main browser window HTML
│   │   ├── browser.js              # Browser UI logic (tabs, navigation, panels)
│   │   ├── styles.css              # Complete UI styling (dark theme)
│   │   └── settings.html           # Settings page
│   ├── extensions/
│   │   ├── extension-manager.js    # Chrome extension installation/management
│   │   ├── chrome-webstore-bridge.js # Chrome Web Store integration
│   │   └── permission-manager.js   # Extension permission analysis & prompts
│   └── features/
│       ├── privacy-shield.js       # Built-in tracker/ad blocker
│       ├── download-manager.js     # Download handling with progress
│       ├── reading-mode.js         # Distraction-free reading view
│       └── password-manager.js     # Encrypted password vault
└── installers/
    ├── windows/
    │   ├── setup.bat               # Basic Windows installer
    │   └── setup-full.bat          # Full Windows installer with shortcuts
    └── linux/
        ├── setup.sh                # Basic Linux installer
        └── setup-full.sh           # Full Linux installer with desktop integration
```

## Architecture Decisions

### Why Electron/Chromium?
- Chrome Web Store extensions require Chromium's extension API
- Building Chromium from source takes 6+ hours compile time
- Electron provides Chromium + Node.js in one package
- Same approach used by Brave, Vivaldi, Arc

### Extension Support Strategy
1. **Direct CRX Installation**: Download .crx files from Chrome Web Store API
2. **Local Extension Loading**: Load unpacked extensions from filesystem
3. **Session API**: Use Electron's session.loadExtension() for runtime loading
4. **Permission Analysis**: Analyze manifest permissions before install

## Key Features Implemented

### 1. Chrome Web Store Integration
- Download extensions directly from Chrome Web Store
- Parse and install .crx files
- Enable/disable/uninstall extensions
- Permission risk analysis (low/medium/high)
- Direct link to Chrome Web Store in UI

### 2. Privacy Shield
- Blocks 30+ tracker domains by default
- Blocks 20+ ad networks by default
- Custom blocklist support
- Site whitelist support
- Request blocking statistics
- Header manipulation (remove tracking headers)

### 3. Tab Management
- Multiple tab support with tab bar
- Tab favicon, title, loading state
- Keyboard shortcuts (Ctrl+T, Ctrl+W, Ctrl+L)
- Quick links on home page

### 4. Reading Mode
- Distraction-free article view
- Three themes: Light, Dark, Sepia
- Adjustable font size
- Reading progress bar
- Auto-detect article content

### 5. Password Manager
- AES-256-GCM encrypted vault
- Master password protection
- Auto-save credentials
- Import/Export CSV
- Per-site credential lookup

### 6. Download Manager
- Download tracking with progress
- Pause/resume support
- Open file/folder actions
- Download history

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Ctrl+T | New tab |
| Ctrl+W | Close tab |
| Ctrl+L | Focus URL bar |
| Ctrl+R | Refresh |

## Development Workflow

### Running Locally
```bash
cd nexus-browser
npm install
npm start
```

### Building for Distribution
```bash
npm run build:win    # Windows NSIS installer
npm run build:linux  # Linux AppImage + deb
npm run build:all    # Both platforms
```

### Using Offline Installers
```bash
# Windows
cd nexus-browser/installers/windows
setup-full.bat

# Linux
cd nexus-browser/installers/linux
sudo ./setup-full.sh
```

## IPC Channels

### Window Controls
- `window-minimize` - Minimize window
- `window-maximize` - Toggle maximize
- `window-close` - Close window

### Privacy
- `get-privacy-stats` - Get blocking statistics
- `toggle-privacy` - Enable/disable shield
- `get-blocked-domains` - Get blocklist
- `add-blocked-domain` - Add domain to blocklist
- `remove-blocked-domain` - Remove domain from blocklist

### Downloads
- `get-downloads` - List all downloads
- `pause-download` - Pause a download
- `resume-download` - Resume a download
- `cancel-download` - Cancel a download
- `open-download` - Open downloaded file
- `clear-downloads` - Clear download history

### Reading Mode
- `extract-article` - Extract article content from HTML

### Passwords
- `save-password` - Save a password
- `get-passwords` - List saved passwords
- `delete-password` - Delete a password
- `export-passwords` - Export to encrypted file
- `import-passwords` - Import from file

### Extensions
- `install-extension` - Install from Chrome Web Store
- `load-unpacked-extension` - Load from local folder
- `get-extensions` - List installed extensions
- `toggle-extension` - Enable/disable extension
- `uninstall-extension` - Remove extension
- `analyze-permissions` - Analyze extension permissions

### Settings
- `get-settings` - Get all settings
- `save-settings` - Save settings

## Security Considerations

1. **Context Isolation**: Enabled in webPreferences
2. **Node Integration**: Disabled, use preload script
3. **Password Encryption**: AES-256-GCM with unique keys
4. **Extension Permissions**: Analyzed before installation
5. **CSP**: Content Security Policy enforced in HTML

## Known Limitations

1. CRX extraction requires system unzip or adm-zip
2. Extension loading uses Electron's experimental API
3. Reading mode requires jsdom for server-side parsing
4. Password manager stores encrypted data locally

## Future Improvements

- [ ] Add sync support for passwords/bookmarks
- [ ] Implement full extension API compatibility
- [ ] Add ad-block filter list updates
- [ ] Implement tab groups
- [ ] Add vertical tabs option
- [ ] Implement split view
- [ ] Add built-in translation
- [ ] Implement screenshot tool
- [ ] Add video picture-in-picture
- [ ] Implement web archive support

## Testing Checklist

- [ ] Extension installation from Chrome Web Store
- [ ] Privacy shield blocking statistics
- [ ] Password save/retrieve/delete
- [ ] Download pause/resume
- [ ] Reading mode extraction
- [ ] Settings persistence
- [ ] Keyboard shortcuts
- [ ] Multi-tab navigation
- [ ] Windows installer
- [ ] Linux installer
