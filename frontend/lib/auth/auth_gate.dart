import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:seerah_timeline/screen/dashboard_screen.dart';
import 'package:seerah_timeline/screen/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:seerah_timeline/screen/update_password_screen.dart';
import 'package:seerah_timeline/providers/providers.dart';

/*

AUTH GATE  - This will contineously listen for auth state changes


Unauthenticated  => Login Page
Authenticated  => Dashboared Screen
Recovery => Update Password Screen

*/
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (state) {
        final session = state.session;
        final event = state.event;

        // Route to the new password screen if responding to a reset link
        if (event == AuthChangeEvent.passwordRecovery) {
          return const UpdatePasswordScreen();
        }

        // Otherwise check session
        if (session != null) {
          return const DashboardScreen();
        } else {
          return const LoginScreen();
        }
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => const LoginScreen(),
    );
  }
}
