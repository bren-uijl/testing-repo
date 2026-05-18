# Nexus Browser - Agent Instructions for Future Self

## Project Overview

Nexus Browser is a next-generation web browser built on Electron/Chromium with full Chrome Web Store extension compatibility. The unified codebase is located at `/opencode/browser/`.

**Last Updated:** May 18, 2026

## Quick Start

```bash
cd opencode/browser
npm install
npm start
```

## Project Structure

```
opencode/browser/
├── package.json                    # Project configuration with electron-builder
├── electron-builder.yml            # Standalone electron-builder config
├── README.md                       # User-facing documentation
├── LICENSE                         # MIT License
├── .gitignore                      # Git ignore rules
├── assets/
│   └── icon.svg                    # Application icon (SVG source)
├── src/
│   ├── main.js                     # Electron main process entry point
│   ├── preload.js                  # Preload script for secure IPC bridge
│   ├── ui/
│   │   ├── browser.html            # Main browser window HTML structure
│   │   ├── browser.js              # Browser UI logic (NexusBrowser class)
│   │   ├── styles.css              # Complete UI styling (dark theme)
│   │   └── settings.html           # Standalone settings window
│   ├── extensions/
│   │   ├── extension-manager.js    # Chrome extension installation/management
│   │   ├── chrome-webstore-bridge.js # Chrome Web Store CRX download/extraction
│   │   └── permission-manager.js   # Extension permission risk analysis
│   └── features/
│       ├── privacy-shield.js       # Built-in tracker/ad blocker
│       ├── download-manager.js     # Download handling with pause/resume
│       ├── reading-mode.js         # Distraction-free reading view
│       └── password-manager.js     # Encrypted password vault
├── build/
│   └── installer.nsh               # NSIS custom installer script
├── scripts/
│   └── build-installer.js          # Automated offline installer build script
└── installers/
    ├── windows/                    # Windows installer scripts (legacy)
    └── linux/                      # Linux installer scripts (legacy)
```

## Architecture Decisions

### Why Electron/Chromium?
- Chrome Web Store extensions require Chromium's extension API
- Building Chromium from source takes 6+ hours compile time
- Electron provides Chromium + Node.js in one package
- Same approach used by Brave, Vivaldi, Arc

### Tab/Webview Model
The browser uses a **per-tab webview** approach:
- Each tab gets its own `<webview>` element
- More robust isolation between tabs
- Better memory management for inactive tabs
- Individual zoom levels per tab

### UI Architecture
- **Side panels** for features (privacy, downloads, extensions, passwords, settings, reading, history)
- **Dropdown menu** for quick access to common actions
- **Bookmarks panel** with localStorage persistence
- **History panel** with localStorage persistence (500 entry limit)
- **SVG icons** throughout for crisp rendering

### IPC Design
Unified `window.nexusAPI` with namespaced methods:
- `window.nexusAPI.windowControls` - minimize, maximize, close
- `window.nexusAPI.privacy` - stats, toggle, blocklists
- `window.nexusAPI.downloads` - get, pause, resume, cancel, open
- `window.nexusAPI.readingMode` - extractArticle, activate, deactivate
- `window.nexusAPI.passwords` - save, get, delete, export, import
- `window.nexusAPI.extensions` - install, load, get, toggle, uninstall
- `window.nexusAPI.settings` - get, save

## Key Features

### 1. Chrome Web Store Integration
- Download extensions directly from Chrome Web Store API
- Parse and install .crx files (CRX2 and CRX3 formats)
- Load unpacked extensions from filesystem
- Enable/disable/uninstall extensions
- Permission risk analysis (low/medium/high) before install
- Platform-native extraction (PowerShell on Windows, unzip on Linux)

### 2. Privacy Shield
- Blocks 45+ tracker domains by default
- Blocks 20+ ad networks by default
- Custom blocklist and whitelist support
- Header manipulation (modify cookies for privacy)
- Request blocking statistics with persistence
- Toggle protection on/off
- **WebRTC leak prevention** via command-line switches

### 3. Tab Management
- Multiple tab support with tab bar
- Per-tab webview elements for isolation
- Tab favicon, title, loading state
- Keyboard shortcuts (Ctrl+T, Ctrl+W, Ctrl+L)
- Quick links on home page (Google, YouTube, GitHub, Reddit, Wikipedia)

### 4. Reading Mode
- **In-page injection**: CSS + JS toolbar injected into webview
- Three themes: Light, Dark, Sepia
- Adjustable font size (14-28px)
- Reading progress bar
- Auto-detect article content
- **Server-side extraction**: jsdom-based article extraction for side panel

### 5. Password Manager
- AES-256-GCM encryption with PBKDF2 key derivation (100k iterations)
- Master password protection with unlock mechanism
- Per-password random key encryption
- Import/Export with encrypted CSV
- Per-site credential lookup

### 6. Download Manager
- Download tracking with progress
- Pause/resume support
- Open file/folder actions
- Download history with cleanup
- Settings persistence (ask where to save)
- Notification system for download events

### 7. Bookmarks
- Full bookmark system with localStorage
- Add/remove bookmarks via star button
- Bookmark panel with click-to-navigate
- Keyboard shortcut Ctrl+D

### 8. Browsing History
- Automatic history tracking on navigation
- History panel with click-to-navigate
- Individual entry removal
- Clear all history option
- 500 entry limit with FIFO eviction
- Keyboard accessible

### 9. Zoom Controls
- Zoom in/out/reset (Ctrl++, Ctrl+-, Ctrl+0)
- Zoom display in status bar
- Applied to all active webviews

## Build Commands

```bash
npm install              # Install dependencies
npm start                # Run in development
npm run dev              # Run with dev flags
npm run build            # Build for current platform
npm run build:win        # Build for Windows
npm run build:mac        # Build for macOS
npm run build:linux      # Build for Linux
npm run build:all        # Build for all platforms
npm run build:offline    # Build Windows offline installer (.exe)
npm run build-installer  # Run full automated installer build
npm run package          # Build without publishing
npm test                 # Run test suite
npm run lint             # Run ESLint
npm run lint:fix         # Fix ESLint issues
npm run format           # Format with Prettier
```

## Offline Windows Installer

### Building the Installer

```bash
# Quick build (requires Windows or Wine for cross-compilation)
npm run build:offline

# Full automated build with verification
npm run build-installer
```

### Installer Configuration

The offline installer is configured via `electron-builder.yml` and `package.json`:

- **Format**: NSIS (Nullsoft Scriptable Install System)
- **Architecture**: x64
- **Output**: `dist/Nexus Browser-Setup-<version>.exe`
- **Features**:
  - Fully offline - no internet required during installation
  - All dependencies bundled in asar archive
  - Custom installation directory selection
  - Desktop and Start Menu shortcuts
  - Per-machine installation (requires admin)
  - Built-in uninstaller
  - Registry entries for Windows Add/Remove Programs

### NSIS Customization

Custom installer behavior is defined in `build/installer.nsh`:
- `preInit` macro: Sets default install location to `$PROGRAMFILES\Nexus Browser`
- `customInstall` macro: Writes uninstall registry entries
- `customUnInstall` macro: Cleans up registry on uninstall

### Cross-Platform Building

To build the Windows installer on Linux/macOS:
```bash
# Install wine (required for Windows builds on non-Windows)
sudo apt install wine  # Ubuntu/Debian
brew install wine      # macOS

# Build
npm run build:win
```

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Ctrl+T | New tab |
| Ctrl+W | Close tab |
| Ctrl+L | Focus URL bar |
| Ctrl+R | Refresh |
| Ctrl++ | Zoom in |
| Ctrl+- | Zoom out |
| Ctrl+0 | Reset zoom |
| Ctrl+D | Bookmark page |

## Bugs Fixed

1. **Invalid Unicode escape** (`browser.js:610`): Fixed broken emoji surrogate pair `'\uD83E\uDD'` to `'\uD83E\uDDE9'` (puzzle piece)
2. **Duplicate IPC handlers** (`main.js`): Removed duplicate `privacy-stats`/`get-privacy-stats` and `privacy-toggle`/`toggle-privacy` handlers
3. **Duplicate request handlers** (`main.js` + `privacy-shield.js`): Removed redundant `onBeforeSendHeaders` from `applyPrivacyShield()` since `PrivacyShield` constructor already registers all handlers
4. **Invalid redirect option** (`chrome-webstore-bridge.js:46`): Removed unsupported `followRedirects` option from `https.get()` (Node.js http module doesn't support it; manual redirect handling already exists)
5. **WebRTC IP leaks**: Added `force-webrtc-ip-handling-policy` and `webrtc-ip-handling-policy` command-line switches to disable non-proxied UDP

## Known Limitations

1. **Chrome Web Store API**: Google may block automated CRX downloads. Fallback: users install from .crx file manually.
2. **Native Messaging**: Some extensions require native host binaries. Not yet implemented.
3. **DRM Content**: Widevine DRM not configured. Netflix/Spotify may not work.
4. **Service Workers**: Some sites may have issues with Electron's service worker support.
5. **WebAssembly**: Performance may differ from Chrome.
6. **Icon format**: SVG icons work for electron-builder but Windows .ico files provide better taskbar integration. Convert SVG to ICO for production releases.

## Testing Checklist

- [ ] Chrome Web Store extension installs correctly
- [ ] uBlock Origin works for ad blocking
- [ ] LastPass/Bitwarden extension works
- [ ] Privacy Shield blocks trackers
- [ ] Reading mode activates on articles
- [ ] Password manager saves/retrieves credentials
- [ ] Downloads complete successfully
- [ ] All keyboard shortcuts work
- [ ] Bookmarks persist across sessions
- [ ] Window state saves/restores
- [ ] Zoom controls work correctly
- [ ] Extension toggle enable/disable works
- [ ] History tracks visited pages
- [ ] History panel displays entries correctly
- [ ] Clear history removes all entries
- [ ] Offline installer builds successfully
- [ ] Installer runs on clean Windows machine

## Dependencies

```json
{
  "adm-zip": "^0.5.10",
  "electron-dl": "^3.5.1",
  "electron-store": "^8.1.0",
  "electron-updater": "^6.1.7",
  "jsdom": "^24.0.0"
}
```

## Release Checklist

1. Update version in package.json
2. Run full test suite (`npm test`)
3. Run linting (`npm run lint`)
4. Build offline installer (`npm run build:offline`)
5. Build for all platforms (`npm run build:all`)
6. Test installer on Windows 10/11 clean machine
7. Test on macOS 13+, Ubuntu 22.04+
8. Verify Chrome Web Store extension compatibility
9. Sign binaries (macOS: notarize, Windows: code sign)
10. Convert SVG icon to .ico/.icns for production
11. Create release notes
12. Publish to GitHub Releases

## Resources

- Chrome Extension Docs: https://developer.chrome.com/docs/extensions
- Electron Docs: https://www.electronjs.org/docs
- Electron Builder: https://www.electron.build/
- NSIS Docs: https://nsis.sourceforge.io/Docs/
- Chromium Source: https://chromium.googlesource.com
- Chrome Web Store: https://chrome.google.com/webstore

## Commit History Pattern

Each feature should be committed separately:
1. Initialize project structure
2. Add browser UI
3. Add extension support
4. Add unique features (privacy, reading mode, passwords, downloads)
5. Add settings/config
6. Add history feature
7. Add offline installer configuration
8. Add tests
9. Add documentation

---

*These instructions are for the next agent session. Follow the commit-after-each-edit rule. Prioritize Chrome Web Store compatibility above all else.*
