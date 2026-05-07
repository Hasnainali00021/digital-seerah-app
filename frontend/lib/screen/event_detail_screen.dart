import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seerah_timeline/constants/app_colors.dart';
import 'package:seerah_timeline/screen/active_quiz_screen.dart';
import 'package:seerah_timeline/screen/media_viewer_screen.dart';
import 'package:seerah_timeline/widget/custom_back_button.dart';
import 'package:seerah_timeline/widget/custom_network_image.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:seerah_timeline/providers/providers.dart';

class EventDetailScreen extends ConsumerStatefulWidget {
  final String id; // Changed
  final String title;
  final String date;
  final String period;
  final String description;
  // Optional image (either local asset or network)
  final String? imageAsset;
  final String? imageUrl;
  
  // Lists for structured data
  final List<String> references;
  final List<String> lessons;

  const EventDetailScreen({
    super.key,
    required this.id,
    required this.title,
    required this.date,
    required this.period,
    required this.description,
    this.imageAsset,
    this.imageUrl,
    this.references = const [],
    this.lessons = const [],
  });

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  YoutubePlayerController? _youtubeController;

  @override
  void initState() {
    super.initState();

    // Track this as the last visited event for "Resume Reading"
    ref.read(lastVisitedProvider.notifier).save(
      LastVisitedEvent(
        id: widget.id,
        title: widget.title,
        imageUrl: widget.imageUrl,
        date: widget.date,
        period: widget.period,
        description: widget.description,
      ),
    );

    // Count this event as read
    ref.read(readEventsProvider.notifier).markRead(widget.id);

    if (widget.imageUrl != null) {
      final videoId = YoutubePlayer.convertUrlToId(widget.imageUrl!);
      if (videoId != null) {
        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
            disableDragSeek: false,
            loop: false,
            isLive: false,
            forceHD: false,
            enableCaption: true,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textMain = isDark ? const Color(0xFFE5E7EB) : Colors.black87;
    final textSub = isDark ? const Color(0xFF9CA3AF) : Colors.black54;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: CustomBackButton(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Builder(
              builder: (context) {
                final favIds = ref.watch(favoritesProvider);
                final isFav = favIds.contains(widget.id);
                return IconButton(
                  icon: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.pinkAccent : const Color(0xFF0D9488),
                  ),
                  onPressed: () {
                    ref.read(favoritesProvider.notifier).toggle(widget.id);
                  },
                );
              },
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner: YouTube Player or Image
              if (widget.imageAsset != null || widget.imageUrl != null)
                GestureDetector(
                  onTap: () {
                    if (widget.imageUrl == null && widget.imageAsset == null) {
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MediaViewerScreen(
                          mediaUrl: widget.imageUrl,
                          imageAsset: widget.imageAsset,
                          title: widget.title,
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                       width: double.infinity,
                       // If it's a YouTube video, let the player determine height (aspect ratio)
                       // If it's an image, force height 200
                       height: _youtubeController != null ? null : 200,
                       decoration: const BoxDecoration(
                         shape: BoxShape.rectangle,
                       ),
                      child: _youtubeController != null
                          ? YoutubePlayer(
                              controller: _youtubeController!,
                              showVideoProgressIndicator: true,
                              progressIndicatorColor: const Color(0xFF0D9488),
                              progressColors: const ProgressBarColors(
                                playedColor: Color(0xFF0D9488),
                                handleColor: Color(0xFF0D9488),
                              ),
                            )
                          : (widget.imageAsset != null
                              ? Image.asset(widget.imageAsset!, fit: BoxFit.cover)
                              : CustomNetworkImage(
                                  imageUrl: widget.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorWidget: Container(
                                    color: Colors.teal.shade300,
                                    child: const Center(
                                      child: Icon(
                                        Icons.broken_image_rounded,
                                        color: Colors.white70,
                                        size: 44,
                                      ),
                                    ),
                                  ),
                                )),
                    ),
                  ),
                ),

              if (widget.imageAsset != null || widget.imageUrl != null)
                const SizedBox(height: 16),
              
              // 🕌 Title Section with Date & Period
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                   Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.military_tech_rounded,
                      color: Color(0xFF0D9488),
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Date and Period in small format
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (widget.period.isNotEmpty && widget.period != "Unknown Period")
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFD1FAE5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFF0D9488).withOpacity(0.3)),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              child: Text(
                                widget.period,
                                style: const TextStyle(
                                  color: Color(0xFF0D9488),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          if (widget.period.isNotEmpty && widget.period != "Unknown Period" && widget.date.isNotEmpty)
                            const SizedBox(height: 4),
                          if (widget.date.isNotEmpty)
                            Text(
                              widget.date,
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(
                                color: Colors.black54, 
                                fontSize: 12, 
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Noto Nastaliq Urdu',
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  Expanded(
                    flex: 2,
                    child: Text(
                      widget.title,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        color: Color(0xFF0D9488),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Noto Nastaliq Urdu',
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade100),
                ),
                padding: const EdgeInsets.all(16),
                child: Text(
                  widget.description,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    color: textMain,
                    fontSize: 16,
                    height: 1.8,
                    fontFamily: 'Noto Nastaliq Urdu',
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 📚 Collapsible References
               _buildExpandableTile(
                  "References",
                  Icons.menu_book_outlined,
                  widget.references,
                  context,
                  isDark: isDark,
                  cardBg: cardBg,
                  textMain: textMain,
                  textSub: textSub,
                ),
                
              if (widget.lessons.isNotEmpty) ...[
                const SizedBox(height: 12),
                
                // 💡 Collapsible Lessons
                _buildExpandableTile(
                  "Lessons & Wisdom",
                  Icons.lightbulb_outline,
                  widget.lessons,
                  context,
                  isDark: isDark,
                  cardBg: cardBg,
                  textMain: textMain,
                  textSub: textSub,
                ),
              ],

              const SizedBox(height: 30),

                // 📝 Take Quiz Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ActiveQuizScreen(
                            eventTitle: widget.title,
                            eventContent: widget.description,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.quiz_outlined, color: Colors.white),
                    label: const Text(
                      "Take Quiz",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
                
                const SizedBox(height: 40), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Reusable Expandable Tile
  Widget _buildExpandableTile(
    String title,
    IconData icon,
    List<String> items,
    BuildContext context, {
    bool isDark = false,
    Color? cardBg,
    Color? textMain,
    Color? textSub,
  }) {
    final bgColor = cardBg ?? Colors.white;
    final mainColor = textMain ?? Colors.black87;
    final subColor = textSub ?? Colors.black54;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade100),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const RoundedRectangleBorder(
            side: BorderSide.none,
          ),
          leading: Icon(icon, color: const Color(0xFF0D9488)),
          title: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0D9488),
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          iconColor: const Color(0xFF0D9488),
          collapsedIconColor: const Color(0xFF0D9488),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: items.isEmpty
              ? [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      "No content available.",
                      style: TextStyle(
                        color: subColor,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                ]
              : [
                  ...items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Text(
                              item,
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontFamily: 'Noto Nastaliq Urdu',
                                fontSize: 14,
                                color: mainColor,
                                height: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Icon(Icons.circle,
                                size: 6, color: Color(0xFF0D9488)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
        ),
      ),
    );
  }
}

