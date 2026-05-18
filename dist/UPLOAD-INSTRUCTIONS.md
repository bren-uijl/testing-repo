# AI Chat for Garmin - Build & Upload Instructions

## Build the App

### Prerequisites

1. **Connect IQ SDK**: Download from https://developer.garmin.com/connect-iq/sdk/
2. **Connect IQ SDK Manager**: Use it to download device definitions (requires Garmin developer account)
3. **Java 17+**: Required by the SDK
4. **Developer Key**: Generate using the SDK or create with OpenSSL

### Build Steps

```bash
# 1. Install Connect IQ SDK and SDK Manager
# Download from: https://developer.garmin.com/connect-iq/sdk/

# 2. Run SDK Manager to download device definitions
# This requires a Garmin developer account (free to create)
# Download the vivoactive5 device definition

# 3. Set up environment
export CONNECTIQ_SDK=/path/to/connectiq-sdk
export PATH="$CONNECTIQ_SDK/bin:$PATH"

# 4. Navigate to the project
cd garmin-ai-chat

# 5. Build the watch app
monkeyc -w -y developer_key.der -f monkey.jungle -o dist/AIChat.prg -d vivoactive5

# Or build with phone app included
monkeyc -w -y developer_key.der -f monkey.jungle -o dist/AIChat.prg \
  -d vivoactive5 \
  source/*.mc phone/source/*.mc \
  -z resources/ -z phone/resources/
```

### Generate Developer Key

```bash
# Generate a 4096-bit RSA key in DER format
openssl genrsa -out developer_key.pem 4096
openssl pkcs8 -topk8 -nocrypt -in developer_key.pem -outform DER -out developer_key.der
```

## Upload to Watch

### Method 1: Using Garmin Connect IQ Store (Recommended)

1. Create a developer account at https://developer.garmin.com/
2. Submit your app to the Connect IQ Store
3. Users can install it directly from the store on their watch

### Method 2: Sideloading via USB

1. **Build the app** using the steps above to get `AIChat.prg`
2. **Connect your watch** to your computer via USB
3. **Copy the .prg file** to the watch:
   - **Windows**: Copy to `GARMIN/Apps/` on the watch drive
   - **Mac/Linux**: Copy to `/Volumes/GARMIN/Apps/` or `/media/GARMIN/Apps/`
4. **Eject the watch** safely
5. **Restart the watch** (hold power button, select Restart)
6. **Find the app** in your apps menu (look for "AI Chat")

### Method 3: Using Connect IQ SDK Simulator

```bash
# Test in simulator before uploading to watch
monkeydo dist/AIChat.prg vivoactive5
```

### Method 4: Using Garmin Express

1. Install Garmin Express on your computer
2. Connect your watch via USB
3. Use the "Apps" section to sideload custom apps

## Setup After Installation

1. **Open AI Chat** on your watch
2. **Tap the settings icon** (top-right gear)
3. **Enter your API Key**:
   - The app supports any OpenAI-compatible API endpoint
   - Enter your 70-character API key in 10 segments (7 chars each)
   - Or use the phone companion app for easier entry
4. **Select a Model**:
   - Tap "Model" in settings to cycle through available models
   - Supported models:
     - `nvidia/nemotron-nano-9b-v2` (default)
     - `meta/llama-3.1-8b-instruct`
     - `meta/llama-3.1-70b-instruct`
     - `mistralai/mistral-7b-instruct-v0.2`
     - `google/gemma-2-9b-it`
     - `openai/gpt-oss-120b` (new)
     - `openai/gpt-oss-20b` (new)
     - `mistralai/mistral-medium-3.5-128b` (new)

## Supported Models

| Model | Provider | Description |
|-------|----------|-------------|
| nvidia/nemotron-nano-9b-v2 | NVIDIA | Default, fast, good quality |
| meta/llama-3.1-8b-instruct | Meta | Meta's Llama 3.1 8B |
| meta/llama-3.1-70b-instruct | Meta | Meta's Llama 3.1 70B |
| mistralai/mistral-7b-instruct-v0.2 | Mistral AI | Mistral 7B |
| google/gemma-2-9b-it | Google | Google Gemma 2 9B |
| openai/gpt-oss-120b | OpenAI | OpenAI GPT-OSS 120B |
| openai/gpt-oss-20b | OpenAI | OpenAI GPT-OSS 20B |
| mistralai/mistral-medium-3.5-128b | Mistral AI | Mistral Medium 3.5 128B |

## Troubleshooting

### App not showing on watch
- Make sure the .prg file is in `GARMIN/Apps/`
- Restart the watch after copying
- Check that the app ID in manifest.xml matches your developer key

### API key not working
- Verify your API key is 70 characters
- Check that the API endpoint is correct
- Ensure your API key has access to the selected model

### Build fails with "Invalid device id"
- Run the Connect IQ SDK Manager to download device definitions
- Make sure vivoactive5 is downloaded in the SDK Manager

### Build fails with "JungleManager is null"
- The SDK needs device configurations from the SDK Manager
- Run the SDK Manager and download the vivoactive5 device
