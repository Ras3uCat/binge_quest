# Claude AI Integration — Detailed Implementation Guide

## 1. pubspec.yaml
```yaml
dependencies:
  http: ^1.2.0          # or dio if already in use
  rxdart: ^0.27.7       # for streaming state (optional but clean)
```

## 2. AiMessage Model

```dart
// lib/features/ai/models/ai_message_model.dart
import 'package:json_annotation/json_annotation.dart';
part 'ai_message_model.g.dart';

enum AiRole { user, assistant }

@JsonSerializable()
class AiMessageModel {
  final AiRole role;
  final String content;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const AiMessageModel({
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory AiMessageModel.user(String content) => AiMessageModel(
        role: AiRole.user,
        content: content,
        createdAt: DateTime.now(),
      );

  factory AiMessageModel.assistant(String content) => AiMessageModel(
        role: AiRole.assistant,
        content: content,
        createdAt: DateTime.now(),
      );

  Map<String, dynamic> toApiJson() => {
        'role': role.name,
        'content': content,
      };

  factory AiMessageModel.fromJson(Map<String, dynamic> json) =>
      _$AiMessageModelFromJson(json);
  Map<String, dynamic> toJson() => _$AiMessageModelToJson(this);
}
```

## 3. AiResponseModel

```dart
// lib/features/ai/models/ai_response_model.dart
class AiResponseModel {
  final String id;
  final String content;
  final String model;
  final int inputTokens;
  final int outputTokens;

  const AiResponseModel({
    required this.id,
    required this.content,
    required this.model,
    required this.inputTokens,
    required this.outputTokens,
  });

  factory AiResponseModel.fromJson(Map<String, dynamic> json) {
    final contentBlock = (json['content'] as List).first as Map<String, dynamic>;
    final usage = json['usage'] as Map<String, dynamic>;
    return AiResponseModel(
      id: json['id'] as String,
      content: contentBlock['text'] as String,
      model: json['model'] as String,
      inputTokens: usage['input_tokens'] as int,
      outputTokens: usage['output_tokens'] as int,
    );
  }
}
```

## 4. Prompt Templates

```dart
// lib/features/ai/prompts/system_prompt.dart
const String kSystemPrompt = '''
You are a helpful, concise assistant embedded in [App Name].

Guidelines:
- Be direct and practical
- Format responses with markdown when helpful
- If you don't know something, say so
- Stay focused on the user's actual question
''';

// lib/features/ai/prompts/chat_prompts.dart
String buildContextPrompt({
  required String userContext,
  required String question,
}) => '''
Context about the user: $userContext

User question: $question
''';
```

## 5. AiService — Non-Streaming + Streaming

```dart
// lib/features/ai/services/ai_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config/app_config.dart';
import '../models/ai_message_model.dart';
import '../models/ai_response_model.dart';
import '../prompts/system_prompt.dart';

class AiService {
  static const _baseUrl = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-sonnet-4-6';
  static const _anthropicVersion = '2023-06-01';

  Map<String, String> get _headers => {
        'x-api-key': AppConfig.anthropicApiKey,
        'anthropic-version': _anthropicVersion,
        'content-type': 'application/json',
      };

  /// Standard (non-streaming) call — use for short, single-turn requests
  Future<AiResponseModel> sendMessage({
    required List<AiMessageModel> history,
    int maxTokens = 1024,
  }) async {
    final body = jsonEncode({
      'model': _model,
      'max_tokens': maxTokens,
      'system': kSystemPrompt,
      'messages': history.map((m) => m.toApiJson()).toList(),
    });

    final res = await http.post(
      Uri.parse(_baseUrl),
      headers: _headers,
      body: body,
    );

    if (res.statusCode != 200) {
      final error = jsonDecode(res.body);
      throw AiException(
        error['error']['message'] as String? ?? 'Unknown error',
        type: error['error']['type'] as String?,
      );
    }

    return AiResponseModel.fromJson(jsonDecode(res.body));
  }

  /// Streaming call — yields text chunks as they arrive (chat UX)
  Stream<String> streamMessage({
    required List<AiMessageModel> history,
    int maxTokens = 1024,
  }) async* {
    final body = jsonEncode({
      'model': _model,
      'max_tokens': maxTokens,
      'system': kSystemPrompt,
      'stream': true,
      'messages': history.map((m) => m.toApiJson()).toList(),
    });

    final request = http.Request('POST', Uri.parse(_baseUrl))
      ..headers.addAll({..._headers, 'accept': 'text/event-stream'})
      ..body = body;

    final response = await http.Client().send(request);

    await for (final chunk in response.stream.transform(utf8.decoder)) {
      for (final line in chunk.split('\n')) {
        if (!line.startsWith('data: ')) continue;
        final data = line.substring(6).trim();
        if (data == '[DONE]') return;

        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          if (json['type'] == 'content_block_delta') {
            final delta = json['delta'] as Map<String, dynamic>;
            if (delta['type'] == 'text_delta') {
              yield delta['text'] as String;
            }
          }
        } catch (_) {
          // Skip malformed chunks
        }
      }
    }
  }
}

class AiException implements Exception {
  final String message;
  final String? type;
  const AiException(this.message, {this.type});

  @override
  String toString() => 'AiException($type): $message';
}
```

## 6. AiController

```dart
// lib/controllers/ai_controller.dart
import 'package:get/get.dart';
import '../core/base/base_controller.dart';
import '../features/ai/models/ai_message_model.dart';
import '../features/ai/services/ai_service.dart';

class AiController extends BaseController {
  final _service = AiService();

  final messages = <AiMessageModel>[].obs;
  final streamingResponse = ''.obs;
  final isStreaming = false.obs;

  // Token tracking
  final totalInputTokens = 0.obs;
  final totalOutputTokens = 0.obs;

  // Context window safety — trim history if getting long
  static const _maxHistoryLength = 20;

  Future<void> sendMessage(String userText) async {
    if (userText.trim().isEmpty) return;

    // Add user message
    messages.add(AiMessageModel.user(userText));
    _trimHistory();

    isStreaming.value = true;
    streamingResponse.value = '';
    clearError();

    try {
      await for (final chunk in _service.streamMessage(history: messages)) {
        streamingResponse.value += chunk;
      }

      // Commit streamed response to history
      if (streamingResponse.value.isNotEmpty) {
        messages.add(AiMessageModel.assistant(streamingResponse.value));
      }
    } on AiException catch (e) {
      setError(_friendlyError(e));
      // Remove the user message that failed
      messages.removeLast();
    } finally {
      isStreaming.value = false;
      streamingResponse.value = '';
    }
  }

  void clearConversation() {
    messages.clear();
    streamingResponse.value = '';
    clearError();
  }

  void _trimHistory() {
    if (messages.length > _maxHistoryLength) {
      // Keep system context by removing oldest user/assistant pairs
      messages.removeRange(0, messages.length - _maxHistoryLength);
    }
  }

  String _friendlyError(AiException e) => switch (e.type) {
        'overloaded_error' => 'Claude is busy right now. Please try again.',
        'rate_limit_error' => 'Too many requests. Please wait a moment.',
        'invalid_api_key' => 'API key error. Contact support.',
        _ => 'Something went wrong. Please try again.',
      };
}
```

## 7. AiChatView (Streaming UI)

```dart
// lib/features/ai/views/ai_chat_view.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/ai_controller.dart';
import '../../../core/theme/e_colors.dart';
import '../../../core/theme/e_spacing.dart';
import '../../../core/theme/e_text_styles.dart';

class AiChatView extends GetView<AiController> {
  const AiChatView({super.key});

  @override
  Widget build(BuildContext context) {
    final inputCtrl = TextEditingController();

    return Scaffold(
      backgroundColor: EColors.background,
      appBar: AppBar(
        title: const Text('AI Assistant', style: ETextStyles.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.clearConversation,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              final msgs = controller.messages;
              final streaming = controller.streamingResponse.value;
              final total = msgs.length + (streaming.isNotEmpty ? 1 : 0);

              return ListView.builder(
                padding: const EdgeInsets.all(ESpacing.md),
                itemCount: total,
                itemBuilder: (_, i) {
                  if (i == msgs.length && streaming.isNotEmpty) {
                    return _MessageBubble(
                      content: streaming,
                      isUser: false,
                      isStreaming: true,
                    );
                  }
                  final msg = msgs[i];
                  return _MessageBubble(
                    content: msg.content,
                    isUser: msg.role == AiRole.user,
                  );
                },
              );
            }),
          ),
          _InputBar(ctrl: inputCtrl, onSend: (text) {
            controller.sendMessage(text);
            inputCtrl.clear();
          }),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String content;
  final bool isUser;
  final bool isStreaming;

  const _MessageBubble({
    required this.content,
    required this.isUser,
    this.isStreaming = false,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: ESpacing.xs),
        padding: const EdgeInsets.all(ESpacing.md),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? EColors.primary.withOpacity(0.2) : EColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUser ? EColors.primary : EColors.surfaceAlt,
          ),
        ),
        child: Text(
          isStreaming ? '$content▋' : content,
          style: ETextStyles.body,
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final void Function(String) onSend;

  const _InputBar({required this.ctrl, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(ESpacing.md),
      decoration: BoxDecoration(
        color: EColors.surface,
        border: Border(top: BorderSide(color: EColors.surfaceAlt)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: ctrl,
              style: ETextStyles.body,
              decoration: const InputDecoration(
                hintText: 'Ask anything...',
                border: InputBorder.none,
              ),
              onSubmitted: onSend,
            ),
          ),
          GetX<AiController>(
            builder: (c) => IconButton(
              onPressed: c.isStreaming.value
                  ? null
                  : () => onSend(ctrl.text),
              icon: c.isStreaming.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send, color: EColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}
```

## 8. AppConfig — Add Anthropic Key

```dart
// lib/config/app_config.dart (add to existing)
static String get anthropicApiKey =>
    const String.fromEnvironment('ANTHROPIC_API_KEY');
```

```bash
# Run with key injected at build time (never commit the key)
flutter run --dart-define=ANTHROPIC_API_KEY=sk-ant-...
```
