# Changelog

All notable changes to the Garmin AI Chat app.

## [1.2.0] - 2026-05-18

### Added
- Quick prompt templates (Translate, Summarize, Explain, Weather, Joke, Timer)
- Cancel button during API requests
- Retry button on failed requests
- Conversation rename (tap title)
- Clear conversation (tap message count)
- Message count display in conversation header
- Haptic feedback on send, receive, and error
- About view with app info
- Build script (build.sh) with watch/full/simulator modes
- Friendly model names in settings (e.g., "Llama 3.1 70B")
- HTTP response type specification for better parsing

### Fixed
- Phone app API key input was empty (tapping did nothing)
- Loading animation starting on ConversationView layout
- Double-remove bug in conversation eviction (PropertyStore)
- Removed spurious loading animation on view creation

### Changed
- Version bumped to 1.2.0
- monkey.jungle improved with proper sections
- Documentation updated with all new features

## [1.1.0] - Previous

### Added
- System prompt support
- Swipe-to-delete conversations
- Improved error messages for HTTP codes
- Memory limits (20 conversations, 30 messages each)
- API key segment bounds checking
- Null safety throughout

### Fixed
- SDK API migrations (Rez.Strings, makeWebRequest, delegate patterns)
- Storage bug in MessageInputView
- Time API usage in Message.mc
- getInitialView() return format

## [1.0.0] - Initial

- Basic conversation list
- Message input and sending
- Conversation view with bubbles
- Settings (API key, model)
- Phone companion app
- NVIDIA API integration
