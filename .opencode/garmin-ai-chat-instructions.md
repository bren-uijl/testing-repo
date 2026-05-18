# AI Chat for Garmin vívoactive 5 - Agent Instructions for Future Self

## Project Overview

AI Chat is a Garmin Connect IQ application for the vívoactive 5 that enables conversational AI powered by NVIDIA's API. Users can chat with various AI models directly from their watch.

The app is located at `garmin-ai-chat/`.

## Project Structure

```
garmin-ai-chat/
├── manifest.xml                      # Connect IQ app manifest (watch app)
├── resources/
│   ├── strings.xml                   # String resources (English)
│   ├── drawables.xml                 # Drawable resource definitions
│   ├── layouts.xml                   # Layout definitions
│   └── drawables/
│       └── launcher_icon.png         # 48x48 launcher icon (placeholder)
├── source/
│   ├── AiChatApp.mc                  # Main app entry point, navigation hub
│   ├── PropertyStore.mc              # Persistent storage for conversations & settings
│   ├── Message.mc                    # Message data model (user/assistant/system)
│   ├── Conversation.mc               # Conversation data model with message list
│   ├── NviApiClient.mc               # NVIDIA API HTTP client
│   ├── ConversationListView.mc       # Main screen: list of past conversations
│   ├── MessageInputView.mc           # Text input for new messages
│   ├── ConversationView.mc           # Single conversation view with message bubbles
│   ├── SettingsView.mc               # Settings menu (API key, model, clear)
│   └── ApiKeyInputView.mc            # Multi-segment API key input (10 x 7 chars)
└── phone/
    ├── manifest.xml                  # Phone app manifest
    ├── resources/
    │   └── strings.xml               # Phone app strings
    └── source/
        ├── AiChatPhoneApp.mc         # Phone app entry point
        └── PhoneSettingsView.mc      # Phone settings UI for easy API key entry
```

## Architecture Decisions

### Why Monkey C?
- Garmin Connect IQ SDK uses Monkey C language (Java-like syntax)
- Runs on the watch's embedded runtime
- Limited memory (~64KB for apps on vívoactive 5)
- No garbage collection - must manage memory carefully

### vívoactive 5 Specifications
- Display: 260x260 pixels, circular, AMOLED
- Touch screen only (no physical buttons)
- SDK: Connect IQ 4.x (minSdkVersion 3.3.0)
- Memory: Limited, avoid large allocations
- Communications: HTTP via `Toybox.Communications`

### API Key Input Strategy
The NVIDIA API key is 70 characters long - too long for comfortable single-field input on a 260px watch screen. Solution:
- Split into 10 segments of 7 characters each
- Each segment entered via watch's native text input
- Segments stored separately, reassembled for API calls
- Phone app available for easier full-key entry

### Storage Strategy
- Uses `Application.getAppProperty()` for persistence
- Conversations stored as dictionaries with message arrays
- API key stored both as full string and as segmented parts
- Phone app can sync settings to watch via `Communications.sendToWatchApp()`

## Key Features Implemented

### 1. Conversation List (Main Screen)
- Shows all past conversations sorted by last updated
- "+ New" button at top for starting new conversations
- Settings gear icon (top-right) for configuration
- Swipe up/down to scroll through conversations
- Tap conversation to open it

### 2. Message Input
- Uses watch's native text input (`WatchUi.invokeTextInput`)
- Send button enabled only when text is present
- Shows loading state during API call
- Error display for network/API issues

### 3. Conversation View
- Message bubbles: blue (user) on right, gray (assistant) on left
- System messages centered in gray
- Reply button at bottom to continue conversation
- Swipe to scroll through message history

### 4. Settings
- API Key: Opens multi-segment input view
- Model: Cycles through available NVIDIA models
- Clear All Chats: Deletes all stored conversations
- About: Shows app version

### 5. API Key Input (10 Segments)
- 10 input fields, each accepting 7 characters
- Character counter shows progress (X/70)
- Green indicator when key is complete
- Save button enabled when any characters entered

### 6. NVIDIA API Integration
- Endpoint: `https://integrate.api.nvidia.com/v1/chat/completions`
- Auth: Bearer token in Authorization header
- Request: JSON with model, messages, max_tokens, temperature
- Response: Parsed for `choices[0].message.content`
- Error handling for network failures and API errors

## Supported Models

| Model | Description |
|-------|-------------|
| nvidia/nemotron-nano-9b-v2 | Default, fast, good quality |
| meta/llama-3.1-8b-instruct | Meta's Llama 3.1 8B |
| meta/llama-3.1-70b-instruct | Meta's Llama 3.1 70B (higher quality) |
| mistralai/mistral-7b-instruct-v0.2 | Mistral 7B |
| google/gemma-2-9b-it | Google Gemma 2 9B |
| openai/gpt-oss-120b | OpenAI GPT-OSS 120B |
| openai/gpt-oss-20b | OpenAI GPT-OSS 20B |
| mistralai/mistral-medium-3.5-128b | Mistral Medium 3.5 128B |

## Build Commands

```bash
# Requires Connect IQ SDK installed
# Set CONNECTIQ_SDK_DIR environment variable

monkeyc -w -y developer_key.der -m manifest.xml -z resources/ -o AIChat.prg source/*.mc

# With phone app
monkeyc -w -y developer_key.der -m manifest.xml -m phone/manifest.xml \
  -z resources/ -z phone/resources/ -o AIChat.prg \
  source/*.mc phone/source/*.mc
```

## Next Steps for Future Self

### Priority 1 - Must Have
1. **Streaming Responses**: Implement streaming for faster perceived response time (SDK limitation may apply)
2. **Proper Launcher Icon**: Create a 48x48 PNG icon for the app
3. **Error Recovery**: Handle network timeouts gracefully with retry logic
4. **Conversation Export**: Export conversations as text files

### Priority 2 - Should Have
5. **Conversation Search**: Search through past conversations
6. **Message Editing**: Edit sent messages before resending
7. **Copy Response**: Long-press to copy assistant responses
8. **Conversation Rename**: Allow custom conversation titles
9. **Delete Single Conversation**: Swipe-to-delete or context menu

### Priority 3 - Nice to Have
10. **System Prompt**: Customizable system prompt in settings
11. **Temperature Control**: Adjust creativity/temperature per conversation
12. **Max Tokens Setting**: Configurable response length
13. **Voice Input**: Use watch microphone for voice-to-text
14. **Offline Queue**: Queue messages when offline, send when connected
15. **Response Caching**: Cache frequent responses

### Priority 4 - Polish
16. **Animations**: Smooth transitions between views
17. **Haptic Feedback**: Vibrate on send/receive
18. **Dark/Light Theme**: Theme options
19. **Conversation Stats**: Message count, token usage display
20. **Quick Replies**: Pre-defined prompt templates

## Known Limitations

1. **Memory Constraints**: vívoactive 5 has limited RAM. Long conversations may cause issues. Consider truncating message history for API calls.
2. **Text Input**: Watch text input is slow. Phone app is recommended for API key entry.
3. **HTTP Timeouts**: Watch HTTP requests may timeout on slow connections. No streaming support yet.
4. **No Background Sync**: App must be open for API calls. No background processing.
5. **Character Limit**: Message input limited to 500 characters via watch input.
6. **No Image Support**: Text-only. No multimodal capabilities.

## Testing Checklist

- [ ] App launches and shows conversation list
- [ ] New conversation button opens text input
- [ ] Text input sends message to NVIDIA API
- [ ] API response displays correctly
- [ ] Conversation persists after app restart
- [ ] API key can be set via 10-segment input
- [ ] API key can be set via phone app
- [ ] Model can be changed in settings
- [ ] Conversations can be cleared
- [ ] Scroll works in conversation list and detail
- [ ] Back navigation works correctly
- [ ] Error handling for missing API key
- [ ] Error handling for network failures

## Dependencies

- Connect IQ SDK 4.x
- Toybox.System
- Toybox.WatchUi
- Toybox.Graphics
- Toybox.Communications
- Toybox.Application
- Toybox.Lang
- Toybox.Json

## API Reference

### NVIDIA Chat Completions API

```
POST https://integrate.api.nvidia.com/v1/chat/completions
Authorization: Bearer <api-key>
Content-Type: application/json

{
  "model": "nvidia/nemotron-nano-9b-v2",
  "messages": [
    {"role": "user", "content": "Hello"}
  ],
  "max_tokens": 1024,
  "temperature": 0.7
}
```

## Release Checklist

1. Create proper launcher icon (48x48 PNG)
2. Test on actual vívoactive 5 hardware
3. Verify API key input flow works end-to-end
4. Test with all supported models
5. Test error scenarios (no network, invalid key)
6. Build release .prg file
7. Submit to Connect IQ Store (optional)

## Resources

- Connect IQ SDK: https://developer.garmin.com/connect-iq/
- Connect IQ Docs: https://developer.garmin.com/connect-iq/core-topics/
- Monkey C Guide: https://developer.garmin.com/connect-iq/monkey-c/
- vívoactive 5 Specs: https://developer.garmin.com/connect-iq/compatible-devices/
- NVIDIA API: https://build.nvidia.com/

## Commit History Pattern

Each feature committed separately:
1. Initialize project structure and manifest
2. Add resource files
3. Add data models
4. Add main app class
5. Add conversation list view
6. Add message input view
7. Add conversation detail view
8. Add settings view
9. Add API key input view
10. Add NVIDIA API client
11. Add phone companion app
12. Add documentation

---

*These instructions are for the next agent session. Follow the commit-after-each-edit rule. The app targets vívoactive 5 (260x260 circular display, touch-only).*
