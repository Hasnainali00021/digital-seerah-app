import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seerah_timeline/widget/app_search_bar.dart';
import 'package:seerah_timeline/widget/custom_appbar.dart';
import '../constants/app_colors.dart';
import '../providers/providers.dart';
import '../widget/timeline_card.dart';

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onCategorySelected(String category) {
    ref.read(selectedCategoryProvider.notifier).state = category;
  }
  
  void _onSearchQueryChanged(String query) {
    ref.read(searchQueryProvider.notifier).state = query;
  }

  // 🔹 Builds the timeline layout with line, circle, and card
  Widget buildTimelineItem(BuildContext context, Widget card) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        // 🟢 Vertical Line
        Positioned(
          left: 22,
          top: 0,
          bottom: 0,
          child: Container(width: 3, color: Colors.teal.shade300),
        ),

        // ⚪ Circle Marker
        Positioned(
          left: 15,
          top: 25,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.teal.shade400, width: 2),
              shape: BoxShape.circle,
            ),
          ),
        ),

        // 📘 Timeline Card
        Padding(padding: const EdgeInsets.only(left: 40), child: card),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final asyncEvents = ref.watch(timelineEventsProvider);
    final filteredEvents = ref.watch(filteredEventsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppColors.scaffoldBackground,
      appBar: CustomAppbar(titleOne: "Seerah ", titleTwo: "Timeline"),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 5),
        child: Column(
          children: [
            // 🔍 Search Bar
            AppSearchBar(
              hintText: "Search Events, Places", 
              onChanged: _onSearchQueryChanged,
               controller: _searchController
               ),
            const SizedBox(height: 16),

            // 🔹 Filter Buttons Row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterButton("All", selectedCategory == "All"),
                  _buildFilterButton(
                    "Pre-Prophethood",
                    selectedCategory == "Pre-Prophethood",
                  ),
                  _buildFilterButton("Makkah", selectedCategory == "Makkah"),
                  _buildFilterButton("Madina", selectedCategory == "Madina"),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 🔹 Timeline Cards with Line and Circles
            Expanded(
              child: asyncEvents.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(error.toString(), style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(timelineEventsProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (_) {
                  if (filteredEvents.isEmpty) {
                    return const Center(child: Text('No events found'));
                  }
                  return ListView.builder(
                    itemCount: filteredEvents.length,
                    itemBuilder: (context, index) {
                      final event = filteredEvents[index];
                      
                      final refs = (event['references'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
                      final less = (event['lessons'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

                      return buildTimelineItem(
                        context,
                        TimelineCard(
                          id: event['id'].toString(), 
                          year: event['year'] ?? '',
                          title: event['title'] ?? 'Untitled',
                          description: event['short_description'] ?? '',
                          imageUrl: event['image_url'],
                          fullDescription: event['full_description'],
                          category: event['category'],
                          references: refs,
                          lessons: less,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔘 Filter Button Builder
  Widget _buildFilterButton(String text, bool selected) {
    final isDark = false; // accessed from context if needed — buttons are always teal when selected
    return GestureDetector(
      onTap: () => _onCategorySelected(text),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
