import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seerah_timeline/constants/app_colors.dart';
import 'package:seerah_timeline/providers/providers.dart';
import 'package:seerah_timeline/widget/app_search_bar.dart';
import 'package:seerah_timeline/widget/timeline_card.dart';
import 'package:seerah_timeline/widget/custom_back_button.dart';

class MultimediaTab extends ConsumerStatefulWidget {
  const MultimediaTab({super.key});

  @override
  ConsumerState<MultimediaTab> createState() => _MultimediaTabState();
}

class _MultimediaTabState extends ConsumerState<MultimediaTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase().trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildPinnedSearchBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppSearchBar(
        hintText: 'Search media events...',
        onChanged: (value) {},
        controller: _searchController,
      ),
    );
  }

  bool _matchesQuery(Map<String, dynamic> event) {
    if (_searchQuery.isEmpty) return true;

    final title = (event['title'] ?? '').toString().toLowerCase();
    final description = (event['short_description'] ?? '').toString().toLowerCase();
    final fullDescription = (event['full_description'] ?? '').toString().toLowerCase();
    final year = (event['year'] ?? '').toString().toLowerCase();
    final category = (event['category'] ?? '').toString().toLowerCase();

    return title.contains(_searchQuery) ||
        description.contains(_searchQuery) ||
        fullDescription.contains(_searchQuery) ||
        year.contains(_searchQuery) ||
        category.contains(_searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    final asyncEvents = ref.watch(timelineEventsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? const Color(0xFF121212) : AppColors.scaffoldBackground;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: background,
              surfaceTintColor: background,
              elevation: 0,
              centerTitle: true,
              leading: const CustomBackButton(),
              iconTheme: const IconThemeData(color: AppColors.primary),
              title: RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                      text: 'Seerah ',
                      style: TextStyle(color: AppColors.primary),
                    ),
                    TextSpan(
                      text: 'Media',
                      style: TextStyle(color: AppColors.accent),
                    ),
                  ],
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(70),
                child: _buildPinnedSearchBar(),
              ),
            ),
            ...asyncEvents.when(
              loading: () => const [
                SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (error, stack) => [
                SliverFillRemaining(
                  child: Center(child: Text('Error: $error')),
                ),
              ],
              data: (events) {
                final mediaEvents = events.where((event) {
                  final url = (event['image_url'] ?? '').toString().trim();
                  return url.isNotEmpty && _matchesQuery(event);
                }).toList();

                if (mediaEvents.isEmpty) {
                  return const [
                    SliverFillRemaining(
                      child: Center(child: Text('No media found.')),
                    ),
                  ];
                }

                return [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final event = mediaEvents[index];

                          final refs = (event['references'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
                          final less = (event['lessons'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

                          return TimelineCard(
                            id: event['id'].toString(),
                            year: event['year'] ?? '',
                            title: event['title'] ?? 'Untitled',
                            description: event['short_description'] ?? '',
                            imageUrl: event['image_url'],
                            fullDescription: event['full_description'],
                            category: event['category'],
                            references: refs,
                            lessons: less,
                          );
                        },
                        childCount: mediaEvents.length,
                      ),
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
    );
  }
}
