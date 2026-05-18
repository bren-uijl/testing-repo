# Nexus Browser - Agent Instructions for Future Self

## Project Overview

Nexus Browser is a next-generation web browser built on Electron/Chromium with full Chrome Web Store extension compatibility. The merged codebase is located at `/opencode/browser/`.

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

### Extension Support Strategy
1. **Direct CRX Installation**: Download .crx files from Chrome Web Store API
2. **Local Extension Loading**: Load unpacked extensions from filesystem
3. **Session API**: Use Electron's session.loadExtension() for runtime loading
4. **Permission Analysis**: Analyze manifest permissions before install

## Key Features Implemented

### 1. Chrome Web Store Integration
- Download extensions directly from Chrome Web Store
- Parse and install .crx files (CRX2 and CRX3)
- Enable/disable/uninstall extensions
- Permission risk analysis (low/medium/high)
- Direct link to Chrome Web Store in UI

### 2. Privacy Shield
- Blocks 45+ tracker domains by default
- Blocks 20+ ad networks by default
- Custom blocklist support
- Site whitelist support
- Request blocking statistics
- Header manipulation (remove tracking headers)

### 3. Tab Management
- Multiple tab support with tab bar
- Per-tab webview elements
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
- Master password protection (PBKDF2, 100k iterations)
- Per-password random key encryption
- Import/Export CSV

### 6. Download Manager
- Download tracking with progress
- Pause/resume support
- Open file/folder actions
- Download history

### 7. Bookmarks
- Full bookmark system with localStorage
- Star button to bookmark pages
- Bookmark panel with navigation

### 8. Zoom Controls
- Zoom in/out/reset
- Zoom display in status bar
- Applied to all webviews

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

## Build Commands

```bash
npm install              # Install dependencies
npm start                # Run in development
npm run build            # Build for current platform
npm run build:win        # Build for Windows
npm run build:mac        # Build for macOS
npm run build:linux      # Build for Linux
npm run build:all        # Build for all platforms
npm test                 # Run test suite
npm run lint             # Run ESLint
npm run format           # Format with Prettier
```

## Next Steps for Future Self

### Priority 1 - Must Have
1. **Sync Engine**: Implement cross-device sync for bookmarks, passwords, history
2. **WebRTC Leak Prevention**: Fix WebRTC IP leaks for privacy
3. **Fingerprinting Protection**: Block canvas/audio fingerprinting
4. **Update System**: Implement auto-updates with electron-updater

### Priority 2 - Should Have
5. **Vertical Tabs**: Optional vertical tab bar like Edge/Sidekick
6. **Workspaces**: Group tabs by project/context
7. **Screenshot Tool**: Built-in full-page and region screenshot
8. **Translate**: Built-in page translation
9. **PDF Viewer**: Enhanced PDF viewer with annotations

### Priority 3 - Nice to Have
10. **AI Assistant**: Integrated AI for summarization, translation
11. **Split View**: Side-by-side tab viewing
12. **Tab Groups**: Color-coded tab groups
13. **Memory Saver**: Suspend inactive tabs to save RAM
14. **Video Picture-in-Picture**: Enhanced PiP mode

## Known Limitations

1. **Chrome Web Store API**: Google may block automated CRX downloads.
2. **Native Messaging**: Some extensions require native host binaries.
3. **DRM Content**: Widevine DRM not configured.
4. **Service Workers**: Some sites may have issues with Electron's service worker support.

## Testing Checklist

- [ ] Chrome Web Store extension installs correctly
- [ ] uBlock Origin works for ad blocking
- [ ] Privacy Shield blocks trackers
- [ ] Reading mode activates on articles
- [ ] Password manager saves/retrieves credentials
- [ ] Downloads complete successfully
- [ ] All keyboard shortcuts work
- [ ] Bookmarks persist across sessions
- [ ] Window state saves/restores

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
2. Run full test suite
3. Build for all platforms
4. Test on Windows 10/11, macOS 13+, Ubuntu 22.04+
5. Verify Chrome Web Store extension compatibility
6. Sign binaries (macOS: notarize, Windows: code sign)
7. Create release notes
8. Publish to GitHub Releases

## Resources

- Chrome Extension Docs: https://developer.chrome.com/docs/extensions
- Electron Docs: https://www.electronjs.org/docs
- Chromium Source: https://chromium.googlesource.com
- Chrome Web Store: https://chrome.google.com/webstore

## Commit History Pattern

Each feature should be committed separately:
1. Initialize project structure
2. Add browser UI
3. Add extension support
4. Add unique features
5. Add settings/config
6. Add tests
7. Add documentation

---

*These instructions are for the next agent session. Follow the commit-after-each-edit rule. Prioritize Chrome Web Store compatibility above all else.*
