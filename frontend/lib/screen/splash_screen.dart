import 'dart:async';
import 'package:flutter/material.dart';
import 'package:seerah_timeline/constants/app_colors.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seerah_timeline/auth/auth_gate.dart';
import 'package:seerah_timeline/screen/dashboard_screen.dart';
import 'package:seerah_timeline/screen/onboarding_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  int _activeDotIndex = 0;
  Timer? _animationTimer;

  @override
  void initState() {
    super.initState();

    _startDotAnimation();

    Timer(const Duration(seconds: 3), () async {
      if (mounted) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        } else {
          final prefs = await SharedPreferences.getInstance();
          final bool hasSeenOnboarding =
              prefs.getBool('has_seen_onboarding') ?? false;

          if (hasSeenOnboarding && mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AuthGate()),
            );
          } else if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const OnboardingScreen()),
            );
          }
        }
      }
    });
  }

  void _startDotAnimation() {
    int tickCount = 0;
    _animationTimer = Timer.periodic(const Duration(milliseconds: 500), (
      timer,
    ) {
      if (mounted) {
        setState(() {
          _activeDotIndex = (_activeDotIndex + 1) % 3;
        });
      }

      tickCount++;
      // Stop after 6 ticks (3 seconds), matching your splash screen delay
      if (tickCount >= 6) {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    // Always cancel the timer to prevent memory leaks
    _animationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundGradient = isDark
        ? const [Color(0xFF171717), Color(0xFF121212)]
        : const [Color(0xFFE8FFF5), Color(0xFFD8F5EB)];
    final panelColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final primaryText = isDark ? Colors.white : Colors.teal.shade800;
    final accentText = isDark ? const Color(0xFFF59E0B) : Colors.orange.shade600;
    final subtitleColor = isDark ? Colors.white70 : Colors.teal.shade700;
    final lineColor = isDark ? Colors.white24 : Colors.teal.shade300;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : AppColors.scaffoldBackground,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: backgroundGradient,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 120,
                width: 120,
                decoration: BoxDecoration(
                  color: panelColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black54 : Colors.grey.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      size: 50,
                      color: isDark ? const Color(0xFF2DD4BF) : Colors.teal.shade700,
                    ),
                    Positioned(
                      top: 20,
                      left: 28,
                      child: Icon(
                        Icons.nights_stay_rounded,
                        size: 24,
                        color: accentText,
                      ),
                    ),
                    Positioned(
                      bottom: 25,
                      right: 28,
                      child: Icon(
                        Iconsax.clock,
                        size: 20,
                        color: accentText,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 📘 App Name
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "Digital ",
                      style: TextStyle(
                        color: primaryText,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    TextSpan(
                      text: "Seerah",
                      style: TextStyle(
                        color: accentText,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // 📖 Subtitle
              Text(
                "Journey Through the Seerah",
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
                ),
              ),

              const SizedBox(height: 20),

              // Decorative line
              Container(width: 100, height: 1, color: lineColor),

              const SizedBox(height: 20),

              // Page indicator (3 dots)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  bool isActive = _activeDotIndex == index;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _buildDot(
                      isActive,
                      isActive ? accentText : (isDark ? Colors.white38 : Colors.teal.shade400),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDot(bool active, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: active ? 10 : 8,
      height: active ? 10 : 8,
      decoration: BoxDecoration(
        color: color.withOpacity(active ? 1.0 : 0.5),
        shape: BoxShape.circle,
      ),
    );
  }
}
