# Garmin AI Chat - Developer Guide

Get started building and extending the Garmin AI Chat app.

## Overview

AI Chat is a Connect IQ application for Garmin watches that brings conversational AI to your wrist. It supports multiple AI models including NVIDIA, Meta, Mistral, Google, and OpenAI GPT-OSS models.

The app is located at `garmin-ai-chat/`.

---

## Project Structure

```
garmin-ai-chat/
├── manifest.xml              # Connect IQ app manifest
├── monkey.jungle             # Build configuration
├── developer_key.der         # Developer signing key
├── resources/
│   ├── strings.xml           # String resources
│   ├── drawables.xml         # Drawable definitions
│   ├── layouts.xml           # Layout definitions
│   └── drawables/
│       └── launcher_icon.png # 48x48 launcher icon
├── source/                   # Watch app source
│   ├── AiChatApp.mc          # Main app entry
│   ├── PropertyStore.mc      # Data persistence
│   ├── Message.mc            # Message model
│   ├── Conversation.mc       # Conversation model
│   ├── NviApiClient.mc       # API client
│   ├── ConversationListView.mc
│   ├── MessageInputView.mc
│   ├── ConversationView.mc
│   ├── SettingsView.mc
│   └── ApiKeyInputView.mc
└── phone/                    # Phone companion app
    ├── manifest.xml
    ├── resources/
    └── source/
```

---

## Build

### Prerequisites

1. Connect IQ SDK 9.x
2. Java 17+
3. SDK Manager with vivoactive5 device downloaded

### Commands

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

## Architecture

### Monkey C Language

- Garmin Connect IQ SDK uses Monkey C (Java-like syntax)
- Runs on watch embedded runtime
- Limited memory (~64KB for apps)
- No garbage collection

### vivoactive 5 Specifications

- Display: 390x390 pixels, circular, AMOLED
- Touch screen only
- SDK: Connect IQ 5.2.0
- Memory: 64KB for apps

### API Integration

- Endpoint: `https://integrate.api.nvidia.com/v1/chat/completions`
- Auth: Bearer token in Authorization header
- Request: JSON with model, messages, max_tokens, temperature
- Response: Parsed for `choices[0].message.content`

---

## Supported Models

| Model | Provider |
|-------|----------|
| nvidia/nemotron-nano-9b-v2 | NVIDIA (default) |
| meta/llama-3.1-8b-instruct | Meta |
| meta/llama-3.1-70b-instruct | Meta |
| mistralai/mistral-7b-instruct-v0.2 | Mistral AI |
| google/gemma-2-9b-it | Google |
| openai/gpt-oss-120b | OpenAI |
| openai/gpt-oss-20b | OpenAI |
| mistralai/mistral-medium-3.5-128b | Mistral AI |

---

## Key Features

### Conversation List
- Shows all past conversations sorted by last updated
- "+ New" button for starting new conversations
- Settings gear icon for configuration

### Message Input
- Uses watch native text input
- Send button enabled only when text present
- Shows loading state during API call

### Conversation View
- Message bubbles: blue (user) on right, gray (assistant) on left
- Reply button to continue conversation
- Swipe to scroll through history

### Settings
- API Key: Multi-segment input (10 x 7 chars)
- Model: Cycle through available models
- Clear All Chats: Delete all conversations

---

## Adding New Models

To add a new model, update these files:

1. `source/SettingsView.mc` - Add to `cycleModel()` models array
2. `phone/source/PhoneSettingsView.mc` - Add to `models` array
3. `README.md` - Update supported models table
4. `.opencode/garmin-ai-chat-instructions.md` - Update documentation

---

## Upload to Watch

### Sideloading via USB

1. Build the app to get `AIChat.prg`
2. Connect watch to computer via USB
3. Copy `.prg` to `GARMIN/Apps/` on watch
4. Eject and restart watch
5. Find app in apps menu

### Connect IQ Store

1. Create developer account at developer.garmin.com
2. Submit app to Connect IQ Store
3. Users install directly from store

---

## Known Limitations

1. Memory constraints limit conversation length
2. Text input on watch is slow
3. HTTP requests may timeout on slow connections
4. No background sync - app must be open
5. Character limit: 500 chars via watch input
6. Text-only, no image support

---

## Testing Checklist

- [ ] App launches and shows conversation list
- [ ] New conversation button opens text input
- [ ] Text input sends message to API
- [ ] API response displays correctly
- [ ] Conversation persists after app restart
- [ ] API key can be set via 10-segment input
- [ ] Model can be changed in settings
- [ ] Conversations can be cleared
- [ ] Scroll works in list and detail views
- [ ] Back navigation works correctly
- [ ] Error handling for missing API key
- [ ] Error handling for network failures

---

## Resources

- [Connect IQ SDK](https://developer.garmin.com/connect-iq/)
- [Connect IQ Docs](https://developer.garmin.com/connect-iq/core-topics/)
- [Monkey C Guide](https://developer.garmin.com/connect-iq/monkey-c/)
- [vívoactive 5 Specs](https://developer.garmin.com/connect-iq/compatible-devices/)
- [NVIDIA API](https://build.nvidia.com/)
