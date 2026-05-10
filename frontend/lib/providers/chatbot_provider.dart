import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:translator/translator.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isStreaming;
  final List? sources;
  final bool isError;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.isStreaming = false,
    this.sources,
    this.isError = false,
  });

  ChatMessage copyWith({
    String? text,
    bool? isUser,
    bool? isStreaming,
    List? sources,
    bool? isError,
  }) {
    return ChatMessage(
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      isStreaming: isStreaming ?? this.isStreaming,
      sources: sources ?? this.sources,
      isError: isError ?? this.isError,
    );
  }
}

class ChatbotState {
  final List<ChatMessage> messages;
  final bool isLoading;

  ChatbotState({
    required this.messages,
    this.isLoading = false,
  });

  ChatbotState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
  }) {
    return ChatbotState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ChatbotNotifier extends StateNotifier<ChatbotState> {
  ChatbotNotifier() : super(ChatbotState(messages: []));

  final _translator = GoogleTranslator();

  // Lightweight detection method
  bool isEnglish(String text) {
    // If it contains mostly English characters, consider it English
    return RegExp(r'[a-zA-Z]').hasMatch(text);
  }

  Future<void> sendMessage(String query) async {
    if (query.trim().isEmpty) return;

    // Add user message
    final userMsg = ChatMessage(text: query, isUser: true);
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
    );

    try {
      bool englishInput = isEnglish(query);
      String queryForDb = query;

      // Pipeline 1: Translate to Urdu if input is English
      if (englishInput) {
        final translated = await _translator.translate(query, from: 'en', to: 'ur');
        queryForDb = translated.text;
      }

      // Query Database
      final url = Uri.parse('http://192.168.100.56:3000/api/chat/query');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': queryForDb}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String answer = data['answer'] ?? 'No answer received.';
        var sources = data['sources'] as List?;

        if (sources != null) {
          final uniqueSources = [];
          final seen = <String>{};
          for (var s in sources) {
            // Deduplicate by stringifying the source content
            final key = '${s['heading']}_${s['book']}_${s['references']}';
            if (!seen.contains(key)) {
              seen.add(key);
              uniqueSources.add(s);
            }
          }
          sources = uniqueSources;
        }

        // Pipeline 2: Translate back to English if input was English
        if (englishInput) {
          final translatedAnswer = await _translator.translate(answer, from: 'ur', to: 'en');
          answer = translatedAnswer.text;
        }

        // Stream the response out
        await _streamResponse(answer, sources);
      } else {
        // Handle error
        String errorMessage = 'Server Error: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['answer'] != null) {
            errorMessage = errorData['answer'];
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'];
          }
        } catch (_) {}
        _addError(errorMessage);
      }
    } catch (e) {
      _addError('Connection Failed: $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _streamResponse(String fullAnswer, List? sources) async {
    // Add an empty bot message that is streaming
    var botMsg = ChatMessage(
        text: '', isUser: false, isStreaming: true, sources: sources);

    state = state.copyWith(
      messages: List.from(state.messages)..add(botMsg),
    );

    // Stream text in chunks to create a typing effect
    final chunks = fullAnswer.split(RegExp(r'(?<=[\s.])'));
    String currentText = '';

    for (var chunk in chunks) {
      await Future.delayed(const Duration(milliseconds: 30)); // Typing speed
      currentText += chunk;

      final messages = List<ChatMessage>.from(state.messages);
      messages[messages.length - 1] = botMsg.copyWith(text: currentText);
      state = state.copyWith(messages: messages);
    }

    // Done streaming
    final finalMessages = List<ChatMessage>.from(state.messages);
    finalMessages[finalMessages.length - 1] =
        botMsg.copyWith(text: currentText, isStreaming: false);
    state = state.copyWith(messages: finalMessages);
  }

  void _addError(String message) {
    final errorMsg = ChatMessage(text: message, isUser: false, isError: true);
    state = state.copyWith(
      messages: [...state.messages, errorMsg],
      isLoading: false,
    );
  }
}

final chatbotProvider = StateNotifierProvider<ChatbotNotifier, ChatbotState>((ref) {
  return ChatbotNotifier();
});
