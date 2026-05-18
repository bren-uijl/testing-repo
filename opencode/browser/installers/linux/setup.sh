#!/bin/bash
# Nexus Browser - Linux Offline Installer
# Version 1.0.0

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
APP_NAME="Nexus Browser"
APP_VERSION="1.0.0"
INSTALL_DIR="/opt/nexus-browser"
BIN_LINK="/usr/local/bin/nexus-browser"
DESKTOP_FILE="/usr/share/applications/nexus-browser.desktop"
ICON_FILE="/opt/nexus-browser/assets/icon.png"

# Print banner
echo ""
echo "========================================"
echo "   $APP_NAME Installer v$APP_VERSION"
echo "========================================"
echo ""

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}[WARNING]${NC} This installer requires root privileges."
    echo "         Please run with sudo: sudo $0"
    echo ""
    exit 1
fi

# Detect package manager
detect_package_manager() {
    if command -v apt-get &> /dev/null; then
        echo "apt"
    elif command -v yum &> /dev/null; then
        echo "yum"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v pacman &> /dev/null; then
        echo "pacman"
    elif command -v zypper &> /dev/null; then
        echo "zypper"
    else
        echo "unknown"
    fi
}

# Check dependencies
check_dependencies() {
    echo -e "${BLUE}[1/5]${NC} Checking dependencies..."

    local pkg_manager
    pkg_manager=$(detect_package_manager)

    # Check for Node.js
    if command -v node &> /dev/null; then
        local node_version
        node_version=$(node --version)
        echo -e "  ${GREEN}[OK]${NC} Node.js detected: $node_version"
    else
        echo -e "  ${YELLOW}[!]${NC} Node.js not found"
        echo "      Installing Node.js via package manager ($pkg_manager)..."

        case $pkg_manager in
            apt)
                curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
                apt-get install -y nodejs
                ;;
            yum|dnf)
                curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
                $pkg_manager install -y nodejs
                ;;
            pacman)
                pacman -S --noconfirm nodejs npm
                ;;
            zypper)
                zypper install -y nodejs
                ;;
            *)
                echo -e "  ${RED}[ERROR]${NC} Cannot install Node.js automatically."
                echo "            Please install Node.js 18+ manually from https://nodejs.org"
                exit 1
                ;;
        esac
        echo -e "  ${GREEN}[OK]${NC} Node.js installed: $(node --version)"
    fi

    # Check for npm
    if command -v npm &> /dev/null; then
        echo -e "  ${GREEN}[OK]${NC} npm detected: $(npm --version)"
    else
        echo -e "  ${RED}[ERROR]${NC} npm not found"
        exit 1
    fi

    echo ""
}

# Install application
install_application() {
    echo -e "${BLUE}[2/5]${NC} Installing application files..."

    # Create installation directory
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$INSTALL_DIR/src/ui"
    mkdir -p "$INSTALL_DIR/src/extensions"
    mkdir -p "$INSTALL_DIR/src/features"
    mkdir -p "$INSTALL_DIR/assets"

    # Get source directory (parent of installers/linux)
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    SOURCE_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

    # Copy application files
    if [ -d "$SOURCE_DIR/src" ]; then
        cp -r "$SOURCE_DIR/src"/* "$INSTALL_DIR/src/"
        cp "$SOURCE_DIR/package.json" "$INSTALL_DIR/"
        echo -e "  ${GREEN}[OK]${NC} Application files copied"
    else
        echo -e "  ${YELLOW}[!]${NC} Source files not found in expected location"
    fi

    echo ""
}

# Install dependencies
install_dependencies() {
    echo -e "${BLUE}[3/5]${NC} Installing dependencies..."

    cd "$INSTALL_DIR"

    if [ -d "$SOURCE_DIR/node_modules" ]; then
        cp -r "$SOURCE_DIR/node_modules" "$INSTALL_DIR/"
        echo -e "  ${GREEN}[OK]${NC} Using bundled dependencies"
    else
        npm install --production
        echo -e "  ${GREEN}[OK]${NC} Dependencies installed"
    fi

    echo ""
}

# Create launcher
create_launcher() {
    echo -e "${BLUE}[4/5]${NC} Creating launcher..."

    # Create executable script
    cat > "$INSTALL_DIR/nexus-browser" << 'LAUNCHER'
#!/bin/bash
# Nexus Browser Launcher
exec node --no-warnings /opt/nexus-browser/src/main.js "$@"
LAUNCHER

    chmod +x "$INSTALL_DIR/nexus-browser"

    # Create symlink
    if [ -L "$BIN_LINK" ] || [ -f "$BIN_LINK" ]; then
        rm -f "$BIN_LINK"
    fi
    ln -s "$INSTALL_DIR/nexus-browser" "$BIN_LINK"

    # Create desktop entry
    cat > "$DESKTOP_FILE" << DESKTOP
[Desktop Entry]
Name=Nexus Browser
Comment=A next-generation browser with Chrome Web Store support
Exec=$BIN_LINK
Icon=$ICON_FILE
Terminal=false
Type=Application
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;
Keywords=browser;web;internet;
DESKTOP

    chmod 644 "$DESKTOP_FILE"

    echo -e "  ${GREEN}[OK]${NC} Launcher created"
    echo ""
}

# Create uninstaller
create_uninstaller() {
    echo -e "${BLUE}[5/5]${NC} Creating uninstaller..."

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
echo "Removing application files..."
rm -rf /opt/nexus-browser

echo "Removing launcher..."
rm -f /usr/local/bin/nexus-browser

echo "Removing desktop entry..."
rm -f /usr/share/applications/nexus-browser.desktop

echo ""
echo "========================================"
echo "   Uninstallation Complete"
echo "========================================"
echo ""
echo "Note: User data is preserved in ~/.config/nexus-browser"
echo "To remove user data, run: rm -rf ~/.config/nexus-browser"
echo ""
UNINSTALLER

    chmod +x "/usr/local/bin/uninstall-nexus-browser"

    echo -e "  ${GREEN}[OK]${NC} Uninstaller created"
    echo ""
}

# Main installation flow
check_dependencies
install_application
install_dependencies
create_launcher
create_uninstaller

# Summary
echo "========================================"
echo "   Installation Complete!"
echo "========================================"
echo ""
echo "$APP_NAME v$APP_VERSION is now installed."
echo ""
echo "Installation directory: $INSTALL_DIR"
echo ""
echo "Launch from:"
echo "  - Application menu (search for 'Nexus Browser')"
echo "  - Terminal: nexus-browser"
echo ""
echo "To uninstall, run:"
echo "  sudo uninstall-nexus-browser"
echo ""
echo "User data location:"
echo "  ~/.config/nexus-browser"
echo ""
