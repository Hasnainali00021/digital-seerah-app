import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:seerah_timeline/constants/app_colors.dart';
import 'package:seerah_timeline/screen/event_detail_screen.dart';
import 'package:seerah_timeline/screen/media_viewer_screen.dart';
import 'package:seerah_timeline/providers/providers.dart';
import 'package:seerah_timeline/widget/custom_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── Daily Sunnahs list (shown by day-of-year index) ──────────────────────────
const _dailySunnahs = [
  'Greet others with Salaam first.',
  'Smile at your brother — it is charity.',
  'Eat with your right hand.',
  'Begin every task with Bismillah.',
  'Drink water while seated in 3 sips.',
  'Sleep on your right side.',
  'Recite Ayatul Kursi before sleeping.',
  'Say SubhanAllah 33 times after each prayer.',
  'Give charity, even if only a little.',
  'Brush your teeth (Miswak) before prayer.',
  'Say Alhamdulillah after sneezing.',
  'Reply to a sneeze with "YarhamukAllah".',
  'Lower your gaze and guard your modesty.',
  'Visit the sick — it is a great Sunnah.',
  'Perform Wudhu perfectly and with Du\'a.',
  'Enter the Masjid with your right foot.',
  'Exit the Masjid with your left foot.',
  'Recite Durood on the Prophet ﷺ at least 10 times.',
  'Perform 2 Rak\'ah Tahiyyat al-Masjid upon entering.',
  'Make Du\'a after the Adhan.',
  'Fast on Mondays and Thursdays.',
  'Give the right of way on the road.',
  'Remove harmful things from the road (Sadaqah).',
  'Visit your relatives (Sila-e-Rahmi).',
  'Make Istighfar 70+ times a day.',
  'Say Bismillah before entering the home.',
  'Recite Surah Kahf on Friday.',
  'Send extra Durood on Friday.',
  'Perform 12 Sunnah rak\'ahs daily.',
  'Remember Allah abundantly (Dhikr).',
];

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() =>
      _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  // ── Did You Know state ──────────────────────────────────────────────────────
  Map<String, dynamic>? _didYouKnowEvent;
  bool _loadingFact = true;

  // ── Daily Sunnah (derived deterministically from today's date) ─────────────
  late final String _todaySunnah;

  @override
  void initState() {
    super.initState();
    final dayOfYear = DateTime.now().difference(
          DateTime(DateTime.now().year, 1, 1),
        ).inDays;
    _todaySunnah = _dailySunnahs[dayOfYear % _dailySunnahs.length];
    _fetchRandomFact();
  }

  Future<void> _fetchRandomFact() async {
    try {
      final supabase = Supabase.instance.client;
      // Fetch all IDs first (lightweight)
      final ids = await supabase.from('shumail_events').select('id');
      if (ids.isEmpty) {
        if (mounted) setState(() => _loadingFact = false);
        return;
      }
      final randomId = (ids..shuffle(Random()))[0]['id'];
      final event = await supabase
          .from('shumail_events')
          .select()
          .eq('id', randomId)
          .maybeSingle();
      if (mounted) {
        setState(() {
          _didYouKnowEvent = event;
          _loadingFact = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingFact = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lastVisited = ref.watch(lastVisitedProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF121212) : AppColors.scaffoldBackground;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final subColor = isDark ? Colors.white60 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: SafeArea(
          child: AppBar(
            backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: isDark ? Colors.white : AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              "Notifications",
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section: Resume Reading
            _buildResumeReadingCard(context, lastVisited, isDark, cardBg, subColor),

            const SizedBox(height: 24),

            // Explore Section Header
            Text(
              "Explore",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),

            // Did You Know card
            _buildDidYouKnowCard(context, isDark, cardBg, subColor, textColor),

            const SizedBox(height: 12),

            // Daily Sunnah Reminder card
            _buildDailySunnahCard(context, isDark, cardBg, subColor, textColor),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ── Did You Know Card ───────────────────────────────────────────────────────
    Widget _buildDidYouKnowCard(
      BuildContext context,
      bool isDark,
      Color cardBg,
      Color subColor,
      Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFD1FAE5),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.lightbulb_outline, color: Color(0xFF0D9488), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _loadingFact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Did You Know?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        color: AppColors.primary,
                        backgroundColor: AppColors.primary.withOpacity(0.15),
                      ),
                    ],
                  )
                : _didYouKnowEvent == null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Did You Know?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Discover a fascinating fact about the life of the Prophet Muhammad (P.B.U.H).',
                            style: TextStyle(fontSize: 13, color: subColor, height: 1.3),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Did You Know?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            (_didYouKnowEvent!['short_description'] ?? '').toString(),
                            style: TextStyle(fontSize: 13, color: subColor, height: 1.3),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _didYouKnowEvent == null
                ? _fetchRandomFact
                : () {
                    _showFactDialog(context, isDark);
                  },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(60, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              _didYouKnowEvent == null ? 'Refresh' : 'Read More',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFactDialog(BuildContext context, bool isDark) {
    if (_didYouKnowEvent == null) return;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final subColor = isDark ? Colors.white60 : Colors.grey.shade600;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFD1FAE5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lightbulb, color: AppColors.primary, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                _didYouKnowEvent!['title'] ?? 'Did You Know?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _didYouKnowEvent!['short_description'] ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: subColor, height: 1.5),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _fetchRandomFact();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Another Fact',
                        style: TextStyle(color: AppColors.primary)),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Close',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Daily Sunnah Card ───────────────────────────────────────────────────────
    Widget _buildDailySunnahCard(
      BuildContext context,
      bool isDark,
      Color cardBg,
      Color subColor,
      Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFD1FAE5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.wb_sunny_outlined,
                color: Color(0xFF10B981), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Sunnah Reminder',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Today's Sunnah: $_todaySunnah",
                  style: TextStyle(
                    fontSize: 13,
                    color: subColor,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => _showSunnahDialog(context, isDark),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(50, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'View',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSunnahDialog(BuildContext context, bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final subColor = isDark ? Colors.white60 : Colors.grey.shade600;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFD1FAE5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.wb_sunny,
                    color: Color(0xFF10B981), size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                'Daily Sunnah Reminder',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _todaySunnah,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'May Allah make it easy for us to follow the Sunnah of our beloved Prophet ﷺ.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12, color: subColor, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('JazakAllah Khair',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Resume Reading Card ─────────────────────────────────────────────────────
  Widget _buildResumeReadingCard(
    BuildContext context,
    LastVisitedEvent? lastVisited,
    bool isDark,
    Color cardBg,
    Color subColor,
  ) {
    if (lastVisited == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "Start your journey",
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Icon(Iconsax.book_1, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              "No events visited yet",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Explore the Timeline to start tracking your progress",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "Pick up where you left off",
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (lastVisited.imageUrl != null &&
                  lastVisited.imageUrl!.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MediaViewerScreen(
                          mediaUrl: lastVisited.imageUrl!,
                          title: lastVisited.title,
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 90,
                      height: 90,
                      child: CustomNetworkImage(
                        imageUrl: lastVisited.imageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade200,
                          child:
                              const Icon(Icons.image, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Iconsax.book_1,
                      color: AppColors.primary, size: 36),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lastVisited.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      lastVisited.description.length > 100
                          ? '${lastVisited.description.substring(0, 100)}...'
                          : lastVisited.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: subColor,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventDetailScreen(
                      id: lastVisited.id,
                      title: lastVisited.title,
                      date: lastVisited.date,
                      period: lastVisited.period,
                      description: lastVisited.description,
                      imageUrl: lastVisited.imageUrl,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                elevation: 0,
              ),
              child: const Text(
                "Resume Reading",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
