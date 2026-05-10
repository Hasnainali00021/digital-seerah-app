import 'package:flutter/material.dart';
import 'package:seerah_timeline/constants/app_colors.dart';
import 'package:seerah_timeline/screen/login_screen.dart';
import 'package:seerah_timeline/widget/custom_text_field.dart';
import 'package:seerah_timeline/services/validators.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final password = _passwordController.text.trim();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );

      // Sign out the recovery session so user can log in fresh
      await Supabase.instance.client.auth.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Password updated! Please log in with your new password.',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 3),
          ),
        );
        // Navigate to Login screen and clear navigation stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.message}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: isDark ? Colors.red.shade400 : Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString()}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: isDark ? Colors.red.shade400 : Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Set New Password', style: TextStyle(color: Colors.white)),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  offset: Offset(0, 4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_reset, size: 60, color: AppColors.primary),
                  const SizedBox(height: 16),
                  const Text(
                    "Reset Password",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Please securely enter your new password.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  CustomTextField(
                    hintText: 'New Password',
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                    controller: _passwordController,
                    validator: Validators.validatePassword,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    hintText: 'Confirm Password',
                    prefixIcon: Icons.lock,
                    obscureText: true,
                    controller: _confirmController,
                    validator: (value) => Validators.validateConfirmPassword(
                        value, _passwordController.text),
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const CircularProgressIndicator(color: AppColors.primary)
                      : SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _updatePassword,
                            child: const Text('Save Password', style: TextStyle(fontSize: 16, color: Colors.white)),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
