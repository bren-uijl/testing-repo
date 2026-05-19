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
│   ├── ConversationListView.mc       # Main screen: list of past conversations + quick prompts
│   ├── MessageInputView.mc           # Text input for new messages
│   ├── ConversationView.mc           # Single conversation view with message bubbles
│   ├── SettingsView.mc               # Settings menu (API key, model, clear)
│   ├── ApiKeyInputView.mc            # Multi-segment API key input (10 x 7 chars)
│   └── AboutView.mc                  # About screen with app info
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
- Model: Cycles through available NVIDIA models (shows friendly names)
- System Prompt: View and reset system prompt
- Clear All Chats: Deletes all stored conversations
- About: Shows app version, device, API info

### 5. API Key Input (10 Segments)
- 10 input fields, each accepting 7 characters
- Character counter shows progress (X/70)
- Green indicator when key is complete
- Save button enabled when any characters entered

### 6. Quick Prompts
- Tap "+ New" button to show quick prompt templates
- 6 templates: Translate, Summarize, Explain, Weather, Joke, Timer
- Tap a template to start conversation with pre-filled text

### 7. Conversation View Features
- Tap title to rename conversation
- Tap message count to clear conversation
- Retry button on failed requests
- Cancel button during loading
- Haptic feedback on send/receive/error

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

# Using build script (recommended)
./build.sh                    # Build watch app
./build.sh vivoactive5 full   # Build with phone app
./build.sh vivoactive5 watch run  # Build and run in simulator

# Manual build
monkeyc -w -y developer_key.der -f monkey.jungle -o dist/AIChat.prg -d vivoactive5

# With phone app
monkeyc -w -y developer_key.der -f monkey.jungle -o dist/AIChat.prg \
  -d vivoactive5 \
  source/*.mc phone/source/*.mc \
  -z resources/ -z phone/resources/
```

## Simulator Setup (Important!)

The Connect IQ SDK requires device files to compile and run the simulator. These files are NOT included in the SDK download and must be downloaded separately via the SDK Manager.

### SDK Setup Steps
1. Download SDK from: https://developer.garmin.com/connect-iq/sdk/
2. The SDK manager GUI is required to download device files
3. On Linux, the SDK manager has dependency issues with libsoup2/libsoup3 conflict on Ubuntu 24.04
4. Device files are stored at: `~/.Garmin/ConnectIQ/Devices/`
5. Each device has a folder with `compiler.json`, `simulator.json`, and other files

### Alternative: Use pcolby's AppImage
For Linux systems, use the AppImage versions from https://github.com/pcolby/connectiq-sdk-manager:
```bash
curl -sL https://raw.githubusercontent.com/pcolby/connectiq-sdk-manager/main/install.sh | bash -r
```
This installs AppImages at `~/.Garmin/ConnectIQ/AppImages/`

### Running the Simulator
```bash
# Start Xvfb for headless display
Xvfb :99 -screen 0 1920x1080x24 &
export DISPLAY=:99

# Run simulator with AppImage
~/.Garmin/ConnectIQ/AppImages/Connect_IQ_Simulator-9.1.0+159-x86_64.AppImage --appimage-extract-and-run

# Or use monkeydo with SDK
export CONNECTIQ_SDK_DIR=/path/to/connectiq-sdk
$CONNECTIQ_SDK_DIR/bin/monkeydo dist/AIChat.prg vivoactive5
```

### Known SDK Issues on Ubuntu 24.04
- SDK manager crashes due to libsoup2/libsoup3 conflict
- Workaround: Use pcolby's AppImage which bundles dependencies
- Device files require authentication to download from Garmin API
- Manual device file creation is possible but complex (requires specific JSON structure)

## Bugs Fixed

### v1.2.1 - Critical Bug Fixes
1. **Missing onSendComplete method in MessageInputView**: The `SendCallback` class was calling `view.onSendComplete(response, error)` but this method didn't exist in `MessageInputView`. This caused a runtime crash when the API response was received. Fixed by adding the method.

2. **Empty try-catch blocks**: Removed empty try-catch blocks in:
   - `MessageInputView.sendMessage()` (lines 157-160)
   - `ConversationView.onSendComplete()` (lines 356-359, 368-371)
   These were likely leftover from removed code and served no purpose.

## Next Steps for Future Self

### Completed Features (v1.2.0)
- ~~Error Recovery~~: Retry button added for failed API requests
- ~~Conversation Rename~~: Tap title in conversation view to rename
- ~~Delete Single Conversation~~: Swipe-to-delete implemented
- ~~System Prompt~~: Customizable system prompt in settings
- ~~Haptic Feedback~~: Vibrate on send (100ms), receive (100ms), error (200ms)
- ~~Conversation Stats~~: Message count displayed in header
- ~~Quick Replies~~: 6 quick prompt templates (Translate, Summarize, Explain, etc.)
- ~~Cancel Request~~: Cancel button during loading
- ~~Clear Conversation~~: Tap message count to clear current conversation
- ~~About View~~: App info screen with version, device, API details
- ~~Phone API Key Input~~: Fixed broken text input in phone app
- ~~Build Script~~: build.sh with watch/full/simulator modes
- ~~Friendly Model Names~~: Settings shows "Llama 3.1 70B" instead of full ID

### Priority 1 - Must Have
1. **Streaming Responses**: Implement streaming for faster perceived response time (SDK limitation may apply)
2. **Proper Launcher Icon**: Create a 48x48 PNG icon for the app
3. **Conversation Export**: Export conversations as text files

### Priority 2 - Should Have
4. **Conversation Search**: Search through past conversations
5. **Message Editing**: Edit sent messages before resending
6. **Copy Response**: Long-press to copy assistant responses
7. **Timeout Configuration**: Configurable request timeout

### Priority 3 - Nice to Have
8. **Temperature Control**: Adjust creativity/temperature per conversation
9. **Max Tokens Setting**: Configurable response length
10. **Voice Input**: Use watch microphone for voice-to-text
11. **Offline Queue**: Queue messages when offline, send when connected
12. **Response Caching**: Cache frequent responses

### Priority 4 - Polish
13. **Animations**: Smooth transitions between views
14. **Dark/Light Theme**: Theme options
15. **Token Usage Display**: Show estimated token count

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
