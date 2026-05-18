# Garmin AI Chat - SDK API Migration Guide

## Overview

The Garmin AI Chat app was migrated to match the current Connect IQ SDK API. This document records all changes made and serves as a reference for future development.

**Migration Date:** May 18, 2026
**Target SDK:** Connect IQ 4.x/5.x
**Target Device:** vivoactive 5
**Current Version:** v1.2.0

---

## Breaking Changes Fixed

### 1. Resource Access Pattern

**Old (deprecated):**
```monkeyc
Resources.getString(Resources.Strings.AppName)
Lang.format("$1$", [Resources.getString(Resources.Strings.X)])
```

**New:**
```monkeyc
Rez.Strings.AppName
```

The `Rez` module is auto-generated from resource XML files. Direct access is faster and the recommended pattern in SDK 4.x+.

**Files affected:**
- `source/ApiKeyInputView.mc`
- `source/ConversationListView.mc`
- `source/ConversationView.mc`
- `source/MessageInputView.mc`
- `source/SettingsView.mc`

### 2. Communications API

**Old (deprecated):**
```monkeyc
Communications.makeJsonRequest(url, options, delegate)
```

**New:**
```monkeyc
Communications.makeWebRequest(url, options, delegate)
```

The `makeJsonRequest` method was replaced with `makeWebRequest`. The delegate also changed from `JsonResponseDelegate` to `WebResponseDelegate`.

**Response handling change:**
- Old: `data` was automatically parsed as JSON
- New: `data` is a `String` or `Blob` - must manually call `Json.decode()`

**Files affected:**
- `source/NviApiClient.mc`

### 3. Delegate Pattern

**Old (problematic):**
```monkeyc
class MyDelegate extends WatchUi.BehaviorDelegate
    function onTap(evt) {
        var v = WatchUi.getView();  // Unreliable
        if (v has :onTap) { v.onTap(evt); }
    }
end
```

**New (recommended):**
```monkeyc
class MyDelegate extends WatchUi.BehaviorDelegate
    var view;

    function initialize(theView) {
        BehaviorDelegate.initialize();
        view = theView;
    }

    function onTap(evt) {
        if (view != null && view has :onTap) {
            view.onTap(evt);
        }
        return true;
    }
end
```

Delegates should hold a direct reference to their view rather than relying on `WatchUi.getView()`.

**Files affected:**
- `source/AiChatApp.mc` - Updated all `pushView` calls to pass view+delegate pairs
- `source/ApiKeyInputView.mc`
- `source/ConversationListView.mc`
- `source/ConversationView.mc`
- `source/MessageInputView.mc`
- `source/SettingsView.mc`
- `phone/source/PhoneSettingsView.mc`

### 4. Time API

**Old (incorrect):**
```monkeyc
var time = new Time.Gregorian(timestamp);  // timestamp is raw ms number
```

**New:**
```monkeyc
// Use relative time calculation instead
var elapsed = System.getTimer() - timestamp;
var minutes = elapsed / 60000;
```

`Time.Gregorian` expects a `Time.Duration` object, not a raw number. Since `System.getTimer()` returns elapsed milliseconds since boot (not a Unix timestamp), using `Time.Gregorian` was conceptually wrong anyway.

**Files affected:**
- `source/Message.mc`

### 5. Missing Imports

Added `using Toybox.Json;` to files that use `Json.encode()` or `Json.decode()`:
- `source/NviApiClient.mc`
- `source/MessageInputView.mc`
- `phone/source/AiChatPhoneApp.mc`

Added `using Toybox.Time;` to:
- `source/Message.mc`

Added `using Toybox.System;` to:
- `source/PropertyStore.mc`

### 6. getInitialView() Return Format

**Old:**
```monkeyc
function getInitialView() {
    return [new MyView()];  // Missing delegate
}
```

**New:**
```monkeyc
function getInitialView() {
    var view = new MyView();
    var delegate = new MyInputDelegate(view);
    return [view, delegate];
}
```

The `getInitialView()` method should return both view and delegate as an array.

**Files affected:**
- `source/AiChatApp.mc`
- `phone/source/AiChatPhoneApp.mc`

---

## Bug Fixes

### 1. Undefined Variable in MessageInputView
- **Issue:** `storage` was referenced in `onSendComplete()` but not defined as class member
- **Fix:** Added `storage` as class member, initialized in `initialize()`

### 2. Direct Array Access
- **Issue:** `conversation.messages.remove()` accessed internal array directly
- **Fix:** Added `Conversation.removeLastMessage()` method

### 3. Memory Overflow Prevention
- **Issue:** No limit on conversations or messages could fill device memory
- **Fix:** Added `MAX_CONVERSATIONS = 20` and `MAX_MESSAGES_PER_CONVERSATION = 30`
- Auto-evicts oldest conversation when limit reached
- Auto-removes oldest messages when per-conversation limit reached

### 4. Bounds Checking
- **Issue:** `setApiKeyPart(index)` had no bounds validation
- **Fix:** Added index validation (0-9 range)

### 5. Null Safety
- **Issue:** Corrupted data could cause crashes
- **Fix:** Added null checks in:
  - `Conversation.load()`
  - `Message.fromDictionary()`
  - `ConversationListView.loadConversations()`
  - `ConversationView.loadData()`
  - `NviApiClient.onResponse()`

---

## New Features Added

### 1. System Prompt Support
- Configurable system prompt stored in PropertyStore
- Included in API requests as first message
- Reset to default via Settings menu
- Default: "You are a helpful assistant on a Garmin watch. Keep responses concise and under 200 characters."

### 2. Improved Error Messages
- User-friendly messages for common HTTP codes:
  - 401: "Invalid API key"
  - 403: "Access denied"
  - 429: "Rate limited, try later"
  - 500: "Server error"
  - 503: "Service unavailable"
- Truncated API error messages to fit watch screen

### 3. Swipe-to-Delete Conversations
- Swipe left to enter delete mode
- Red visual indicator for delete mode
- Tap conversation to select for deletion
- Tap New button to confirm deletion
- Swipe right to exit delete mode

---

## API Reference Changes Summary

| Old API | New API | Status |
|---------|---------|--------|
| `Resources.getString(Resources.Strings.X)` | `Rez.Strings.X` | Required |
| `Communications.makeJsonRequest()` | `Communications.makeWebRequest()` | Required |
| `Communications.JsonResponseDelegate` | `Communications.WebResponseDelegate` | Required |
| `WatchUi.getView()` | Store view reference in delegate | Required |
| `new Time.Gregorian(ms)` | Use relative time or `new Time.Duration(ms)` | Required |
| `[view]` return from getInitialView | `[view, delegate]` | Required |

---

## PropertyStore Constants

```monkeyc
MAX_CONVERSATIONS = 20
MAX_MESSAGES_PER_CONVERSATION = 30
API_KEY_SEGMENT_COUNT = 10
```

---

## Build Commands

```bash
# Build watch app
monkeyc -w -y developer_key.der -f monkey.jungle -o dist/AIChat.prg -d vivoactive5

# Build with phone app
monkeyc -w -y developer_key.der -f monkey.jungle -o dist/AIChat.prg \
  -d vivoactive5 \
  source/*.mc phone/source/*.mc \
  -z resources/ -z phone/resources/

# Test in simulator
monkeydo dist/AIChat.prg vivoactive5
```

---

## File Change Summary

| File | Changes |
|------|---------|
| `source/AiChatApp.mc` | Fixed getInitialView, pushView patterns |
| `source/ApiKeyInputView.mc` | Fixed Rez.Strings, delegate pattern |
| `source/Conversation.mc` | Added removeLastMessage(), message limit, null safety |
| `source/ConversationListView.mc` | Fixed Rez.Strings, delegate pattern, added delete mode |
| `source/ConversationView.mc` | Fixed Rez.Strings, delegate pattern, null safety |
| `source/Message.mc` | Fixed Time API, added null safety |
| `source/MessageInputView.mc` | Fixed Rez.Strings, delegate pattern, storage bug |
| `source/NviApiClient.mc` | Fixed makeWebRequest, WebResponseDelegate, error messages |
| `source/PropertyStore.mc` | Added limits, system prompt, bounds checking |
| `source/SettingsView.mc` | Fixed Rez.Strings, added system prompt option |
| `phone/source/AiChatPhoneApp.mc` | Fixed getInitialView, added Json import |
| `phone/source/PhoneSettingsView.mc` | Fixed delegate pattern |

---

## Next Steps

### Priority 1
1. Test compilation with actual Connect IQ SDK
2. Verify on vivoactive 5 simulator
3. Test on physical device

### Priority 2
4. Add proper launcher icon (48x48 PNG)
5. Implement streaming response support
6. Add conversation export

### Priority 3
7. Add conversation search
8. Add temperature control per conversation
9. Add message editing

---

## Resources

- Connect IQ SDK: https://developer.garmin.com/connect-iq/
- Monkey C Guide: https://developer.garmin.com/connect-iq/monkey-c/
- API Reference: https://developer.garmin.com/connect-iq/reference/
- vivoactive 5 Specs: https://developer.garmin.com/connect-iq/compatible-devices/

---

*These instructions are for the next agent session. The app targets vivoactive 5 with Connect IQ SDK 4.x/5.x. Current version: v1.1.0.*
