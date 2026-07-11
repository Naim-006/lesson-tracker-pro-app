import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers/supabase_pupil_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/error_handler.dart';
import '../auth/onboarding_screen.dart';

class PupilSettingsScreen extends ConsumerStatefulWidget {
  const PupilSettingsScreen({super.key});

  @override
  ConsumerState<PupilSettingsScreen> createState() => _PupilSettingsScreenState();
}

class _PupilSettingsScreenState extends ConsumerState<PupilSettingsScreen> {
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _instructor;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final profileRes = await Supabase.instance.client
          .from('profiles')
          .select('*')
          .eq('id', user.id)
          .single();

      final linkRes = await Supabase.instance.client
          .from('instructor_pupil_links')
          .select('instructors:profiles!instructor_id(full_name, business_name, phone, email)')
          .eq('pupil_id', user.id)
          .eq('status', 'active')
          .maybeSingle();

      if (mounted) {
        setState(() {
          _profile = profileRes;
          _instructor = linkRes?['instructors'] as Map<String, dynamic>?;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editProfile() async {
    final nameCtrl = TextEditingController(text: _profile?['full_name'] as String? ?? '');
    final phoneCtrl = TextEditingController(text: _profile?['phone'] as String? ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Full name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: phoneCtrl,
                decoration: InputDecoration(
                  labelText: 'Phone number',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.sunsetBright),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (saved != true) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client
          .from('profiles')
          .update({
            'full_name': nameCtrl.text.trim(),
            'phone': phoneCtrl.text.trim(),
          })
          .eq('id', user.id);

      ref.invalidate(pupilProfileProvider);
      if (mounted) {
        setState(() {
          _profile?['full_name'] = nameCtrl.text.trim();
          _profile?['phone'] = phoneCtrl.text.trim();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFriendlyError(e))),
        );
      }
    }
  }

  void _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = Supabase.instance.client.auth.currentUser;
    final name = _profile?['full_name'] as String? ?? 'Pupil';
    final email = user?.email ?? '';
    final phone = _profile?['phone'] as String? ?? '';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF6F4F0),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBg : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        title: const Text('Settings'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.sunsetBright))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.sunsetBright, Color(0xFFE85D3A)]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: AppColors.sunsetBright.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(18)),
                        child: Center(
                          child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3)),
                            const SizedBox(height: 4),
                            Text(email, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _SettingsSection(
                  title: 'Profile',
                  icon: Icons.person_outline,
                  children: [
                    _SettingsTile(
                      icon: Icons.edit_outlined,
                      title: 'Edit Profile',
                      subtitle: phone.isNotEmpty ? '$name · $phone' : 'Add your name and phone',
                      onTap: _editProfile,
                    ),
                    _SettingsTile(
                      icon: Icons.email_outlined,
                      title: 'Email',
                      subtitle: email,
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_instructor != null)
                  _SettingsSection(
                    title: 'Your Instructor',
                    icon: Icons.school_outlined,
                    children: [
                      _SettingsTile(
                        icon: Icons.person_outlined,
                        title: _instructor!['full_name'] as String? ?? 'Instructor',
                        subtitle: _instructor!['business_name'] as String? ?? '',
                        onTap: () {},
                      ),
                      if (_instructor!['phone'] != null)
                        _SettingsTile(
                          icon: Icons.phone_outlined,
                          title: _instructor!['phone'] as String,
                          subtitle: 'Phone',
                          onTap: () {},
                        ),
                    ],
                  ),
                const SizedBox(height: 16),
                _SettingsSection(
                  title: 'Account',
                  icon: Icons.lock_outline,
                  children: [
                    _SettingsTile(
                      icon: Icons.logout,
                      title: 'Sign Out',
                      subtitle: 'Log out of your account',
                      iconColor: AppColors.error,
                      titleColor: AppColors.error,
                      onTap: _signOut,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.icon, required this.children});
  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder.withValues(alpha: 0.3) : AppColors.lightBorder.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.sunsetBright),
                const SizedBox(width: 10),
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkText : AppColors.lightText)),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? AppColors.darkBorder.withValues(alpha: 0.3) : AppColors.lightBorder.withValues(alpha: 0.6)),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.icon, required this.title, required this.subtitle, required this.onTap, this.iconColor, this.titleColor});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? AppColors.darkText : AppColors.lightText;
    return ListTile(
      leading: Icon(icon, size: 22, color: iconColor ?? AppColors.sunsetBright.withValues(alpha: 0.8)),
      title: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: titleColor ?? defaultColor)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkMuted : AppColors.lightMuted)),
      trailing: Icon(Icons.chevron_right, size: 20, color: isDark ? AppColors.darkMuted : AppColors.lightMuted),
      onTap: onTap,
    );
  }
}
