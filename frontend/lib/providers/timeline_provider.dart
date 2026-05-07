import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimelineEventsNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  TimelineEventsNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    const cacheKey = 'timeline_events_cache';
    
    final cachedStr = prefs.getString(cacheKey);
    
    // 1. Load from cache immediately if present
    if (cachedStr != null) {
      try {
        final List<dynamic> decoded = jsonDecode(cachedStr);
        final cachedData = decoded.cast<Map<String, dynamic>>();
        state = AsyncValue.data(cachedData);
        print('✅ Loaded timeline events from local cache');
      } catch (e) {
        // Cache invalid, ignore
        print('⚠️ Failed to load timeline cache: $e');
      }
    }

    // 2. Fetch fresh data from Supabase silently in background
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('timeline_events')
          .select()
          .order('order_index', ascending: true);
          
      final freshData = List<Map<String, dynamic>>.from(response);
      
      // Update cache
      await prefs.setString(cacheKey, jsonEncode(freshData));
      
      // Update state
      state = AsyncValue.data(freshData);
      print('✅ Fetched and cached fresh timeline events from Supabase');
    } catch (e, st) {
      // If we don't have cache, set error. If we do have cache, keep it.
      print('❌ Error fetching timeline events: $e');
      if (state.value == null) {
        state = AsyncValue.error(e, st);
      }
    }
  }
}

// Raw events from Supabase with Caching
final timelineEventsProvider = StateNotifierProvider<TimelineEventsNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return TimelineEventsNotifier();
});

// Category State
final selectedCategoryProvider = StateProvider<String>((ref) => 'All');

// Search Query State
final searchQueryProvider = StateProvider<String>((ref) => '');

// Filtered Events Provider
final filteredEventsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  // Watch the raw events (we only filter if the raw events are loaded)
  final asyncEvents = ref.watch(timelineEventsProvider);
  
  // Watch the filters
  final selectedCategory = ref.watch(selectedCategoryProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();
  
  return asyncEvents.maybeWhen(
    data: (events) {
      return events.where((event) {
        // 1. Category Filter
        final matchesCategory = selectedCategory == 'All' || event['category'] == selectedCategory;

        // 2. Search Filter
        final title = (event['title'] ?? '').toString().toLowerCase();
        final description = (event['short_description'] ?? '').toString().toLowerCase();
        final fullDesc = (event['full_description'] ?? '').toString().toLowerCase();
        final year = (event['year'] ?? '').toString().toLowerCase();

        final matchesSearch = query.isEmpty ||
            title.contains(query) ||
            description.contains(query) ||
            fullDesc.contains(query) ||
            year.contains(query);

        return matchesCategory && matchesSearch;
      }).toList();
    },
    orElse: () => [],
  );
});
