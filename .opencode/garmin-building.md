# Garmin AI Chat - Building & Development Guide

> This guide covers how to build, test, and extend the Garmin AI Chat Connect IQ app.

## Quick Start

```bash
# Set up the SDK
export CONNECTIQ_SDK_DIR=/path/to/connectiq-sdk

# Build the app
cd garmin-ai-chat
./build.sh

# Run in simulator
./build.sh vivoactive5 watch run
```

## Project Overview

AI Chat is a Connect IQ app for Garmin vívoactive 5 that enables conversational AI using NVIDIA's API. Users can chat with multiple AI models directly from their watch.

**Current Version:** 1.2.0
**Target Device:** vívoactive 5 (390x390 circular AMOLED, touch-only)
**SDK:** Connect IQ 4.x/5.x
**Language:** Monkey C

## Architecture

### Source Files

| File | Purpose |
|------|---------|
| `AiChatApp.mc` | App entry point, navigation hub |
| `PropertyStore.mc` | Persistent storage (conversations, settings) |
| `Message.mc` | Message data model |
| `Conversation.mc` | Conversation model with message list |
| `NviApiClient.mc` | HTTP client for NVIDIA API |
| `ConversationListView.mc` | Main screen with conversation list + quick prompts |
| `MessageInputView.mc` | Text input for composing messages |
| `ConversationView.mc` | Chat view with message bubbles |
| `SettingsView.mc` | Settings menu |
| `ApiKeyInputView.mc` | 10-segment API key input |
| `AboutView.mc` | App info screen |

### Data Flow

```
User Input → MessageInputView → NviApiClient → NVIDIA API → Response → ConversationView
                                      ↓
                              PropertyStore (persist)
```

### Storage

Uses `Application.getAppProperty()` for persistence:
- Conversations stored as dictionaries with message arrays
- Max 20 conversations, 30 messages per conversation
- Auto-evicts oldest when limits reached
- API key stored as full string + segmented parts

## Building

### Prerequisites

1. Connect IQ SDK 9.x
2. Java 17+
3. SDK Manager with vivoactive5 device downloaded

### Build Options

```bash
# Watch app only
./build.sh

# Watch + phone app
./build.sh vivoactive5 full

# Build and run in simulator
./build.sh vivoactive5 watch run
```

### Manual Build

```bash
monkeyc -w -y developer_key.der -f monkey.jungle -o dist/AIChat.prg -d vivoactive5
```

## Features (v1.2.0)

### Core
- Start and continue AI conversations on watch
- 8 AI models (NVIDIA, Meta, Mistral, Google, OpenAI)
- Persistent local storage for conversations
- Phone companion app for API key config

### Conversation List
- Sorted by last updated
- Quick prompt templates (Translate, Summarize, Explain, etc.)
- Swipe-to-delete conversations
- Settings access from gear icon

### Conversation View
- Message bubbles (blue=user, gray=assistant)
- Tap title to rename
- Tap message count to clear
- Retry on failed requests
- Cancel during loading
- Haptic feedback

### Settings
- API key input (10 segments × 7 chars)
- Model cycling with friendly names
- System prompt reset
- Clear all conversations
- About screen

## Adding Features

### New Model

Update these files:
1. `source/SettingsView.mc` → `cycleModel()` and `getModelDisplayName()`
2. `phone/source/PhoneSettingsView.mc` → `models` array
3. `README.md` → supported models table

### New View

1. Create `source/MyView.mc` extending `WatchUi.View`
2. Create `MyInputDelegate` extending `WatchUi.BehaviorDelegate`
3. Add navigation method in `AiChatApp.mc`
4. Push with `WatchUi.pushView(view, delegate, WatchUi.SLIDE_IMMEDIATE)`

### New String Resource

Add to `resources/strings.xml`:
```xml
<string id="MyString">My Text</string>
```

Access in code: `Rez.Strings.MyString`

## Known Issues

1. Memory constraints limit conversation length
2. Text input on watch is slow (use phone app for API key)
3. HTTP requests may timeout on slow connections
4. No background sync - app must be open
5. 500 char limit via watch text input
6. Text-only, no image support

## Testing Checklist

- [ ] App launches and shows conversation list
- [ ] Quick prompts toggle and start conversations
- [ ] Text input sends message to API
- [ ] API response displays correctly
- [ ] Conversation persists after restart
- [ ] API key set via 10-segment input
- [ ] API key set via phone app
- [ ] Model changes in settings
- [ ] Conversations can be cleared
- [ ] Scroll works in all views
- [ ] Back navigation works
- [ ] Error handling for missing API key
- [ ] Error handling for network failures
- [ ] Retry works on failed requests
- [ ] Cancel works during loading
- [ ] Rename conversation works
- [ ] Clear conversation works
- [ ] Haptic feedback triggers
- [ ] Swipe-to-delete works

## Resources

- [Connect IQ SDK](https://developer.garmin.com/connect-iq/)
- [Monkey C Guide](https://developer.garmin.com/connect-iq/monkey-c/)
- [API Reference](https://developer.garmin.com/connect-iq/reference/)
- [vívoactive 5 Specs](https://developer.garmin.com/connect-iq/compatible-devices/)
- [NVIDIA API](https://build.nvidia.com/)
