import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seerah_timeline/constants/app_colors.dart';
import 'package:seerah_timeline/screen/active_quiz_screen.dart';
import 'package:seerah_timeline/widget/custom_back_button.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({Key? key}) : super(key: key);

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('quiz_history') ?? [];
    setState(() {
      _history = list.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
      // Sort by date ascending (oldest first)
      _history.sort((a, b) {
          DateTime dateA = DateTime.tryParse(a['date'] ?? '') ?? DateTime(2000);
          DateTime dateB = DateTime.tryParse(b['date'] ?? '') ?? DateTime(2000);
          return dateA.compareTo(dateB); 
      });
      _isLoading = false;
    });
  }
  
  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('quiz_history');
    setState(() {
      _history = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final mainText = isDark ? Colors.white : Colors.black87;
    final subText = isDark ? Colors.white70 : Colors.grey[600];
    final emptyText = isDark ? Colors.white70 : Colors.black54;
    final hintText = isDark ? Colors.white60 : Colors.grey;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : AppColors.scaffoldBackground,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        leading: const CustomBackButton(),
        title: RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            children: [
              TextSpan(
                text: 'My Quiz ',
                style: TextStyle(color: AppColors.primary),
              ),
              TextSpan(
                text: 'History',
                style: TextStyle(color: AppColors.accent),
              ),
            ],
          ),
        ),
        actions: [
            if (_history.isNotEmpty)
            IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: _clearHistory,
            )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _history.isEmpty 
            ? _buildEmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _history.length,
                itemBuilder: (context, index) {
                  final item = _history[index];
                  final int percentage = item['percentage'] ?? 0;
                  final Color scoreColor = percentage >= 80 ? Colors.green : (percentage >= 50 ? Colors.orange : Colors.red);
                  
                  return Dismissible(
                    key: Key(item['date'] ?? index.toString()),
                    direction: DismissDirection.startToEnd,
                    background: Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.delete, color: Colors.white, size: 30),
                    ),
                    onDismissed: (direction) async {
                      setState(() {
                        _history.removeAt(index);
                      });
                      
                      // Update SharedPreferences
                      final prefs = await SharedPreferences.getInstance();
                      // We need to re-encode the whole list because we removed an item
                      // Note: The _history list contains Maps, but SharedPreferences stores Strings (JSON)
                      // So we map it back to JSON strings.
                      // IMPORTANT: _history was already sorted! Saving it back will keep it sorted.
                      final updatedList = _history.map((e) => jsonEncode(e)).toList();
                      await prefs.setStringList('quiz_history', updatedList);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Quiz removed from history"), duration: Duration(seconds: 2)),
                      );
                    },
                    child: Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: cardColor,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Score Circle
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: scoreColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  "$percentage%",
                                  style: TextStyle(
                                    fontSize: 18, 
                                    fontWeight: FontWeight.bold,
                                    color: scoreColor
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title'] ?? 'Unknown Quiz',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: mainText
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Answered ${item['score']} / ${item['total']} correctly",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: subText
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Retake Button
                            if (item['content'] != null)
                               TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ActiveQuizScreen(
                                          eventTitle: item['title'],
                                          eventContent: item['content'],
                                        ),
                                      ),
                                    ).then((_) => _loadHistory()); // Reload history when back
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF0D9488),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    backgroundColor: const Color(0xFF0D9488).withOpacity(0.1)
                                  ),
                                  child: const Text("Retake", style: TextStyle(fontWeight: FontWeight.bold)),
                               )
                            else
                              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headingColor = isDark ? Colors.white : Colors.black54;
    final bodyColor = isDark ? Colors.white70 : Colors.grey;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0D9488).withOpacity(0.1),
              shape: BoxShape.circle
            ),
            child: const Icon(Icons.quiz_outlined, size: 60, color: Color(0xFF0D9488)),
          ),
          const SizedBox(height: 20),
          const Text(
            "No Quizzes Taken Yet",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Read stories in the timeline and take quizzes to test your knowledge!",
              textAlign: TextAlign.center,
              style: TextStyle(color: bodyColor),
            ),
          )
        ],
      ),
    );
  }
}