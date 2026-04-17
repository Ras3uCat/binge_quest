---
name: claude-ai
description: Anthropic Claude API integration for Flutter apps. Covers Messages API, streaming responses, prompt template management, conversation history, token budgeting, and error handling. Trigger when a task involves AI chat, Claude API calls, prompt engineering, or lib/features/ai/.
when_to_use: Any task involving the Anthropic API, AI chat features, prompt templates, streaming text, conversation history, or the lib/features/ai/ module.
scope: lib/features/ai/, lib/controllers/ai_controller.dart, lib/core/services/ (if AiService lives there)
authority: medium
alwaysApply: false
---

# Claude AI Integration Skill

## Architecture
```
AiService (lib/features/ai/services/ai_service.dart)
  └── All Anthropic API HTTP calls
  └── Streaming response handling
  └── Token counting

AiRepository (lib/features/ai/repositories/ai_repository.dart)
  └── Thin wrapper: passes prompt → AiService → AiResponseModel

AiController (lib/controllers/ai_controller.dart)
  └── Conversation history management
  └── UI state (loading, streaming, error)
  └── Prompt template selection
```

## API Basics
- **Endpoint**: `POST https://api.anthropic.com/v1/messages`
- **Auth header**: `x-api-key: <ANTHROPIC_API_KEY>`
- **Required header**: `anthropic-version: 2023-06-01`
- **Model**: Default to `claude-sonnet-4-6` for balance of speed/quality
- **Never hardcode API key** — load from `AppConfig.anthropicApiKey` (env var)

## Message Format
```json
{
  "model": "claude-sonnet-4-6",
  "max_tokens": 1024,
  "system": "You are a helpful assistant...",
  "messages": [
    {"role": "user", "content": "Hello"},
    {"role": "assistant", "content": "Hi! How can I help?"},
    {"role": "user", "content": "Tell me about GetX"}
  ]
}
```

## Key Rules
- **Conversation history**: Always send full history — Claude has no memory between calls
- **Token budgeting**: Track `input_tokens` + `output_tokens` from response; warn when approaching limits
- **Streaming**: Use SSE (`stream: true`) for chat UX — never wait for full response
- **System prompt**: Load from `lib/features/ai/prompts/system_prompt.dart`, not hardcoded inline
- **Error handling**: Handle `overloaded_error`, `rate_limit_error` with exponential backoff

## Prompt File Convention
```dart
// lib/features/ai/prompts/system_prompt.dart
const String kSystemPrompt = '''
You are a helpful assistant for [App Name].
[Persona, tone, constraints]
''';
```

See `DETAILED_GUIDE.md` for AiService streaming implementation, conversation history
model, token tracking, and the full Dart HTTP client setup.
