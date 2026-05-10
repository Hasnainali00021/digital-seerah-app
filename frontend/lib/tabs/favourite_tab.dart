import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:seerah_timeline/constants/app_colors.dart';
import 'package:seerah_timeline/providers/providers.dart';
import 'package:seerah_timeline/screen/video_player_screen.dart';
import 'package:seerah_timeline/screen/event_detail_screen.dart';
import 'package:seerah_timeline/widget/custom_network_image.dart';
import 'package:seerah_timeline/widget/custom_back_button.dart';
import 'package:seerah_timeline/widget/app_search_bar.dart';

class FavouriteTab extends ConsumerStatefulWidget {
  const FavouriteTab({super.key});

  @override
  ConsumerState<FavouriteTab> createState() => _FavouriteTabState();
}

class _FavouriteTabState extends ConsumerState<FavouriteTab> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  static const _cacheKey = 'cached_favourite_events';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchFavorites(List<String> ids) async {
    if (ids.isEmpty) return [];

    // Try network first
    try {
      final response = await _supabase
          .from('timeline_events')
          .select()
          .filter('id', 'in', ids);

      final List<Map<String, dynamic>> rawEvents =
          List<Map<String, dynamic>>.from(response);

      final Map<String, Map<String, dynamic>> eventMap = {
        for (var e in rawEvents) e['id'].toString(): e
      };

      final ordered = ids
          .where((id) => eventMap.containsKey(id))
          .map((id) => eventMap[id]!)
          .toList();

      // Save to local cache for offline use
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(ordered));

      return ordered;
    } catch (_) {
      // Network failed — load from cache
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached != null) {
        final list = jsonDecode(cached) as List<dynamic>;
        final all = list.cast<Map<String, dynamic>>();
        // Only return events whose IDs are still in the favorites list
        return all.where((e) => ids.contains(e['id'].toString())).toList();
      }
      return []; // Empty instead of crashing
    }
  }
  
  bool _hasContent(Map<String, dynamic> event) {
    // Check if there is an image URL (which covers both images and videos usually)
    final String? imageUrl = event['image_url'];
    return imageUrl != null && imageUrl.isNotEmpty;
  }

  bool _isYouTubeVideo(String? url) {
    if (url == null) return false;
    return url.contains('youtube.com') || url.contains('youtu.be');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? const Color(0xFF121212) : AppColors.scaffoldBackground;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final primaryText = isDark ? Colors.white : Colors.black87;
    final secondaryText = isDark ? Colors.white70 : Colors.grey[600];

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : AppColors.scaffoldBackground,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        leading: const CustomBackButton(),
        title: RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            children: [
              TextSpan(text: 'My ', style: TextStyle(color: AppColors.primary)),
              TextSpan(text: 'Favorites', style: TextStyle(color: AppColors.accent)),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Quick access to saved events & lessons",
                    style: TextStyle(
                      color: secondaryText,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppSearchBar(
                    hintText: "Search favorites...",
                    onChanged: (value) {},
                    controller: _searchController,
                    margin: EdgeInsets.zero,
                  ),
                ],
              ),
            ),

            // Favorites List
            Expanded(
              child: Builder(
                builder: (context) {
                  final favoriteIds = ref.watch(favoritesProvider);
                  if (favoriteIds.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                           Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                           SizedBox(height: 16),
                           Text(
                            "No favorites yet",
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return FutureBuilder<List<Map<String, dynamic>>>(
                    future: _fetchFavorites(favoriteIds),
                    builder: (context, snapshot) {
                       if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                       }
                       if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.wifi_off_rounded, size: 52, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  "You're offline",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Connect to internet to load your favorites",
                                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          );
                        }
                       
                       var events = snapshot.data ?? [];
                       
                       // Filter events based on search query
                       if (_searchQuery.isNotEmpty) {
                         events = events.where((event) {
                           final title = (event['title'] ?? '').toString().toLowerCase();
                           final desc = (event['short_description'] ?? '').toString().toLowerCase();
                           return title.contains(_searchQuery) || desc.contains(_searchQuery);
                         }).toList();
                       }

                       return Column(
                         crossAxisAlignment: CrossAxisAlignment.stretch,
                         children: [
                           Padding(
                             padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                             child: Text(
                               "${events.length} items found",
                               style: TextStyle(
                                   color: secondaryText,
                                 fontSize: 14,
                                 fontWeight: FontWeight.w500,
                               ),
                             ),
                           ),
                           Expanded(
                             child: ListView.builder(
                               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                               itemCount: events.length,
                               itemBuilder: (context, index) {
                                  final event = events[index];
                                  final bool hasMedia = _hasContent(event);
                                  
                                  if (hasMedia) {
                                    return _buildDetailedCard(context, event);
                                  } else {
                                    return _buildSimpleCard(context, event);
                                  }
                               },
                             ),
                           ),
                         ],
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

  // Card for items with Video/Image content
  Widget _buildDetailedCard(BuildContext context, Map<String, dynamic> event) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final titleColor = isDark ? Colors.white : AppColors.textPrimary;
    final descriptionColor = isDark ? Colors.white70 : AppColors.textSecondary;
    final metadataColor = isDark ? Colors.white70 : Colors.grey[800]!;

    final bool isVideo = _isYouTubeVideo(event['image_url']);
    
    return GestureDetector(
      onTap: () {
        _navigateToDetail(context, event, isVideo);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black54 : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section with Overlay Icon
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 70,
                    height: 70,
                    child: CustomNetworkImage(
                      imageUrl: event['image_url'] ?? '',
                      fit: BoxFit.cover,
                      errorWidget: Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                // Overlay Icon (Top Right of image)
                Positioned(
                  top: -6,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryLight, // Teal
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.history_edu, 
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            
            // Content Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Star Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          event['title'] ?? 'No Title',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.star, color: AppColors.accent, size: 20),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // Description
                  if (event['short_description'] != null)
                  Text(
                    event['short_description'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: descriptionColor,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  
                  // Metadata (Year / Category)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "${event['category'] ?? ''} - ${event['year'] ?? ''}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500, // Medium weight
                            color: metadataColor,
                          ),
                        ),
                      ),
                      // Chevron
                      const Icon(Icons.chevron_right, color: AppColors.primary, size: 20),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Simple Card for items without content (Name only)
  Widget _buildSimpleCard(BuildContext context, Map<String, dynamic> event) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final titleColor = isDark ? Colors.white : AppColors.textPrimary;

    return GestureDetector(
      onTap: () {
         _navigateToDetail(context, event, false);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
           boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black54 : Colors.black.withOpacity(0.03),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                event['title'] ?? 'No Title',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
              ),
            ),
            const Icon(Icons.star, color: AppColors.accent, size: 20),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, Map<String, dynamic> event, bool isVideo) {
    if (isVideo) {
      List<String> lessons = [];
        if (event['lessons'] != null) {
          lessons = List<String>.from(event['lessons']);
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPlayerScreen(
              videoUrl: event['image_url'],
              title: event['title'] ?? 'No Title',
              lessons: lessons,
            ),
          ),
        );
    } else {
       final refs = (event['references'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
       final less = (event['lessons'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      
       Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(
               id: event['id'].toString(),
               title: event['title'] ?? '',
               date: event['year'] ?? '',
               period: event['category'] ?? '',
               description: event['full_description'] ?? event['short_description'] ?? '',
               imageUrl: event['image_url'],
               references: refs,
               lessons: less,
            ),
          ),
        );
    }
  }
}
