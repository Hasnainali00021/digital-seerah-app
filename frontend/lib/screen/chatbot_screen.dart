import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:seerah_timeline/constants/app_colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:seerah_timeline/constants/app_colors.dart';
import 'package:seerah_timeline/widget/custom_back_button.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();

  final List<String> _suggestions = const [
    'Incident of Taif',
    'Battle of Badr',
    'Lessons and Wisdom',
    'Life of Prophet Muhammad(P.B.U.H)',
    "Isra and Mi'raj",
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? const Color(0xFF121212) : AppColors.scaffoldBackground;
    final mainText = isDark ? Colors.white : Colors.black87;
    final subText = isDark ? Colors.white70 : Colors.grey[400];

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : AppColors.scaffoldBackground,
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
            // Scrollable content area
            Expanded(
              child: SingleChildScrollView(
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Iconsax.message_question,
                            color: Colors.white,
                            size: 20,
                          ),
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
                              Icon(
                                Iconsax.magic_star,
                                color: Colors.white,
                                size: 18,
                              ),
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
                                    onTap: () =>
                                        setState(() => _controller.text = s),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.white24,
                                        ),
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
              ),
            ),

            // Bottom input row pinned to screen bottom
            SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: isDark ? Colors.black54 : Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _controller,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: InputDecoration(
                          hintText: 'Search a topic...',
                          hintStyle: TextStyle(
                            color: subText,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Iconsax.microphone_2,
                                color: isDark ? Colors.white70 : Colors.grey[500],
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                            ],
                          ),
                        ),
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _onSend(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: _onSend,
                    borderRadius: BorderRadius.circular(26),
                    child: Container(
                      width: 46,
                      height: 46,
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

  void _onSend() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    // 1. Show Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      // 2. Clear input
      _controller.clear();
      FocusScope.of(context).unfocus();

      // 3. Make API Call (Uses host LAN IP: works for BOTH Emulator & Physical Device!)
      final url = Uri.parse('http://192.168.100.56:3000/api/chat/query');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': query}),
      );

      // 4. Close Loading
      Navigator.of(context).pop();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final answer = data['answer'] ?? 'No answer received.';
        final sources = data['sources'] as List?;

        // 5. Show Response
        _showAnswerDialog(query, answer, sources);
      } else {
        String errorMessage = 'Server Error: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['answer'] != null) {
            errorMessage = errorData['answer'];
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'];
          }
        } catch (_) {}
        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      // Close loading if open
      if (Navigator.canPop(context)) Navigator.of(context).pop();
      _showErrorDialog('Connection Failed: $e');
    }
  }

  void _showAnswerDialog(String query, String answer, List? sources) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final primaryText = isDark ? Colors.white : Colors.black87;
    final secondaryText = isDark ? Colors.white70 : Colors.grey;
    final sourceCardColor = isDark ? const Color(0xFF2A2A2A) : Colors.grey[50]!;
    final sourceBorderColor = isDark ? Colors.white12 : Colors.grey[200]!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: sheetColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Question
            Text(
              query,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryText,
              ),
            ),
            const Divider(height: 30),

            // Answer Scrollable
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      answer,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: secondaryText,
                      ),
                      textAlign: TextAlign.right, // Assuming Urdu/RTL
                      textDirection: TextDirection.rtl,
                    ),

                    if (sources != null && sources.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        '📚 Sources Used:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...sources
                          .map(
                            (s) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: sourceCardColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: sourceBorderColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s['heading'] ?? 'Unknown Section',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: primaryText,
                                    ),
                                  ),
                                  Builder(
                                    builder: (context) {
                                      var refs = s['references'];
                                      String validRef = '';

                                      // 1. Try to extract references safely
                                      if (refs != null &&
                                          refs is List &&
                                          refs.isNotEmpty) {
                                        validRef = refs
                                            .map((e) => e.toString())
                                            .join(', ');
                                      } else if (refs != null &&
                                          refs is String &&
                                          refs.isNotEmpty) {
                                        validRef = refs;
                                      }

                                      // 2. Fallback: Show Book Name only (Remove Page number as requested)
                                      if (validRef.isEmpty) {
                                        validRef =
                                            s['book'] ?? 'Source Reference';
                                      }

                                      return Text(
                                        validRef,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: secondaryText,
                                        ),
                                        textDirection: TextDirection
                                            .rtl, // Better for Urdu
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
