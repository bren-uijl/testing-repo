# Nexus Browser

A next-generation Chromium-based browser with full Chrome Web Store extension support, built on Electron.

## Features

- **Chrome Web Store Integration**: Install extensions directly from the Chrome Web Store
- **Privacy Shield**: Built-in tracker and ad blocker with customizable blocklists
- **Tab Management**: Multiple tabs with keyboard shortcuts and quick navigation
- **Reading Mode**: Distraction-free article viewing with customizable themes
- **Password Manager**: AES-256-GCM encrypted password vault with import/export
- **Download Manager**: Download tracking with pause/resume support
- **Custom Settings**: Comprehensive settings page for all browser features

## Getting Started

### Prerequisites

- Node.js 18 or higher
- npm 9 or higher

### Installation

```bash
cd nexus-browser
npm install
```

### Development

```bash
npm run dev
```

### Building

```bash
npm run build
```

Build for specific platforms:

```bash
npm run build:win
npm run build:linux
npm run build:all
```

## Project Structure

```
nexus-browser/
├── package.json
├── src/
│   ├── main.js                     # Electron main process
│   ├── preload.js                  # Secure preload script
│   ├── ui/
│   │   ├── browser.html            # Main browser window
│   │   ├── browser.js              # Browser UI logic
│   │   ├── styles.css              # UI styling (dark theme)
│   │   └── settings.html           # Settings page
│   ├── extensions/
│   │   ├── extension-manager.js    # Extension installation/management
│   │   ├── chrome-webstore-bridge.js # Chrome Web Store integration
│   │   └── permission-manager.js   # Permission analysis
│   └── features/
│       ├── privacy-shield.js       # Tracker/ad blocker
│       ├── download-manager.js     # Download handling
│       ├── reading-mode.js         # Article extraction
│       └── password-manager.js     # Encrypted password vault
└── installers/
    ├── windows/
    │   └── setup.bat               # Windows offline installer
    └── linux/
        └── setup.sh                # Linux offline installer
```

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Ctrl+T | New tab |
| Ctrl+W | Close tab |
| Ctrl+L | Focus URL bar |
| Ctrl+R | Refresh |

## Architecture

Nexus Browser is built on Electron, leveraging Chromium's rendering engine for web compatibility while providing native desktop integration.

### Extension Support

Extensions are installed via the Chrome Web Store API:
1. Download .crx files from Chrome Web Store
2. Extract CRX to local filesystem
3. Load via Electron's session.loadExtension()
4. Analyze permissions before installation

### Privacy Shield

The privacy shield operates at the network request level:
- Intercepts requests via webRequest API
- Blocks known tracker and ad domains
- Supports custom blocklists and whitelists
- Tracks blocking statistics

### Password Security

Passwords are encrypted using AES-256-GCM:
- Each password has a unique encryption key
- Export files are encrypted with master password
- Import supports both encrypted and CSV formats

## License

MIT
