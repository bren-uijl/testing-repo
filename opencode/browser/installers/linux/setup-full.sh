#!/bin/bash
# Nexus Browser - Linux Full Offline Installer
# Creates a self-contained installation with bundled runtime
# Usage: sudo ./setup-full.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
APP_NAME="Nexus Browser"
APP_VERSION="1.0.0"
INSTALL_DIR="/opt/nexus-browser"
BIN_LINK="/usr/local/bin/nexus-browser"
DESKTOP_FILE="/usr/share/applications/nexus-browser.desktop"
ICON_DIR="/opt/nexus-browser/assets"

# Print banner
echo ""
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}   $APP_NAME - Full Installer v$APP_VERSION${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}[!]${NC} This installer requires root privileges."
    echo "    Please run: sudo $0"
    exit 1
fi

# Detect architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64)  NODE_ARCH="x64";;
    aarch64) NODE_ARCH="arm64";;
    armv7l)  NODE_ARCH="armv7l";;
    *)       echo -e "${RED}[ERROR]${NC} Unsupported architecture: $ARCH"; exit 1;;
esac

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_NAME=$NAME
    OS_VERSION=$VERSION_ID
else
    OS_NAME="Unknown"
fi

echo "System detected:"
echo "  OS: $OS_NAME $OS_VERSION"
echo "  Architecture: $ARCH"
echo ""

# Step 1: Create directories
echo -e "${BLUE}[1/6]${NC} Preparing installation directory..."
mkdir -p "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR/src/ui"
mkdir -p "$INSTALL_DIR/src/extensions"
mkdir -p "$INSTALL_DIR/src/features"
mkdir -p "$ICON_DIR"
mkdir -p "$INSTALL_DIR/runtime"
echo -e "  ${GREEN}[OK]${NC} Directories created"
echo ""

# Step 2: Copy application files
echo -e "${BLUE}[2/6]${NC} Installing application files..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [ -d "$SOURCE_DIR/src" ]; then
    cp -r "$SOURCE_DIR/src"/* "$INSTALL_DIR/src/"
    cp "$SOURCE_DIR/package.json" "$INSTALL_DIR/"
    cp "$SOURCE_DIR/README.md" "$INSTALL_DIR/" 2>/dev/null || true
    echo -e "  ${GREEN}[OK]${NC} Application files copied"
else
    echo -e "  ${YELLOW}[!]${NC} Source directory not found: $SOURCE_DIR"
fi
echo ""

# Step 3: Install or bundle Node.js runtime
echo -e "${BLUE}[3/6]${NC} Setting up Node.js runtime..."

if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo -e "  ${GREEN}[OK]${NC} System Node.js found: $NODE_VERSION"
    echo "      Using system Node.js for execution"
    USE_SYSTEM_NODE=true
else
    echo -e "  ${YELLOW}[!]${NC} Node.js not found, bundling runtime..."

    NODE_VERSION="v20.11.0"
    NODE_TARBALL="node-${NODE_VERSION}-linux-${ARCH}.tar.xz"
    NODE_URL="https://nodejs.org/dist/${NODE_VERSION}/${NODE_TARBALL}"

    if [ -f "$SCRIPT_DIR/runtime/${NODE_TARBALL}" ]; then
        echo "      Using bundled Node.js archive"
        cp "$SCRIPT_DIR/runtime/${NODE_TARBALL}" /tmp/
    else
        echo "      Downloading Node.js ${NODE_VERSION}..."
        curl -fsSL "$NODE_URL" -o "/tmp/${NODE_TARBALL}" 2>/dev/null || {
            echo -e "  ${RED}[ERROR]${NC} Failed to download Node.js"
            echo "            Please install Node.js manually or provide offline archive"
            exit 1
        }
    fi

    echo "      Extracting Node.js..."
    tar -xJf "/tmp/${NODE_TARBALL}" -C /tmp/
    cp -r "/tmp/node-${NODE_VERSION}-linux-${ARCH}/bin/"* "$INSTALL_DIR/runtime/"
    cp -r "/tmp/node-${VERSION}-linux-${ARCH}/lib/"* "$INSTALL_DIR/runtime/lib/" 2>/dev/null || true

    rm -rf "/tmp/node-${NODE_VERSION}-linux-${ARCH}" "/tmp/${NODE_TARBALL}"

    echo -e "  ${GREEN}[OK]${NC} Node.js bundled: ${NODE_VERSION}"
    USE_SYSTEM_NODE=false
fi
echo ""

# Step 4: Install npm dependencies
echo -e "${BLUE}[4/6]${NC} Installing dependencies..."

cd "$INSTALL_DIR"

if [ "$USE_SYSTEM_NODE" = true ]; then
    NODE_CMD="node"
    NPM_CMD="npm"
else
    NODE_CMD="$INSTALL_DIR/runtime/node"
    NPM_CMD="$INSTALL_DIR/runtime/npm"
fi

if [ -d "$SOURCE_DIR/node_modules" ]; then
    cp -r "$SOURCE_DIR/node_modules" "$INSTALL_DIR/"
    echo -e "  ${GREEN}[OK]${NC} Using bundled dependencies"
else
    echo "      Running npm install..."
    $NPM_CMD install --production 2>/dev/null || {
        echo -e "  ${YELLOW}[!]${NC} npm install failed"
        echo "            Run 'npm install' manually in $INSTALL_DIR"
    }
fi
echo ""

# Step 5: Create launchers and desktop integration
echo -e "${BLUE}[5/6]${NC} Creating launchers..."

# Create launcher script
cat > "$INSTALL_DIR/nexus-browser" << LAUNCHER
#!/bin/bash
# Nexus Browser Launcher v$APP_VERSION

NEXUS_HOME="$INSTALL_DIR"

if [ "$USE_SYSTEM_NODE" = true ]; then
    NODE_CMD="node"
else
    NODE_CMD="\$NEXUS_HOME/runtime/node"
fi

if [ ! -x "\$NODE_CMD" ] && ! command -v node &> /dev/null; then
    echo "[ERROR] Node.js is required to run Nexus Browser."
    echo "        Install from https://nodejs.org or use the full installer."
    exit 1
fi

exec "\$NODE_CMD" --no-warnings "\$NEXUS_HOME/src/main.js" "\$@"
LAUNCHER

chmod +x "$INSTALL_DIR/nexus-browser"

# Create system symlink
if [ -L "$BIN_LINK" ] || [ -f "$BIN_LINK" ]; then
    rm -f "$BIN_LINK"
fi
ln -s "$INSTALL_DIR/nexus-browser" "$BIN_LINK"

# Create icon (simple SVG placeholder)
cat > "$ICON_DIR/icon.svg" << 'ICON'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">
  <defs>
    <linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#e94560"/>
      <stop offset="100%" style="stop-color:#4ecca3"/>
    </linearGradient>
  </defs>
  <circle cx="64" cy="64" r="60" fill="url(#grad)"/>
  <text x="64" y="80" font-family="Arial" font-size="48" font-weight="bold" fill="white" text-anchor="middle">N</text>
</svg>
ICON

# Create desktop entry
cat > "$DESKTOP_FILE" << DESKTOP
[Desktop Entry]
Name=Nexus Browser
Comment=A next-generation browser with Chrome Web Store extension support
Exec=$BIN_LINK %U
Icon=$ICON_DIR/icon.svg
Terminal=false
Type=Application
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;x-scheme-handler/http;x-scheme-handler/https;
Keywords=browser;web;internet;privacy;extensions;
StartupWMClass=nexus-browser
DESKTOP

chmod 644 "$DESKTOP_FILE"

# Update desktop database
update-desktop-database /usr/share/applications 2>/dev/null || true
gtk-update-icon-cache /usr/share/icons/hicolor 2>/dev/null || true

echo -e "  ${GREEN}[OK]${NC} Launchers and desktop integration created"
echo ""

# Step 6: Create uninstaller
echo -e "${BLUE}[6/6]${NC} Creating uninstaller..."

cat > "/usr/local/bin/uninstall-nexus-browser" << 'UNINSTALLER'
#!/bin/bash
# Nexus Browser Uninstaller

echo ""
echo "========================================"
echo "   Nexus Browser Uninstaller"
echo "========================================"
echo ""

read -p "Are you sure you want to uninstall Nexus Browser? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Uninstallation cancelled."
    exit 0
fi

echo ""
echo "Removing desktop entry..."
rm -f /usr/share/applications/nexus-browser.desktop

echo "Removing launcher symlink..."
rm -f /usr/local/bin/nexus-browser

echo "Removing application files..."
rm -rf /opt/nexus-browser

echo ""
echo "========================================"
echo "   Uninstallation Complete"
echo "========================================"
echo ""
echo "Note: User data preserved in ~/.config/nexus-browser"
echo "To remove user data: rm -rf ~/.config/nexus-browser"
echo ""
UNINSTALLER

chmod +x "/usr/local/bin/uninstall-nexus-browser"

echo -e "  ${GREEN}[OK]${NC} Uninstaller created"
echo ""

# Installation complete
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}   Installation Complete!${NC}"
echo -e "${CYAN}========================================${NC}"
echo ""
echo "$APP_NAME v$APP_VERSION is now installed."
echo ""
echo "Installation directory: $INSTALL_DIR"
echo ""
echo "Launch from:"
echo "  - Application menu (search 'Nexus Browser')"
echo "  - Terminal: nexus-browser"
echo ""
echo "To uninstall:"
echo "  sudo uninstall-nexus-browser"
echo ""
echo "User data: ~/.config/nexus-browser"
echo ""
