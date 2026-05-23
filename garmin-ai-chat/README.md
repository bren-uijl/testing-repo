# AI Chat for Garmin vívoactive 5

A Connect IQ app that brings conversational AI to your wrist, powered by NVIDIA's API.

## Screenshots

_Screenshots coming soon. Capture them from the Connect IQ Simulator:_

1. **Conversation List** — Shows the main screen with quick prompts and saved conversations
2. **Active Conversation** — A chat in progress with message bubbles
3. **Settings** — API key configuration, model selection, and options

## Features

- **Past Conversations**: View and continue previous conversations
- **New Conversations**: Start fresh chats with a single tap
- **Multiple AI Models**: Choose from NVIDIA, Meta, Mistral, and Google models
- **Persistent Storage**: Conversations saved locally on your watch
- **Phone Companion**: Easy API key configuration via phone app
- **Smart API Key Input**: 10-segment input for the 70-character API key

## Requirements

- Garmin vívoactive 5
- Connect IQ SDK 4.x (for building)
- NVIDIA API key (get one at https://build.nvidia.com/)

## Installation

### Pre-built
1. Download the `.prg` file
2. Connect your watch to your computer
3. Copy the `.prg` file to `GARMIN/Apps/` on the watch
4. Disconnect and find AI Chat in your apps menu

### Build from Source
```bash
# Install Connect IQ SDK from https://developer.garmin.com/connect-iq/sdk/
export CONNECTIQ_SDK_DIR=/path/to/connectiq-sdk

# Build watch app
monkeyc -w -y developer_key.der -m manifest.xml -z resources/ -o AIChat.prg source/*.mc

# Build with phone app
monkeyc -w -y developer_key.der -m manifest.xml -m phone/manifest.xml \
  -z resources/ -z phone/resources/ -o AIChat.prg \
  source/*.mc phone/source/*.mc
```

## Setup

1. Open AI Chat on your watch
2. Tap the settings icon (top-right)
3. Select "API Key"
4. Enter your 70-character NVIDIA API key in 10 segments (7 chars each)
5. Or use the phone app for easier entry

## Usage

### Starting a New Conversation
1. From the main screen, tap "+ New"
2. Tap the text input area
3. Type your message using the watch keyboard
4. Tap "Send"

### Continuing a Conversation
1. Tap any conversation from the list
2. Tap "Reply" at the bottom
3. Type your message and send

### Settings
- **API Key**: Configure your NVIDIA API key
- **Model**: Cycle through available AI models
- **Clear All Chats**: Delete all conversations

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

## Project Structure

```
garmin-ai-chat/
├── manifest.xml           # Watch app manifest
├── resources/             # Watch app resources
├── source/                # Watch app source code
│   ├── AiChatApp.mc       # Main app
│   ├── PropertyStore.mc   # Data persistence
│   ├── Message.mc         # Message model
│   ├── Conversation.mc    # Conversation model
│   ├── NviApiClient.mc    # NVIDIA API client
│   ├── ConversationListView.mc
│   ├── MessageInputView.mc
│   ├── ConversationView.mc
│   ├── SettingsView.mc
│   └── ApiKeyInputView.mc
└── phone/                 # Companion phone app
    ├── manifest.xml
    ├── resources/
    └── source/
```

## License

MIT
