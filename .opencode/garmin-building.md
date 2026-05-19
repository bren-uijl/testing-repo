# Garmin AI Chat - Building Guide (SDK 9.1.0)

> Updated: May 19, 2026 | SDK 9.1.0 | API Level 5.2+ | BUILD STATUS: SUCCESSFUL

## Status

The app has been successfully migrated to SDK 9.1.0 and builds without errors.

### Build Command

```bash
cd garmin-ai-chat
/opt/connectiq-sdk/bin/monkeyc -w -y /tmp/developer_key.der -f monkey.jungle -o dist/AIChat.prg -b /opt/connectiq-sdk/bin/api.mir
```

### Output

- `dist/AIChat.prg` - 147KB watch app PRG file

## Migration Details

See `.opencode/garmin-sdk-910-migration.md` for complete API change documentation.

## Build Environment Setup

### Prerequisites

- Java 17+
- Connect IQ SDK 9.1.0
- SDK Manager (for device definitions)

### SDK Installation

```bash
# Download SDK
curl -L -o connectiq-sdk.zip "https://developer.garmin.com/downloads/connect-iq/sdks/connectiq-sdk-lin-9.1.0-2026-03-09-6a872a80b.zip"

# Extract
unzip connectiq-sdk.zip -d /opt/connectiq-sdk

# Set environment
export CONNECTIQ_SDK_DIR=/opt/connectiq-sdk
```

### Device Setup

SDK 9.1.0 requires devices to be installed via SDK Manager. The devices are stored in:

```
~/.Garmin/ConnectIQ/Sdks/connectiq-sdk-9.1.0/devices/
```

Each device needs a `compiler.json` file with the following structure:

```json
{
    "deviceId": "vivoactive5",
    "displayName": "vívoactive® 5",
    "deviceFamily": "round-390x390",
    "bitsPerPixel": 16,
    "resolution": { "width": 390, "height": 390 },
    "appTypes": [
        { "type": "watchApp", "memoryLimit": 65536, "prgLimit": 65536 }
    ],
    "launcherIcon": { "width": 56, "height": 56 },
    "alphaBlendingSupport": true
}
```

## Build Commands

### Watch App Only

```bash
cd garmin-ai-chat

# Using build script
./build.sh vivoactive5 watch

# Manual build
monkeyc -w \
    -y developer_key.der \
    -f monkey.jungle \
    -o dist/AIChat.prg \
    -d vivoactive5
```

### With Jungle File (SDK 9.1.0 format)

```bash
# Create jungle file
cat > build.jungle << EOF
project.manifest = manifest.xml
sourcePath = source/
resourcePath = resources/
EOF

# Build
monkeyc -w \
    -f build.jungle \
    -o dist/AIChat.prg \
    -d vivoactive5 \
    -y developer_key.der
```

## Known Issues

1. **API Symbol Resolution**: Custom device definitions don't link to the API database properly. Use SDK Manager-installed devices.

2. **Phone App**: The phone app uses different APIs and should be built separately.

3. **API Changes**: SDK 9.1.0 has significant API changes from 4.x/5.x:
   - `Toybox.Json` → `Toybox.Communications`
   - `TextConfirmationDelegate` → `ConfirmationDelegate`
   - Various method renames and restructures

## Troubleshooting

### "Invalid device id specified"

The SDK 9.1.0 requires devices to be installed via SDK Manager. Run the SDK Manager GUI or set up the device folder manually in `~/.Garmin/ConnectIQ/Sdks/`.

### "Undefined symbol" errors

The device's API level must match the SDK's api.db. Check that `connectIQVersion` in `compiler.json` matches an available API version.

### "Cannot resolve module" errors

The module may have been renamed or removed in the SDK version. Check the API documentation for the correct module name.

## Resources

- [Connect IQ SDK](https://developer.garmin.com/connect-iq/)
- [SDK Manager](https://developer.garmin.com/connect-iq/sdk/)
- [Monkey C Guide](https://developer.garmin.com/connect-iq/monkey-c/)
- [API Reference](https://developer.garmin.com/connect-iq/reference/)
