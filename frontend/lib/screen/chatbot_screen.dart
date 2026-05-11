import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:seerah_timeline/constants/app_colors.dart';
import 'package:seerah_timeline/widget/custom_back_button.dart';
import 'package:seerah_timeline/providers/chatbot_provider.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class ChatbotScreen extends ConsumerStatefulWidget {
  const ChatbotScreen({super.key});

  @override
  ConsumerState<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends ConsumerState<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _isTranscribing = false;
  String? _selectedLanguage; // 'en' or 'ur'

  final List<String> _suggestions = const [
    'Incident of Taif',
    'Battle of Badr',
    'Lessons and Wisdom',
    'Life of Prophet Muhammad(P.B.U.H)',
    "Isra and Mi'raj",
  ];

  @override
  void dispose() {
    _recorder.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _listen() async {
    // If already recording, stop and transcribe
    if (_isRecording) {
      await _stopAndTranscribe();
      return;
    }

    // If transcribing, don't allow another tap
    if (_isTranscribing) return;

    // Show language picker
    final language = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Select Voice Language',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
                title: Text(
                  'English',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                tileColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                onTap: () => Navigator.pop(ctx, 'en'),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Text('🇵🇰', style: TextStyle(fontSize: 24)),
                title: Text(
                  'اردو (Urdu)',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                tileColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey[100],
                onTap: () => Navigator.pop(ctx, 'ur'),
              ),
            ],
          ),
        );
      },
    );

    if (language == null) return;
    _selectedLanguage = language;

    // Check microphone permission
    if (!await _recorder.hasPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied')),
        );
      }
      return;
    }

    // Start recording
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/voice_input.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: filePath,
    );

    setState(() => _isRecording = true);
    print('🎤 Recording started ($language)...');
  }

  Future<void> _stopAndTranscribe() async {
    final path = await _recorder.stop();
    setState(() {
      _isRecording = false;
      _isTranscribing = true;
    });
    print('🎤 Recording stopped. File: $path');

    if (path == null) {
      setState(() => _isTranscribing = false);
      return;
    }

    try {
      // Read audio file and encode to base64
      final audioBytes = await File(path).readAsBytes();
      final base64Audio = base64Encode(audioBytes);
      print('🎤 Audio size: ${audioBytes.length} bytes, sending to Gemini...');

      // Send to backend for Gemini transcription
      final url = Uri.parse(
        'https://digital-seerah-app.onrender.com/api/speech/transcribe',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'audio': base64Audio,
          'mimeType': 'audio/aac',
          'language': _selectedLanguage ?? 'en',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = (data['text'] ?? '').toString().trim();
        if (text.isNotEmpty && mounted) {
          setState(() {
            _controller.text = text;
            _controller.selection = TextSelection.fromPosition(
              TextPosition(offset: _controller.text.length),
            );
          });
          print('✅ Transcription received: $text');
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Could not understand the audio. Please try again.',
                ),
              ),
            );
          }
        }
      } else {
        print('❌ Transcription API error: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Transcription failed (${response.statusCode})'),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Transcription error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isTranscribing = false);
      // Clean up temp file
      try {
        await File(path).delete();
      } catch (_) {}
    }
  }

  void _onSend([String? prefilledQuery]) {
    final query = prefilledQuery ?? _controller.text.trim();
    if (query.isEmpty) return;

    if (prefilledQuery == null) {
      _controller.clear();
    }

    FocusScope.of(context).unfocus();

    // Call Provider to handle sendMessage
    ref.read(chatbotProvider.notifier).sendMessage(query);

    // Scroll to bottom after message added
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? const Color(0xFF121212)
        : AppColors.scaffoldBackground;
    final mainText = isDark ? Colors.white : Colors.black87;
    final subText = isDark ? Colors.white70 : Colors.grey[400];

    final chatState = ref.watch(chatbotProvider);
    final messages = chatState.messages;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: isDark
            ? const Color(0xFF1A1A1A)
            : AppColors.scaffoldBackground,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        leading: const CustomBackButton(),
        title: RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            children: [
              TextSpan(
                text: 'Chatbot ',
                style: TextStyle(color: AppColors.primary),
              ),
              TextSpan(
                text: 'AI',
                style: TextStyle(color: AppColors.accent),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable content area / Messages
            Expanded(
              child: messages.isEmpty
                  ? _buildEmptyState(isDark)
                  : _buildMessageList(messages, isDark),
            ),

            if (chatState.isLoading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),

            // Bottom input row pinned to screen bottom
            SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black54
                                : Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _controller,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        minLines: 1,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'Search a topic...',
                          hintStyle: TextStyle(color: subText, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: _isTranscribing ? null : _listen,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _isRecording
                                        ? Colors.red.withOpacity(0.1)
                                        : _isTranscribing
                                        ? Colors.orange.withOpacity(0.1)
                                        : Colors.transparent,
                                    shape: BoxShape.circle,
                                  ),
                                  child: _isTranscribing
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Icon(
                                          _isRecording
                                              ? Iconsax.stop
                                              : Iconsax.microphone_2,
                                          color: _isRecording
                                              ? Colors.red
                                              : (isDark
                                                    ? Colors.white70
                                                    : Colors.grey[500]),
                                          size: 20,
                                        ),
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                          ),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _onSend(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () => _onSend(),
                    borderRadius: BorderRadius.circular(26),
                    child: Container(
                      width: 46,
                      height: 46,
                      margin: const EdgeInsets.only(
                        bottom: 2,
                      ), // align with center of 1-line textfield
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Iconsax.send_1,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Centered round logo using asset
          Center(
            child: Image.asset(
              'assets/images/login_logo_cropped.png',
              width: 100,
              height: 100,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 40),
          // Orange welcome/info message
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Iconsax.message_question, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Hi, you can ask me anything about Seerat un Nabi (P.B.U.H)! Just type your question below',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Suggestions title + list container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            decoration: BoxDecoration(
              color: const Color(0xFF0D9488),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Iconsax.magic_star, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'I suggest you some names you can ask me..',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _suggestions
                      .map(
                        (s) => GestureDetector(
                          onTap: () => _onSend(s), // Now sends immediately
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Text(
                              s,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(List<ChatMessage> messages, bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[index];
        return _buildChatBubble(msg, isDark);
      },
    );
  }

  Widget _buildRichText(
    String text,
    bool isEnglishTxt,
    bool isUser,
    bool isDark,
    bool isError,
  ) {
    final parts = text.split('**');
    final spans = <TextSpan>[];
    final defaultStyle = TextStyle(
      color: isUser || isError
          ? Colors.white
          : (isDark ? Colors.white : Colors.black87),
      fontSize: 16,
    );

    for (int i = 0; i < parts.length; i++) {
      if (i % 2 == 1) {
        // Bold
        spans.add(
          TextSpan(
            text: parts[i],
            style: defaultStyle.copyWith(fontWeight: FontWeight.bold),
          ),
        );
      } else {
        // Normal
        spans.add(TextSpan(text: parts[i], style: defaultStyle));
      }
    }

    return RichText(
      textAlign: isEnglishTxt ? TextAlign.left : TextAlign.right,
      textDirection: isEnglishTxt ? TextDirection.ltr : TextDirection.rtl,
      text: TextSpan(children: spans),
    );
  }

  Widget _buildChatBubble(ChatMessage message, bool isDark) {
    final isUser = message.isUser;

    // Use regex logic to detect if message is English to align correctly
    final isEnglishTxt = RegExp(r'[a-zA-Z]').hasMatch(message.text);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.primary
              : (message.isError
                    ? Colors.redAccent
                    : (isDark ? const Color(0xFF2A2A2A) : Colors.white)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRichText(
              message.text,
              isEnglishTxt,
              isUser,
              isDark,
              message.isError,
            ),
            if (message.isStreaming) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Typing...',
                    style: TextStyle(fontSize: 12, color: AppColors.primary),
                  ),
                ],
              ),
            ],
            if (message.sources != null && message.sources!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 4),
              const Text(
                '📚 Sources:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              ...message.sources!.map((s) {
                String validRef = '';
                var refs = s['references'];
                if (refs != null && refs is List && refs.isNotEmpty) {
                  validRef = refs.map((e) => e.toString()).join(', ');
                } else if (refs != null && refs is String && refs.isNotEmpty) {
                  validRef = refs;
                }
                if (validRef.isEmpty) {
                  validRef = s['book'] ?? 'Source Reference';
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    '- ${s['heading'] ?? 'Unknown Section'}: $validRef',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }
}
