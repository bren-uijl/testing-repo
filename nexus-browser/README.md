# Nexus Browser

A next-generation Chromium-based browser with full Chrome Web Store extension support.

## Features

- **Chrome Web Store Support**: Install and run extensions directly from the Chrome Web Store
- **Privacy Shield**: Built-in tracker and ad blocker
- **Reading Mode**: Distraction-free article reading with multiple themes
- **Password Manager**: Encrypted password vault with AES-256-GCM
- **Download Manager**: Full download management with progress tracking
- **Tab Management**: Multi-tab browsing with quick links
- **Bookmarks**: Save and organize your favorite sites

## Quick Start

```bash
# Install dependencies
npm install

# Run in development mode
npm start

# Build for your platform
npm run build
```

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+T` | New tab |
| `Ctrl+W` | Close tab |
| `Ctrl+L` | Focus URL bar |
| `Ctrl+R` | Refresh |
| `Ctrl++` | Zoom in |
| `Ctrl+-` | Zoom out |
| `Ctrl+0` | Reset zoom |
| `Ctrl+D` | Bookmark page |

## Installing Extensions

### From Chrome Web Store
1. Click the Extensions button (🧩) in the toolbar
2. Click "Browse Chrome Web Store"
3. Download the .crx file
4. Click "Install Extension from File" and select the folder

### From Local Folder
1. Click the Extensions button (🧩)
2. Click "Install Extension from File"
3. Select the unpacked extension folder

## Architecture

```
src/
├── main.js                     # Electron main process
├── preload.js                  # Secure IPC bridge
├── ui/                         # Browser interface
├── extensions/                 # Chrome extension support
└── features/                   # Built-in browser features
```

## Building

```bash
# Windows
npm run build:win

# macOS
npm run build:mac

# Linux
npm run build:linux

# All platforms
npm run build:all
```

## License

MPL-2.0
