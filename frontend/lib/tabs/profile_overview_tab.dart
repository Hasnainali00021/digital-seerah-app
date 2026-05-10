import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seerah_timeline/auth/auth_service.dart';
import 'package:seerah_timeline/constants/app_colors.dart';
import 'package:seerah_timeline/main.dart';
import 'package:seerah_timeline/providers/providers.dart';
import 'package:seerah_timeline/tabs/profile_tab.dart';

class ProfileOverviewTab extends ConsumerStatefulWidget {
  const ProfileOverviewTab({super.key});

  @override
  ConsumerState<ProfileOverviewTab> createState() => _ProfileOverviewTabState();
}

class _ProfileOverviewTabState extends ConsumerState<ProfileOverviewTab> {
  String _username = '';
  String _email = '';
  String? _imageUrl;
  bool _loading = true;

  static const _profileUsernameKey = 'cached_profile_username';
  static const _profileEmailKey    = 'cached_profile_email';
  static const _profileAvatarKey   = 'cached_profile_avatar';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();

    // ── Step 1: Load profile from local cache immediately (works offline) ───
    final cachedName   = prefs.getString(_profileUsernameKey);
    final cachedEmail  = prefs.getString(_profileEmailKey);
    final cachedAvatar = prefs.getString(_profileAvatarKey);

    if (mounted && cachedName != null) {
      setState(() {
        _username = cachedName;
        _email    = cachedEmail ?? supabase.auth.currentUser?.email ?? '';
        _imageUrl = cachedAvatar;
        _loading  = false; // Show content immediately from cache
      });
    }

    // ── Step 2: Fetch fresh from Supabase (if online) ────────────────────────
    try {
      final userId = supabase.auth.currentUser!.id;
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (mounted && data != null) {
        final name   = data['username'] as String? ?? 'Explorer';
        final email  = data['email']    as String? ?? supabase.auth.currentUser?.email ?? '';
        final avatar = data['avatar_url'] as String?;

        // Save fresh data to local cache for next offline visit
        await prefs.setString(_profileUsernameKey, name);
        await prefs.setString(_profileEmailKey, email);
        if (avatar != null) await prefs.setString(_profileAvatarKey, avatar);

        setState(() {
          _username        = name;
          _email           = email;
          _imageUrl        = avatar;
          _loading         = false;
        });
      }
    } catch (e) {
      // Network failed — already showing cached data, just hide spinner
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    // Watch providers directly so the widget rebuilds immediately on any change
    final favorites = ref.watch(favoritesProvider);
    final readEvents = ref.watch(readEventsProvider);
    final lastQuizResult = ref.watch(lastQuizResultProvider);

    // ref.watch on these providers ensures the widget rebuilds live whenever
    // the user reads a new event or adds a favourite — even on return from push.

    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF2F8F5);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final subColor = isDark ? Colors.white60 : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bgColor,
      body: _loading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async => await _loadProfile(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // ── Hero Header ──────────────────────────────────────────
                    _buildHeader(isDark, textColor, subColor),

                    const SizedBox(height: 24),

                    // ── Stats Row ────────────────────────────────────────────
                    _buildStatsRow(
                      isDark,
                      cardColor,
                      textColor,
                      subColor,
                      favorites,
                      readEvents,
                      lastQuizResult,
                    ),

                    const SizedBox(height: 24),

                    // ── Account Settings ─────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionLabel('Account', subColor),
                          const SizedBox(height: 10),
                          _buildSettingsCard(isDark, cardColor, textColor, [
                            _SettingItem(
                              icon: Iconsax.edit,
                              iconColor: AppColors.primary,
                              label: 'Edit Profile',
                              sublabel: 'Update name, email & avatar',
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ProfileTab(),
                                  ),
                                ).then((_) => _loadProfile());
                              },
                            ),
                          ]),

                          const SizedBox(height: 20),
                          _sectionLabel('Preferences', subColor),
                          const SizedBox(height: 10),
                          _buildSettingsCard(isDark, cardColor, textColor, [
                            _SettingItem(
                              icon: isDark ? Iconsax.moon : Iconsax.sun_1,
                              iconColor:
                                  isDark ? Colors.indigo : Colors.amber.shade600,
                              label: 'Dark Mode',
                              sublabel: isDark ? 'Currently Dark' : 'Currently Light',
                              trailing: Switch(
                                value: isDark,
                                onChanged: (_) =>
                                    ref.read(themeModeProvider.notifier).toggle(),
                                activeColor: AppColors.primary,
                              ),
                            ),
                          ]),

                          const SizedBox(height: 20),
                          _sectionLabel('Session', subColor),
                          const SizedBox(height: 10),
                          _buildSettingsCard(isDark, cardColor, textColor, [
                            _SettingItem(
                              icon: Iconsax.logout,
                              iconColor: Colors.red,
                              label: 'Sign Out',
                              sublabel: 'Log out from your account',
                              labelColor: Colors.red,
                              onTap: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: cardColor,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    title: Text('Sign Out',
                                        style: TextStyle(
                                            color: textColor,
                                            fontWeight: FontWeight.bold)),
                                    content: Text(
                                      'Are you sure you want to sign out?',
                                      style: TextStyle(color: subColor),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: Text('Cancel',
                                            style: TextStyle(color: subColor)),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                        ),
                                        child: const Text('Sign Out',
                                            style: TextStyle(
                                                color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true && context.mounted) {
                                  await AuthService().signOut();
                                }
                              },
                            ),
                          ]),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader(bool isDark, Color textColor, Color subColor) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0A5C57), const Color(0xFF0D9488)]
              : [const Color(0xFF0D9488), const Color(0xFF14B8A6)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          child: Column(
            children: [
              // Top bar: Title + Edit button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ProfileTab()),
                      ).then((_) => _loadProfile());
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Iconsax.edit, color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Edit',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Avatar
              Stack(
                alignment: Alignment.center,
                children: [
                  // Glow ring
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
                    ),
                  ),
                  // ClipOval + CachedNetworkImage: disk-cached, persists across restarts
                  ClipOval(
                    key: ValueKey(_imageUrl ?? 'no-avatar'),
                    child: Container(
                      width: 88,
                      height: 88,
                      color: Colors.white.withOpacity(0.25),
                      child: _imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: _imageUrl!,
                              fit: BoxFit.cover,
                              width: 88,
                              height: 88,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              errorWidget: (context, url, error) => Center(
                                child: Text(
                                  _username.isNotEmpty
                                      ? _username[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                _username.isNotEmpty
                                    ? _username[0].toUpperCase()
                                    : 'U',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Name
              Text(
                _username.isNotEmpty ? _username : 'Explorer',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _email,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),

              // Badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Iconsax.medal, color: Color(0xFFFBBF24), size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Seerah Explorer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow(
    bool isDark,
    Color cardColor,
    Color textColor,
    Color subColor,
    List<String> favorites,
    List<String> readEvents,
    LastQuizResult? lastQuizResult,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _statCard(
            isDark: isDark,
            cardColor: cardColor,
            textColor: textColor,
            subColor: subColor,
            icon: Iconsax.heart,
            iconColor: Colors.pinkAccent,
            value: '${favorites.length}',
            label: 'Favorites',
          ),
          const SizedBox(width: 12),
          _statCard(
            isDark: isDark,
            cardColor: cardColor,
            textColor: textColor,
            subColor: subColor,
            icon: Iconsax.book_1,
            iconColor: AppColors.primary,
            value: '${readEvents.length}',
            label: 'Events Read',
          ),
          const SizedBox(width: 12),
          _statCard(
            isDark: isDark,
            cardColor: cardColor,
            textColor: textColor,
            subColor: subColor,
            icon: Iconsax.star,
            iconColor: Colors.amber,
            value: lastQuizResult == null
                ? '—'
                : '${lastQuizResult.score}/${lastQuizResult.total}',
            label: 'Quiz Score',
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color subColor,
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: subColor, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, Color color) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSettingsCard(bool isDark, Color cardColor, Color textColor,
      List<_SettingItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          return Column(
            children: [
              ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, color: item.iconColor, size: 20),
                ),
                title: Text(
                  item.label,
                  style: TextStyle(
                    color: item.labelColor ?? textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                subtitle: item.sublabel != null
                    ? Text(
                        item.sublabel!,
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.grey,
                          fontSize: 12,
                        ),
                      )
                    : null,
                trailing: item.trailing ??
                    (item.onTap != null
                        ? Icon(
                            Iconsax.arrow_right_3,
                            color: isDark ? Colors.white38 : Colors.grey,
                            size: 18,
                          )
                        : null),
                onTap: item.onTap,
              ),
              if (index < items.length - 1)
                Divider(
                  height: 1,
                  indent: 56,
                  endIndent: 16,
                  color: isDark ? Colors.white12 : Colors.grey.shade100,
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _SettingItem {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? sublabel;
  final Color? labelColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.sublabel,
    this.labelColor,
    this.trailing,
    this.onTap,
  });
}
