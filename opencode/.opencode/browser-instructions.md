# Nexus Browser - Agent Instructions for Future Self

## Project Overview

Nexus Browser is a next-generation web browser built on Electron/Chromium with full Chrome Web Store extension compatibility. This merged version combines the best features from two previous implementations into a single, unified codebase located at `/opencode/browser/`.

## Quick Start

```bash
cd opencode/browser
npm install
npm start
```

## Project Structure

```
opencode/browser/
├── package.json                    # Project configuration
├── README.md                       # User-facing documentation
├── .gitignore                      # Git ignore rules
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
└── installers/
    ├── windows/                    # Windows installer scripts
    └── linux/                      # Linux installer scripts
```

## Architecture Decisions

### Why Electron/Chromium?
- Chrome Web Store extensions require Chromium's extension API
- Building Chromium from source takes 6+ hours compile time
- Electron provides Chromium + Node.js in one package
- Same approach used by Brave, Vivaldi, Arc

### Tab/Webview Model
The merged browser uses a **per-tab webview** approach:
- Each tab gets its own `<webview>` element
- More robust isolation between tabs
- Better memory management for inactive tabs
- Individual zoom levels per tab

### UI Architecture
- **Side panels** for features (privacy, downloads, extensions, passwords, settings, reading)
- **Dropdown menu** for quick access to common actions
- **Bookmarks panel** with localStorage persistence
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
- Header manipulation (remove tracking headers, modify cookies)
- Request blocking statistics with persistence
- Toggle protection on/off

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

### 8. Zoom Controls
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
npm run package          # Build without publishing
npm test                 # Run test suite
npm run lint             # Run ESLint
npm run lint:fix         # Fix ESLint issues
npm run format           # Format with Prettier
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

## Merge Strategy

This merged browser combines two previous implementations:

### From Root `nexus-browser/`:
- Window state persistence (saves/restores position and size)
- Per-tab webview architecture
- Bookmark system with localStorage
- Zoom controls with display
- `nexus://home` protocol handling
- Security icon in URL bar
- Loading animation indicator
- In-page reading mode injection
- Master password vault with PBKDF2
- Download notification system
- Command-line switches for extensions
- `shell.openExternal` for popup windows
- Test/lint/format scripts

### From `opencode/nexus-browser/`:
- SVG icons throughout UI
- Side panel architecture for all features
- Window controls (minimize/maximize/close) wired to IPC
- Namespaced `nexusAPI` with ~30 methods
- Per-password random key encryption
- Download pause/resume support
- jsdom-based article extraction
- Settings persistence per feature module
- Platform-native CRX extraction
- 4 installer scripts (Windows/Linux basic/full)
- Comprehensive permission analysis (~40 permissions)

## Known Limitations

1. **Chrome Web Store API**: Google may block automated CRX downloads. Fallback: users install from .crx file manually.
2. **Native Messaging**: Some extensions require native host binaries. Not yet implemented.
3. **DRM Content**: Widevine DRM not configured. Netflix/Spotify may not work.
4. **Service Workers**: Some sites may have issues with Electron's service worker support.
5. **WebAssembly**: Performance may differ from Chrome.

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
4. Build for all platforms (`npm run build:all`)
5. Test on Windows 10/11, macOS 13+, Ubuntu 22.04+
6. Verify Chrome Web Store extension compatibility
7. Sign binaries (macOS: notarize, Windows: code sign)
8. Create release notes
9. Publish to GitHub Releases

## Resources

- Chrome Extension Docs: https://developer.chrome.com/docs/extensions
- Electron Docs: https://www.electronjs.org/docs
- Chromium Source: https://chromium.googlesource.com
- Chrome Web Store: https://chrome.google.com/webstore

---

*These instructions are for the next agent session. Follow the commit-after-each-edit rule. Prioritize Chrome Web Store compatibility above all else.*
