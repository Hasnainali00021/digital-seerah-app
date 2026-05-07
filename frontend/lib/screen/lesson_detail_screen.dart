import 'package:flutter/material.dart';
import 'package:seerah_timeline/constants/app_colors.dart';
import 'package:seerah_timeline/widget/custom_back_button.dart';

class LessonDetailScreen extends StatelessWidget {
  final String title;
  final List<String> lessons;

  const LessonDetailScreen({
    super.key,
    required this.title,
    required this.lessons,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? const Color(0xFF121212) : AppColors.scaffoldBackground;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final mainText = isDark ? Colors.white : Colors.black87;
    final subText = isDark ? Colors.white70 : Colors.grey;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : AppColors.scaffoldBackground,
        scrolledUnderElevation: 0,
        elevation: 0,
        title: Text(title, style: TextStyle(color: mainText)),
        centerTitle: true,
        leading: const CustomBackButton(),
      ),
      body: lessons.isEmpty
          ? Center(
              child: Text(
                "No lessons available for this event.",
                style: TextStyle(fontSize: 16, color: subText),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: lessons.length,
              itemBuilder: (context, index) {
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  color: cardColor,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb_outline, color: AppColors.primary, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            lessons[index],
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              fontFamily: 'Noto Nastaliq Urdu',
                              color: mainText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
