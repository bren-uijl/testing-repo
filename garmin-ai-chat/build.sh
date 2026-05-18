#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

SDK_DIR="${CONNECTIQ_SDK_DIR:-}"
DEVICE="${1:-vivoactive5}"
BUILD_TYPE="${2:-watch}"

if [ -z "$SDK_DIR" ]; then
    echo "Error: CONNECTIQ_SDK_DIR environment variable not set"
    echo "Usage: export CONNECTIQ_SDK_DIR=/path/to/connectiq-sdk"
    exit 1
fi

MONKEYC="$SDK_DIR/bin/monkeyc"
MONKEYDO="$SDK_DIR/bin/monkeydo"

if [ ! -x "$MONKEYC" ]; then
    echo "Error: monkeyc not found at $MONKEYC"
    exit 1
fi

mkdir -p dist

echo "Building AI Chat for $DEVICE..."

if [ "$BUILD_TYPE" = "full" ] || [ "$BUILD_TYPE" = "phone" ]; then
    $MONKEYC -w \
        -y developer_key.der \
        -f monkey.jungle \
        -o dist/AIChat.prg \
        -d "$DEVICE" \
        source/*.mc phone/source/*.mc \
        -z resources/ -z phone/resources/
    echo "Built with phone app: dist/AIChat.prg"
else
    $MONKEYC -w \
        -y developer_key.der \
        -f monkey.jungle \
        -o dist/AIChat.prg \
        -d "$DEVICE" \
        source/*.mc \
        -z resources/
    echo "Built watch app: dist/AIChat.prg"
fi

echo "Build complete!"

if [ "$3" = "run" ]; then
    echo "Launching simulator..."
    $MONKEYDO dist/AIChat.prg "$DEVICE"
fi
