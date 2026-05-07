import 'package:flutter/material.dart';
import 'package:seerah_timeline/auth/auth_service.dart';
import 'package:seerah_timeline/main.dart';
import 'package:seerah_timeline/constants/app_colors.dart';
import 'package:seerah_timeline/screen/dashboard_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widget/custom_text_field.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // get Auth Service
  final authService = AuthService();

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showToast(String message, {bool isError = true}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isError
        ? (isDark ? Colors.red.shade400 : Colors.red.shade700)
        : AppColors.primary;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void login() async {
    if (!_formKey.currentState!.validate()) {
      _showToast("Please fix the errors in the form");
      return;
    }

    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      // Attempt actual sign in
      final response = await authService.signInWithEmailPassword(
        email,
        password,
      );

      if (response.session != null) {
        // Login successful, navigate to dashboard
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        String msg = e.message;
        if (msg.toLowerCase().contains('invalid login credentials')) {
          msg = "Invalid credentials. If you registered via Google or Facebook, please use their buttons, or use 'Forgot Password'.";
        }
        _showToast(msg);
      }
    } catch (e) {
      if (mounted) {
        _showToast("Login failed: ${e.toString()}");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void sendMagicLink() async {
    final email = _emailController.text.trim();

    // Validate email
    if (email.isEmpty) {
      _showToast("Please enter your email");
      return;
    }

    try {
      await supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'io.supabase.seerahtimeline://login-callback/',
      );

      if (mounted) {
        _showToast("Magic link sent! Check your email.", isError: false);
      }
    } on AuthException catch (e) {
      if (mounted) {
        _showToast(e.message);
      }
    } catch (e) {
      if (mounted) {
        _showToast("Failed to send magic link.");
      }
    }
  }

  void _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showToast("Please enter your email to reset password.");
      return;
    }

    try {
      await authService.resetPassword(email);
      if (mounted) {
        _showToast("Password reset link sent! Check your email.", isError: false);
      }
    } catch (e) {
      if (mounted) {
        _showToast("Failed to send reset link: ${e.toString()}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? const Color(0xFF121212) : AppColors.scaffoldBackground;
    final panelColor = isDark ? const Color(0xFF1E1E1E) : Colors.white.withOpacity(0.9);
    final titlePrimary = isDark ? Colors.white : AppColors.primary;
    final subtitleColor = isDark ? Colors.white70 : const Color(0xFF6B7280);
    final mutedText = isDark ? Colors.white70 : Colors.black54;
    final socialButtonColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final socialButtonText = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: background,
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              colors: isDark
                  ? const [
                      Color(0xFF171717),
                      Color(0xFF121212),
                      Color(0xFF121212),
                    ]
                  : const [
                      AppColors.backgroundMint,
                      AppColors.backgroundMint,
                      AppColors.backgroundMint,
                    ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 48),

              // Logo - no background container
              Image.asset(
                'assets/images/login_logo_cropped.png',
                width: 130,
                height: 130,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Welcome ',
                            style: TextStyle(
                              color: titlePrimary,
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: 'Back',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Continue your Seerah journey",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: subtitleColor, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              //  Reusable Login Box
              Center(
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: panelColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        offset: Offset(0, 4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomTextField(
                          hintText: 'Email',
                          prefixIcon: Icons.email_outlined,
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please enter your email";
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return "Please enter a valid email";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          hintText: 'Password',
                          prefixIcon: Icons.lock_outline,
                          obscureText: true,
                          controller: _passwordController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Please enter your password";
                            }
                            if (value.length < 6) {
                              return "Password must be at least 6 characters";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: _handleForgotPassword,
                            child: Text(
                              "Forgot Password?",
                              style: TextStyle(
                                color: titlePrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                             Text(
                              "Don't have an account? ",
                              style: TextStyle(color: mutedText),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SignupScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                "Create account",
                                style: TextStyle(
                                  color: isDark ? AppColors.accent : const Color.fromARGB(255, 220, 127, 12),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0D9488),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _isLoading ? null : login,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "Login",
                                    style: TextStyle(
                                        fontSize: 18, color: Colors.white),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Google OAuth Button
              Center(
                child: SizedBox(
                  width: 280,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: socialButtonColor,
                      foregroundColor: socialButtonText,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () async {
                      try {
                        await authService.signInWithGoogle();
                      } catch (e) {
                        if (mounted) {
                          _showToast("Error: ${e.toString()}");
                        }
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipOval(
                          child: Container(
                            width: 24,
                            height: 24,
                            color: Colors.white,
                            padding: const EdgeInsets.all(2),
                            child: Image.asset(
                              'assets/images/google.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                child: Text(
                                  'G',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Continue with Google",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Facebook OAuth Button
              Center(
                child: SizedBox(
                  width: 280,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: socialButtonColor,
                      foregroundColor: socialButtonText,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 2,
                    ),
                    onPressed: () async {
                      try {
                        await authService.signInWithFacebook();
                      } catch (e) {
                        if (mounted) {
                          _showToast("Error: ${e.toString()}");
                        }
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipOval(
                          child: Container(
                            width: 24,
                            height: 24,
                            color: Colors.white,
                            padding: const EdgeInsets.all(2),
                            child: Image.asset(
                              'assets/images/facebook.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Center(
                                child: Text(
                                  'f',
                                  style: TextStyle(
                                    color: Color(0xFF1877F2),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          "Continue with Facebook",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
