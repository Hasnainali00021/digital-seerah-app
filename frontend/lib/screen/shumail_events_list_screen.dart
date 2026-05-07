import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_colors.dart';
import '../widget/timeline_card.dart';
import '../widget/custom_appbar.dart';
import '../widget/app_search_bar.dart';
import '../services/offline_cache_service.dart';

class ShumailEventsListScreen extends StatefulWidget {
  final String category;
  
  const ShumailEventsListScreen({super.key, required this.category});

  @override
  State<ShumailEventsListScreen> createState() => _ShumailEventsListScreenState();
}

class _ShumailEventsListScreenState extends State<ShumailEventsListScreen> {
  final supabase = Supabase.instance.client;
  String get _cacheKey => 'shumail_events_cache_${widget.category.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_').toLowerCase()}';
  List<Map<String, dynamic>> events = [];
  List<Map<String, dynamic>> filteredEvents = [];
  bool isLoading = true;
  String? errorMessage;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    final cachedEvents = await OfflineCacheService.loadJsonList(_cacheKey);
    if (cachedEvents != null && mounted) {
      setState(() {
        events = cachedEvents;
        _filterEvents();
        isLoading = false;
      });
    }

    try {
      final response = await supabase
          .from('shumail_events')
          .select()
          .eq('category', widget.category)
          .order('order_index', ascending: true);

      setState(() {
        events = List<Map<String, dynamic>>.from(response);
        _filterEvents();
        isLoading = false;
      });

      await OfflineCacheService.saveJsonList(_cacheKey, events);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'Failed to load events: $e';
        isLoading = false;
        if (events.isEmpty) {
          filteredEvents = [];
        }
      });
    }
  }

  void _filterEvents() {
    setState(() {
      filteredEvents = events.where((event) {
        final query = _searchQuery.toLowerCase().trim();
        final title = (event['title'] ?? '').toString().toLowerCase();
        final description = (event['short_description'] ?? '').toString().toLowerCase();

        return query.isEmpty || title.contains(query) || description.contains(query);
      }).toList();
    });
  }

  void _onSearchQueryChanged(String query) {
    _searchQuery = query;
    _filterEvents();
  }

  Widget buildShumailItem(BuildContext context, Widget card) {
    return Padding(
       padding: const EdgeInsets.only(bottom: 16),
       child: card,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppColors.scaffoldBackground,
      appBar: CustomAppbar(
        titleOne: "", 
        titleTwo: widget.category,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
        child: Column(
          children: [
            AppSearchBar(
              hintText: "Search inside ${widget.category}...", 
              onChanged: _onSearchQueryChanged,
              controller: _searchController
            ),
            const SizedBox(height: 16),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage != null
                    ? Center(child: Text(errorMessage!, style: TextStyle(color: isDark ? Colors.white70 : Colors.red)))
                  : filteredEvents.isEmpty
                    ? Center(child: Text('No events found in this category', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)))
                  : ListView.builder(
                      itemCount: filteredEvents.length,
                      itemBuilder: (context, index) {
                        final event = filteredEvents[index];
                        final refs = (event['references'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

                        return buildShumailItem(
                          context,
                          TimelineCard(
                            id: event['id'].toString(), 
                            year: '', // Excluded since Shumail generally lacks years
                            title: event['title'] ?? 'Untitled',
                            description: event['short_description'] ?? '',
                            imageUrl: event['image_url'], // May be null or omitted
                            fullDescription: event['full_description'],
                            category: event['category'],
                            references: refs,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
