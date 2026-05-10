import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:seerah_timeline/auth/auth_service.dart';
import 'package:seerah_timeline/constants/app_colors.dart';
import 'package:seerah_timeline/main.dart';
import 'package:seerah_timeline/screen/login_screen.dart';
import 'package:seerah_timeline/widget/profile_input_field.dart';
import 'package:seerah_timeline/widget/custom_back_button.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:iconsax/iconsax.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  String? _imageUrl;
  Uint8List? _localImageBytes; // Local bytes for instant preview after upload
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _getInitialProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _getInitialProfile() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (data != null && mounted) {
        setState(() {
          _usernameController.text = data['username'] ?? '';
          _emailController.text = data['email'] ?? '';
          _imageUrl = data['avatar_url'];
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (image == null) return;

    // Read bytes immediately for local preview
    final imageBytes = await image.readAsBytes();

    // Show uploading feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uploading image...'),
          duration: Duration(seconds: 15),
          backgroundColor: AppColors.primary,
        ),
      );
    }

    try {
      final imageExtension = image.path.split('.').last.toLowerCase();
      final userId = supabase.auth.currentUser!.id;
      final imagePath = '$userId/profile.$imageExtension';

      await supabase.storage.from('avatars').uploadBinary(
            imagePath,
            imageBytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: 'image/$imageExtension',
            ),
          );

      // Append version timestamp — makes every upload a unique cache key
      // for CachedNetworkImage (same file path, but new URL = fresh download)
      final imageUrl =
          '${supabase.storage.from('avatars').getPublicUrl(imagePath)}'
          '?v=${DateTime.now().millisecondsSinceEpoch}';

      // Save versioned URL to profiles table
      await supabase
          .from('profiles')
          .update({'avatar_url': imageUrl}).eq('id', userId);

      if (mounted) {
        // Show local bytes instantly — no network request needed
        setState(() {
          _localImageBytes = imageBytes;
          _imageUrl = imageUrl;
        });
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Avatar updated successfully!'),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();

    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username cannot be empty')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final userId = supabase.auth.currentUser!.id;
      await supabase
          .from('profiles')
          .update({'username': username, 'email': email}).eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Profile updated successfully!'),
            backgroundColor: Color(0xFF0D9488),
          ),
        );
        Navigator.pop(context); // Return to overview
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? const Color(0xFF121212) : AppColors.scaffoldBackground;
    final headerGradient = isDark
        ? const [Color(0xFF1A1A1A), Color(0xFF151515)]
        : const [Color(0xFF0D9488), Color(0xFF14B8A6)];
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final subColor = isDark ? Colors.white70 : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : AppColors.primary,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: const CustomBackButton(color: Colors.white),
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Avatar Picker ─────────────────────────────────────────────
            Center(
              child: Stack(
                children: [
                  GestureDetector(
                    onTap: _pickAndUploadAvatar,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: headerGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(isDark ? 0.2 : 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: _localImageBytes != null
                          // 1st priority: show local bytes instantly after upload
                          ? ClipOval(
                              child: Image.memory(
                                _localImageBytes!,
                                fit: BoxFit.cover,
                                width: 110,
                                height: 110,
                              ),
                            )
                          : _imageUrl != null
                              // 2nd priority: CachedNetworkImage — disk cached, persists across restarts
                              ? ClipOval(
                                  key: ValueKey(_imageUrl),
                                  child: CachedNetworkImage(
                                    imageUrl: _imageUrl!,
                                    fit: BoxFit.cover,
                                    width: 110,
                                    height: 110,
                                    placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    errorWidget: (context, url, error) {
                                      debugPrint('Avatar load error: $error\nURL: $url');
                                      return _avatarInitials();
                                    },
                                  ),
                                )
                              // 3rd priority: show initials
                              : _avatarInitials(),
                    ),
                  ),
                  // Camera badge
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickAndUploadAvatar,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Iconsax.camera,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            Text(
              'Tap avatar to change photo',
              style: TextStyle(
                color: subColor,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 32),

            // ── Form Card ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black54 : Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personal Information',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0D9488),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ProfileInputField(
                    controller: _usernameController,
                    hintText: 'Username',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 12),
                  ProfileInputField(
                    controller: _emailController,
                    hintText: 'Email',
                    icon: Icons.email_outlined,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Save Button ──────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: AppColors.primary.withOpacity(0.4),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Iconsax.save_2, color: Colors.white, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Save Changes',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Sign Out ─────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: () async {
                  await AuthService().signOut();
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red, width: 1.5),
                  foregroundColor: isDark ? Colors.white : Colors.red,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.logout, color: Colors.red, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Sign Out',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _avatarInitials() {
    final name = _usernameController.text;
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: const TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
