# Nexus Browser - Agent Instructions for Future Self

## Project Overview

Nexus Browser is a next-generation web browser built on Electron/Chromium with full Chrome Web Store extension compatibility. The merged codebase is located at `/opencode/browser/`.

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
├── package.json                    # Project configuration
├── electron-builder.yml            # Electron-builder configuration
├── README.md                       # User-facing documentation
├── LICENSE                         # MIT License
├── .gitignore                      # Git ignore rules
├── assets/
│   └── icon.svg                    # Application icon
├── src/
│   ├── main.js                     # Electron main process
│   ├── preload.js                  # Preload script for secure IPC
│   ├── ui/
│   │   ├── browser.html            # Main browser window
│   │   ├── browser.js              # Browser UI logic
│   │   ├── styles.css              # UI styling
│   │   └── settings.html           # Settings window
│   ├── extensions/
│   │   ├── extension-manager.js    # Extension management
│   │   ├── chrome-webstore-bridge.js # CRX download/extraction
│   │   └── permission-manager.js   # Permission analysis
│   └── features/
│       ├── privacy-shield.js       # Tracker/ad blocker
│       ├── download-manager.js     # Download handling
│       ├── reading-mode.js         # Reading view
│       └── password-manager.js     # Password vault
├── build/
│   └── installer.nsh               # NSIS installer script
├── scripts/
│   └── build-installer.js          # Build automation
└── installers/
    ├── windows/                    # Legacy Windows scripts
    └── linux/                      # Legacy Linux scripts
```

## Build Commands

```bash
npm install              # Install dependencies
npm start                # Run in development
npm run build:win        # Build for Windows
npm run build:offline    # Build Windows offline installer (.exe)
npm run build-installer  # Full automated build
npm run build:all        # Build for all platforms
npm test                 # Run test suite
npm run lint             # Run ESLint
npm run format           # Format with Prettier
```

## Key Features

1. **Chrome Web Store Support** - Install extensions directly
2. **Privacy Shield** - Built-in tracker/ad blocker (45+ trackers, 20+ ad networks)
3. **Password Manager** - AES-256-GCM encrypted vault
4. **Reading Mode** - Distraction-free reading with themes
5. **Download Manager** - Pause/resume support
6. **Tab Management** - Multi-tab with per-tab webviews
7. **Bookmarks** - localStorage persistence
8. **Browsing History** - Auto-tracking with 500 entry limit
9. **Zoom Controls** - Zoom in/out/reset with display
10. **WebRTC Protection** - IP leak prevention

## Offline Installer

Build a fully offline Windows installer:

```bash
npm run build:offline
```

Output: `dist/Nexus Browser-Setup-<version>.exe`

The installer bundles all dependencies and requires no internet access during installation.

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

1. Invalid Unicode escape in extension icon
2. Duplicate IPC handlers removed
3. Duplicate request handlers consolidated
4. Invalid HTTP redirect option removed
5. WebRTC IP leak prevention added

## Known Limitations

1. Chrome Web Store API may block automated downloads
2. Native messaging not implemented
3. Widevine DRM not configured
4. SVG icon should be converted to .ico for production

## Next Steps

### Priority 1
1. Sync engine for cross-device bookmarks/passwords
2. Widevine DRM for streaming content
3. Canvas/audio fingerprinting protection
4. Auto-update system with electron-updater

### Priority 2
5. Vertical tabs option
6. Tab workspaces/groups
7. Built-in screenshot tool
8. Page translation

### Priority 3
9. AI assistant integration
10. Split view tabs
11. Memory saver for inactive tabs
12. Enhanced PiP mode

## Resources

- Chrome Extension Docs: https://developer.chrome.com/docs/extensions
- Electron Docs: https://www.electronjs.org/docs
- Electron Builder: https://www.electron.build/

---

*These instructions are for the next agent session. Follow the commit-after-each-edit rule.*
