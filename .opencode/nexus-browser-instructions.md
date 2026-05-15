# Prompt

Build Nexus Browser - a Chromium-based browser competitor with full Chrome Web Store extension support. Commit after each edit.

# Response

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
│   │   └── styles.css              # Complete UI styling (dark theme)
│   ├── extensions/
│   │   ├── extension-manager.js    # Chrome extension installation/management
│   │   ├── chrome-webstore-bridge.js # Chrome Web Store integration
│   │   └── permission-manager.js   # Extension permission analysis & prompts
│   └── features/
│       ├── privacy-shield.js       # Built-in tracker/ad blocker
│       ├── download-manager.js     # Download handling with progress
│       ├── reading-mode.js         # Distraction-free reading view
│       └── password-manager.js     # Encrypted password vault
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

### Priority 4 - Competitive Edge
15. **Built-in VPN**: Optional VPN integration
16. **Crypto Wallet**: Built-in Web3 wallet
17. **RSS Reader**: Built-in RSS feed reader
18. **Notes**: Quick notes sidebar
19. **Screenshot to Text**: OCR on screenshots

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

## Dependencies to Add

```json
{
  "adm-zip": "^0.5.10",
  "electron-updater": "^6.1.7",
  "electron-store": "^8.1.0"
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
