import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screen/splash_screen.dart';
import 'screen/dashboard_screen.dart';
import 'screen/update_password_screen.dart';
import 'providers/providers.dart';
import 'auth/auth_gate.dart';
import 'providers/theme_provider.dart';

// 1. Define a global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    anonKey: "sb_publishable_t9ayeFDKIpuiUcj-2D-MdA_f6qDb2_O",
    url: 'https://hgcarcqmfwmbywrxmpnp.supabase.co',
  );

  final prefs = await SharedPreferences.getInstance();
  final savedThemeMode = prefs.getString('theme_mode');
  initialThemeMode = savedThemeMode == ThemeMode.dark.name
      ? ThemeMode.dark
      : ThemeMode.light;

  // ProviderScope wraps the entire app — Riverpod providers are now available everywhere.
  // FavoritesService().init() is no longer needed; the FavoritesNotifier loads itself.
  runApp(const ProviderScope(child: MyApp()));
}

final supabase = Supabase.instance.client;

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  Timer? _inactivityTimer;
  StreamSubscription<AuthState>? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Listen for auth state changes globally to clear navigation stack 
    // when user signs in (e.g., via OAuth on the SignupScreen).
    _authStateSubscription = supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) {
        // Clear any pushed screens (like SignupScreen) to reveal AuthGate
        navigatorKey.currentState?.popUntil((route) => route.isFirst);
      } else if (data.event == AuthChangeEvent.passwordRecovery) {
        // New: Handle password recovery by navigating to the update screen
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const UpdatePasswordScreen()),
        );
      } else if (data.event == AuthChangeEvent.signedOut) {
        // Reset the entire app routing to AuthGate when logged out
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      }
    });
    
    // Initialize local notifications early
    ref.read(localNotificationsProvider).init();
  }
  
  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _authStateSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print('🔄 App lifecycle changed: $state');
    if (state == AppLifecycleState.paused) {
      // Data is always available now — loaded eagerly in main()
      final lastVisited = ref.read(lastVisitedProvider);
      
      // Cancel any previous timer
      _inactivityTimer?.cancel();
      
      // Start a Dart Timer — this fires reliably even on MIUI
      // because the Flutter engine is still alive when paused.
      // Change to Duration(hours: 24) for production!
      _inactivityTimer = Timer(const Duration(seconds: 10), () {
        print('⏰ Timer fired! Showing inactivity notification now');
        ref.read(localNotificationsProvider).showInactivityReminder(lastVisited);
      });
      print('⏰ Started 10-second inactivity timer');
    } else if (state == AppLifecycleState.resumed) {
      // User came back — cancel the timer if it hasn't fired yet
      if (_inactivityTimer?.isActive ?? false) {
        _inactivityTimer!.cancel();
        print('🧹 Canceled inactivity timer (user returned)');
      } else {
        print('✅ Timer already fired or not set');
      }
      
      // Force reload last visited from disk (SharedPreferences cache may be stale
      // if Android killed our process and we were cold-started)
      ref.read(lastVisitedProvider.notifier).reload();
    }
  }


  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Digital Seerah',
      themeMode: themeMode,

      // ── Light Theme ──────────────────────────────────────────────────
      theme: ThemeData(
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFF0D9488),
        scaffoldBackgroundColor: const Color(0xFFF2F8F5),
        cardColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D9488),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFF1F2937)),
          bodySmall: TextStyle(color: Color(0xFF6B7280)),
        ),
        expansionTileTheme: const ExpansionTileThemeData(
          textColor: Color(0xFF0D9488),
          iconColor: Color(0xFF0D9488),
          collapsedTextColor: Color(0xFF1F2937),
          collapsedIconColor: Color(0xFF0D9488),
        ),
      ),

      // ── Dark Theme ───────────────────────────────────────────────────
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF0D9488),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A1A),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFE5E7EB)),
          bodySmall: TextStyle(color: Color(0xFF9CA3AF)),
          bodyLarge: TextStyle(color: Color(0xFFE5E7EB)),
        ),
        // Make cards, containers look good in dark mode
        dividerColor: Colors.white12,
        expansionTileTheme: const ExpansionTileThemeData(
          textColor: Color(0xFF2DD4BF),
          iconColor: Color(0xFF2DD4BF),
          collapsedTextColor: Color(0xFFE5E7EB),
          collapsedIconColor: Color(0xFF2DD4BF),
          backgroundColor: Color(0xFF1E1E1E),
          collapsedBackgroundColor: Color(0xFF1E1E1E),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF2A2A2A),
          border: OutlineInputBorder(),
          labelStyle: TextStyle(color: Color(0xFF9CA3AF)),
          hintStyle: TextStyle(color: Color(0xFF6B7280)),
        ),
      ),

      home: const SplashScreen(),
    );
  }
}
