# Garmin AI Chat - SDK 9.1.0 Migration Complete

## Status: BUILD SUCCESSFUL

The app has been successfully migrated to compile with Connect IQ SDK 9.1.0.

## Build Command

```bash
cd garmin-ai-chat
/opt/connectiq-sdk/bin/monkeyc -w -y /tmp/developer_key.der -f monkey.jungle -o dist/AIChat.prg -b /opt/connectiq-sdk/bin/api.mir
```

## SDK Location

- SDK installed at: `/opt/connectiq-sdk`
- SDK version: 9.1.0
- API database: `/opt/connectiq-sdk/bin/api.mir`

## API Changes Applied

### 1. JSON API
- Removed `using Toybox.Json;`
- `Json.encode()` → Use dictionary directly as `makeWebRequest` parameters (auto-encoded)
- `Json.decode()` → Use `HTTP_RESPONSE_CONTENT_TYPE_JSON` response type (auto-decoded to Dictionary)
- Dictionary access: `dict[:key]` instead of `dict.get(:key)`

### 2. Text Input
- `WatchUi.invokeTextInput()` → `WatchUi.pushView(new WatchUi.TextPicker(text), delegate, WatchUi.SLIDE_DOWN)`
- `TextConfirmationDelegate` → `TextPickerDelegate` for text input
- `ConfirmationDelegate` for simple confirmations
- `onConfirmed(text)` → `onTextEntered(text, changed)` with `return true`

### 3. Web Request
- `WebResponseDelegate` → Use method reference `method(:onResponse)` directly
- `makeWebRequest(url, params, options, callback)` signature
- Response callback: `function onResponse(responseCode, data) as Void`

### 4. Swipe Constants
- `WatchUi.SWIPE_DIRECTION_UP` → `WatchUi.SWIPE_UP`
- `WatchUi.SWIPE_DIRECTION_DOWN` → `WatchUi.SWIPE_DOWN`
- `WatchUi.SWIPE_DIRECTION_LEFT` → `WatchUi.SWIPE_LEFT`
- `WatchUi.SWIPE_DIRECTION_RIGHT` → `WatchUi.SWIPE_RIGHT`

### 5. Application Properties
- `Application.getApp().getAppProperty()` → `Application.getApp().getProperty()`
- `Application.getApp().setAppProperty()` → `Application.getApp().setProperty()`

### 6. View Updates
- `View.requestUpdate()` → `WatchUi.requestUpdate()`

### 7. Screen Dimensions
- `getWidth()`/`getHeight()` in event handlers → Store `viewWidth`/`viewHeight` in `onLayout(dc)`
- Use `dc.getWidth()`/`dc.getHeight()` only in `onUpdate(dc)`

### 8. Graphics
- `dc.getTextWidth()` → `dc.getTextWidthInPixels()`

### 9. Arrays
- `arr.set(idx, value)` → `arr[idx] = value`
- `arr.get(idx)` → `arr[idx]`

### 10. Removed APIs
- `System.setTimer()`/`System.cancelTimer()` → Removed timer animations
- `System.vibrate()` → Removed
- `Communications.sendToWatchApp()` → Removed from phone app

### 11. Import Style
- Use `import Toybox.X;` instead of `using Toybox.X;` for type annotations to work

## Known Warnings (Non-blocking)

- `getProperty`/`setProperty` deprecated (still functional)
- Container type determination warnings (cosmetic)
- Unused local variable warnings (cosmetic)
- Invalid device id 'vivoactive5' (requires SDK Manager device installation)

## Phone App Limitations

The phone app compiles but has limited functionality:
- `syncToWatch()` not supported in SDK 9.1.0
- Text input uses TextPicker instead of invokeTextInput

## Device Setup

For full device-specific API resolution, install devices via SDK Manager:
```
~/.Garmin/ConnectIQ/Sdks/connectiq-sdk-9.1.0/devices/
```

## File Change Summary

| File | Key Changes |
|------|-------------|
| `source/NviApiClient.mc` | JSON API, WebResponseDelegate, import syntax |
| `source/MessageInputView.mc` | TextPicker, timer removal, dimensions |
| `source/ConversationView.mc` | TextPicker, timer removal, dimensions |
| `source/ApiKeyInputView.mc` | TextPicker, dimensions |
| `source/ConversationListView.mc` | Swipe constants, dimensions |
| `source/AboutView.mc` | Swipe constants, dimensions |
| `source/SettingsView.mc` | Swipe constants, dimensions, array access |
| `source/PropertyStore.mc` | getProperty/setProperty |
| `phone/source/AiChatPhoneApp.mc` | Json removal, getProperty/setProperty |
| `phone/source/PhoneSettingsView.mc` | TextPicker, dimensions |
| `monkey.jungle` | Simplified format |
