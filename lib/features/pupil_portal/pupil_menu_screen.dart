import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../auth/onboarding_screen.dart';
import 'pupil_settings_screen.dart';
import 'pupil_payment_screen.dart';
import 'pupil_resources_screen.dart';
import 'nearby_tutors_screen.dart';
import 'pupil_enquiry_screen.dart';

class PupilMenuScreen extends StatefulWidget {
  const PupilMenuScreen({super.key});

  @override
  State<PupilMenuScreen> createState() => _PupilMenuScreenState();
}

class _PupilMenuScreenState extends State<PupilMenuScreen> {
  final _user = Supabase.instance.client.auth.currentUser;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (_user == null) return;
    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select('*')
          .eq('id', _user!.id)
          .single();
      if (mounted) setState(() => _profile = res);
    } catch (_) {}
  }

  String _displayName() {
    final first = _profile?['first_name'] as String?;
    final last = _profile?['last_name'] as String?;
    if (first != null && last != null) return '$first $last';
    return first ?? _profile?['full_name'] ?? 'Pupil';
  }

  String _initials() {
    final name = _displayName();
    return name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      child: Column(
        children: [
          // Profile card
          _buildProfileCard(isDark),
          const SizedBox(height: 20),

          // Account section
          _buildSection('Account', [
            _MenuItem(icon: Icons.person_outline_rounded, label: 'Edit Profile', onTap: () {}),
            _MenuItem(icon: Icons.payment_rounded, label: 'Payments', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PupilPaymentScreen()))),
            _MenuItem(icon: Icons.receipt_long_rounded, label: 'Resources', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PupilResourcesScreen()))),
          ], isDark),

          const SizedBox(height: 16),

          // Discover section
          _buildSection('Discover', [
            _MenuItem(icon: Icons.search_rounded, label: 'Find Tutors', color: const Color(0xFF8B5CF6), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NearbyTutorsScreen()))),
            _MenuItem(icon: Icons.mail_rounded, label: 'Send Enquiry', color: const Color(0xFF3B82F6), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PupilEnquiryScreen()))),
          ], isDark),

          const SizedBox(height: 16),

          // Settings section
          _buildSection('Settings', [
            _MenuItem(icon: Icons.settings_rounded, label: 'Preferences', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PupilSettingsScreen()))),
            _MenuItem(icon: Icons.help_outline_rounded, label: 'Help & Support', onTap: () {}),
            _MenuItem(icon: Icons.info_outline_rounded, label: 'About', onTap: () => _showAbout(isDark)),
          ], isDark),

          const SizedBox(height: 16),

          // Sign out
          _buildSignOut(isDark),

          const SizedBox(height: 24),

          // Footer
          _buildFooter(isDark),
        ],
      ),
    );
  }

  Widget _buildProfileCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [AppColors.sunsetBright, const Color(0xFFE85D3A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.sunsetBright.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Center(
              child: Text(
                _initials(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName(),
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _user?.email ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.8), size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<_MenuItem> items, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.grey.shade400,
              ),
            ),
          ),
          ...items.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            final isLast = i == items.length - 1;
            return _MenuTile(
              item: item,
              isDark: isDark,
              showDivider: !isLast,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSignOut(bool isDark) {
    return GestureDetector(
      onTap: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Sign Out'),
            content: const Text('Are you sure you want to sign out?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                child: const Text('Sign Out'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await Supabase.instance.client.auth.signOut();
          if (!mounted) return;
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const OnboardingScreen()));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: isDark ? 0.08 : 0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
            const SizedBox(width: 8),
            Text(
              'Sign Out',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Column(
      children: [
        Text(
          'Lesson Tracker v1.0',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Developed by NextByte',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.grey.shade300,
          ),
        ),
      ],
    );
  }

  void _showAbout(bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('About Lesson Tracker'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.sunsetBright, Color(0xFFE85D3A)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.school_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('Lesson Tracker Pro', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              'Professional driving instructor platform.\nManage lessons, track progress, and more.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            Text(
              'Developed by NextByte\nWhatsApp: +880 1984-862536',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(backgroundColor: AppColors.sunsetBright),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  _MenuItem({required this.icon, required this.label, this.color, required this.onTap});
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.item, required this.isDark, required this.showDivider});
  final _MenuItem item;
  final bool isDark;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final itemColor = item.color ?? (isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black87);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: (item.color ?? AppColors.sunsetBright).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.icon, size: 20, color: item.color ?? AppColors.sunsetBright),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: itemColor,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.grey.shade300,
                  ),
                ],
              ),
            ),
            if (!showDivider)
              Divider(
                height: 1,
                indent: 66,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
          ],
        ),
      ),
    );
  }
}
