import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:iconsax/iconsax.dart';
import '../widget/action_card.dart';
import '../widget/bottom_nav_bar.dart';
import './timeline_screen.dart';
import '../tabs/favourite_tab.dart';
import '../tabs/profile_overview_tab.dart';
import '../tabs/multimedia_tab.dart';
import '../tabs/lesson_tab.dart';
import './chatbot_screen.dart';
import '../constants/app_colors.dart';
import './quiz_screen.dart';
import './notification_screen.dart';
import './shumail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final homeContent = SafeArea(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: isDark
                ? [
                    const Color(0xFF1A1A1A),
                    const Color(0xFF121212),
                    const Color(0xFF121212),
                  ]
                : [
                    AppColors.white,
                    AppColors.backgroundMint,
                    AppColors.backgroundMint,
                  ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(10, 0, 16, 30),
          child: Column(
            children: [
              buildNewHeader(context),
              const SizedBox(height: 8),
              buildInfoCards(),
              const SizedBox(height: 10),
              shumailEvents(context),
              const SizedBox(height: 10),
              buildTimelineLessonRow(context),
              const SizedBox(height: 10),
              buildBottomRowSection(context),
            ],
          ),
        ),
      ),
    );

    final pages = [
      homeContent,
      const FavouriteTab(),
      const ProfileOverviewTab(),
      const MultimediaTab(),
      const ChatbotScreen(), // AI Chat tab
    ];

    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: IndexedStack(index: _selectedIndex, children: pages),

        // ✅ Reusable Bottom Navigation Bar
        bottomNavigationBar: BottomNavBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
        ),
      ),
    );
  }

  // ---------------- New Header with Logo ----------------
  Widget buildNewHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/login_logo_cropped.png',
          height: 75,
          width: 70,
        ),
        const SizedBox(width: 20),
        Expanded(
          child: RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Digital See',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: 'rah Timeline',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(
              Iconsax.notification,
              color: AppColors.primary,
              size: 24,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ----------- Major Islamic Events (Hijri month-day) -----------
  static const Map<String, String> _islamicEvents = {
    '1-1': 'Islamic New Year',
    '1-10': 'Day of Ashura',
    '3-12': 'Mawlid al-Nabi ﷺ (Eid Milad-un-Nabi)',
    '7-27': 'Isra & Mi\'raj (Night Journey)',
    '8-15': 'Shab-e-Barat (Night of Fortune)',
    '9-1': 'Ramadan Begins',
    '9-17': 'Battle of Badr (Youm-e-Badr)',
    '9-20': 'Conquest of Makkah',
    '9-27': 'Laylat al-Qadr (Night of Power)',
    '10-1': 'Eid al-Fitr',
    '10-2': 'Eid al-Fitr (Day 2)',
    '10-3': 'Eid al-Fitr (Day 3)',
    '12-8': 'Day of Tarwiyah (Hajj begins)',
    '12-9': 'Day of Arafah',
    '12-10': 'Eid al-Adha',
    '12-11': 'Eid al-Adha (Day 2)',
    '12-12': 'Eid al-Adha (Day 3)',
    '12-18': 'Eid al-Ghadeer',
  };

  // ---------------- Single Info Card with Live Clock ----------------
  Widget buildInfoCards() {
    final hour = _now.hour % 12 == 0 ? 12 : _now.hour % 12;
    final minute = _now.minute.toString().padLeft(2, '0');
    final amPm = _now.hour >= 12 ? 'PM' : 'AM';
    final timeString = '$hour:$minute $amPm';

    // Greeting
    String greeting;
    IconData greetingIcon;
    if (_now.hour < 12) {
      greeting = 'Good Morning';
      greetingIcon = Iconsax.sun_1;
    } else if (_now.hour < 17) {
      greeting = 'Good Afternoon';
      greetingIcon = Iconsax.sun_fog;
    } else {
      greeting = 'Good Evening';
      greetingIcon = Iconsax.moon;
    }

    // Islamic (Hijri) date
    final hijri = HijriCalendar.now();
    final hijriDate = '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} AH';

    // Check for Islamic event today
    final eventKey = '${hijri.hMonth}-${hijri.hDay}';
    final todayEvent = _islamicEvents[eventKey];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: Greeting + Book icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(greetingIcon, color: const Color(0xFFFBBF24), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    greeting,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Iconsax.book_1,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Center: Bold Current Time
          Text(
            timeString,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),

          // Islamic date with crescent icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Iconsax.moon, color: Color(0xFFFBBF24), size: 14),
              const SizedBox(width: 5),
              Text(
                hijriDate,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          // Islamic Event Banner (only if there's an event today)
          if (todayEvent != null) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFBBF24).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFBBF24).withOpacity(0.4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Iconsax.star_1,
                    color: Color(0xFFFBBF24),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '🎉 Today: $todayEvent',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 6),

          // Divider
          Container(
            width: 50,
            height: 2,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 6),

          // Bottom: Seerah Journey title + subtitle
          const Text(
            'Seerah Journey',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Explore the life of Prophet Muhammad (ﷺ)',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ---------------- Event of the Day Card ----------------
  Widget shumailEvents(BuildContext context) {
    return GestureDetector(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              offset: Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Shumail of Rasulullah ﷺ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'How Prophet(PBUH) looked and presented',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'His(ﷺ) Akhalaq, speaking, style and teachings',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color.fromARGB(240, 255, 255, 255),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Iconsax.calendar_25,
                size: 28,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ShumailScreen()),
        );
      },
    );
  }

  // ---------------- Timeline & Lessons Row ----------------
  Widget buildTimelineLessonRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ActionCard(
            color: Colors.teal,
            icon: Icons.timeline,
            label: "Timeline",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TimelineScreen()),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ActionCard(
            color: Colors.amber.shade700,
            icon: Icons.menu_book,
            label: "Lessons",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LessonTab()),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------------- Bottom Row Section ----------------
  Widget buildBottomRowSection(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: stacked Multimedia and Favourite
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ActionCard(
                color: Colors.blue.shade600,
                icon: Icons.collections_rounded,
                label: "Multimedia",
                onTap: () {
                  setState(() {
                    _selectedIndex = 3;
                  });
                },
              ),
              const SizedBox(height: 10),
              ActionCard(
                color: Colors.red.shade400,
                icon: Icons.favorite_rounded,
                label: "Favorite",
                onTap: () {
                  setState(() {
                    _selectedIndex = 1;
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Right: stacked Quiz and AI Chatbot
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ActionCard(
                color: Colors.teal.shade500,
                icon: Icons.psychology_rounded,
                label: "Quiz",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const QuizScreen()),
                  );
                },
              ),
              const SizedBox(height: 10),
              ActionCard(
                color: Colors.deepPurple.shade500,
                icon: Icons.quickreply_rounded,
                label: "AI Chatbot",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChatbotScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // (Favourite card is now integrated into the bottom row stack)
}
