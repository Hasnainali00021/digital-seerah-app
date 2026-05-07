import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:seerah_timeline/widget/app_search_bar.dart';
import 'package:seerah_timeline/widget/custom_appbar.dart';
import '../constants/app_colors.dart';
import '../widget/category_card.dart';
import './shumail_events_list_screen.dart';
import '../services/offline_cache_service.dart';

class ShumailScreen extends StatefulWidget {
    const ShumailScreen({super.key});
    
    @override
    State<ShumailScreen> createState() => _ShumailScreenState();
}

class _ShumailScreenState extends State<ShumailScreen> {
  final supabase = Supabase.instance.client;
  static const String _cacheKey = 'shumail_categories_cache';
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  
  List<String> categories = [];
  List<String> filteredCategories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    final cachedCategories = await OfflineCacheService.loadStringList(_cacheKey);
    if (cachedCategories != null && mounted) {
      setState(() {
        categories = cachedCategories;
        filteredCategories = categories;
        isLoading = false;
      });
    }

    try {
      // Fetch all events and extract unique categories
      final response = await supabase
          .from('shumail_events')
          .select('category, order_index')
          .order('order_index', ascending: true);

      final Set<String> uniqueCategories = {};
      for (var item in response) {
        if (item['category'] != null) {
          uniqueCategories.add(item['category'].toString());
        }
      }

      setState(() {
        categories = uniqueCategories.toList();
        filteredCategories = categories;
        isLoading = false;
      });

      await OfflineCacheService.saveStringList(_cacheKey, categories);
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          if (categories.isEmpty) {
            filteredCategories = [];
          }
        });
      }
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.toLowerCase();
      filteredCategories = categories.where((cat) => cat.toLowerCase().contains(_searchQuery)).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getIconForCategory(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('اخلاق')) return Icons.favorite_border;
    if (lower.contains('طب') || lower.contains('tibb')) return Icons.healing;
    if (lower.contains('دعائیں') || lower.contains('dua')) return Icons.chat_bubble_outline;
    if (lower.contains('عبادات') || lower.contains('ibada')) return Icons.auto_awesome;
    if (lower.contains('قرآن') || lower.contains('quran')) return Icons.menu_book;
    if (lower.contains('سیرت') || lower.contains('seerah')) return Icons.person_outline;
    if (lower.contains('حدیث') || lower.contains('hadith')) return Icons.library_books;
    if (lower.contains('نبوت') || lower.contains('nabuwat')) return Icons.star_border;
    return Icons.folder_special_outlined; // Default fallback icon
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppColors.scaffoldBackground,
      appBar: const CustomAppbar(titleOne: ' Shumail of ', titleTwo: 'Rasulullah ﷺ'),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          children: [
            AppSearchBar(
              hintText: "Search Shumail Categories 🤲🏻", 
              onChanged: _onSearchChanged, 
              controller: _searchController
            ),
            const SizedBox(height: 20),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredCategories.isEmpty
                      ? Center(
                          child: Text(
                            'No categories found',
                            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                          ),
                        )
                      : GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.1, // Matches roughly the squarish cards in design
                          ),
                          itemCount: filteredCategories.length,
                          itemBuilder: (context, index) {
                            final category = filteredCategories[index];
                            return CategoryCard(
                              title: category,
                              icon: _getIconForCategory(category),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ShumailEventsListScreen(category: category),
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
}