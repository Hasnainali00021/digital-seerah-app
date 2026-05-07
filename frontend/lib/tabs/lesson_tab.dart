import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:seerah_timeline/constants/app_colors.dart';
import 'package:seerah_timeline/screen/lesson_detail_screen.dart';
import 'package:seerah_timeline/widget/custom_back_button.dart';

class LessonTab extends StatefulWidget {
  const LessonTab({super.key});

  @override
  State<LessonTab> createState() => _LessonTabState();
}

class _LessonTabState extends State<LessonTab> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> lessonEvents = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLessonEvents();
  }

  Future<void> _fetchLessonEvents() async {
    try {
      final response = await supabase
          .from('timeline_events')
          .select('title, lessons')
          .order('order_index', ascending: true);

      final List<Map<String, dynamic>> data = List<Map<String, dynamic>>.from(response);

      // Filter events that actually have lessons
      final filtered = data.where((e) {
        final l = e['lessons'];
        return l != null && (l is List) && l.isNotEmpty;
      }).toList();

      setState(() {
        lessonEvents = filtered;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching lessons: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? const Color(0xFF121212) : AppColors.scaffoldBackground;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final titleColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white70 : Colors.grey[600];

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (lessonEvents.isEmpty) {
      return const Center(child: Text("No lessons available."));
    }

    return Scaffold(
        backgroundColor: background,
        appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF1A1A1A) : AppColors.scaffoldBackground,
            scrolledUnderElevation: 0,
            elevation: 0,
            leading: const CustomBackButton(),
            title: RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                children: [
                  TextSpan(
                    text: 'Lessons & ',
                    style: TextStyle(color: AppColors.primary),
                  ),
                  TextSpan(
                    text: 'Wisdom',
                    style: TextStyle(color: AppColors.accent),
                  ),
                ],
              ),
            ),
            automaticallyImplyLeading: false,
            centerTitle: true,
        ),
        body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: lessonEvents.length,
            itemBuilder: (context, index) {
                final event = lessonEvents[index];
                final title = event['title'] ?? 'Untitled';
                final lessons = (event['lessons'] as List<dynamic>).map((e) => e.toString()).toList();

                return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: cardColor,
                    child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(isDark ? 0.18 : 0.1),
                                shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.menu_book, color: AppColors.primary),
                        ),
                        title: Text(
                            title,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Noto Nastaliq Urdu', color: titleColor),
                        ),
                        onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => LessonDetailScreen(title: title, lessons: lessons),
                                ),
                            );
                        },
                    ),
                );
            },
        ),
    );
  }
}
