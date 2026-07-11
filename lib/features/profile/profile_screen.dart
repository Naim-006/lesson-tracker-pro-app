import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers/app_state_provider.dart';
import '../../core/theme/app_colors.dart';
import '../auth/role_selection_screen.dart';
import '../finances/export_form_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _titleCtrl;
  late TextEditingController _businessCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  bool _savingProfile = false;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    _nameCtrl = TextEditingController(text: s.instructorName);
    _titleCtrl = TextEditingController(text: s.instructorTitle);
    _businessCtrl = TextEditingController(text: s.businessName);
    _phoneCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _titleCtrl.dispose();
    _businessCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select('full_name, phone, email, business_name')
          .eq('id', user.id)
          .single();
      if (!mounted) return;
      _nameCtrl.text = res['full_name'] ?? '';
      _businessCtrl.text = res['business_name'] ?? '';
      _phoneCtrl.text = res['phone'] ?? '';
      _emailCtrl.text = res['email'] ?? user.email ?? '';
      setState(() {});
    } catch (_) {}
  }

  Future<void> _saveProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    setState(() => _savingProfile = true);
    try {
      await Supabase.instance.client.from('profiles').update({
        'full_name': _nameCtrl.text.trim(),
        'business_name': _businessCtrl.text.trim().isEmpty ? null : _businessCtrl.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      final settings = ref.read(settingsProvider);
      await ref.read(settingsProvider.notifier).update(settings.copyWith(
        instructorName: _nameCtrl.text.trim(),
        instructorTitle: _titleCtrl.text.trim(),
        businessName: _businessCtrl.text.trim(),
      ));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved'), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _savingProfile = false);
    }
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                  (route) => false,
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Widget _tf(String label, TextEditingController ctrl, {IconData? icon, bool obscure = false, bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: ctrl,
        readOnly: readOnly,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon) : null,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          filled: readOnly,
          fillColor: Colors.grey.shade100,
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.sunsetBright.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.sunsetBright, size: 18),
        ),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
      ],
    );
  }

  Widget _card(Widget child) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      surfaceTintColor: Colors.transparent,
      child: ClipRRect(borderRadius: BorderRadius.circular(16), child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF8F6F2),
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionHeader('Instructor Profile', Icons.person),
          const SizedBox(height: 12),
          _card(Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _tf('Full Name', _nameCtrl, icon: Icons.person),
                _tf('Phone Number', _phoneCtrl, icon: Icons.phone, readOnly: true),
                _tf('Email', _emailCtrl, icon: Icons.email, readOnly: true),
                _tf('Qualification / Title', _titleCtrl, icon: Icons.badge),
                _tf('Business Name (optional)', _businessCtrl, icon: Icons.business),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _savingProfile ? null : _saveProfile,
                  icon: _savingProfile
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded, size: 18),
                  label: const Text('Save Profile'),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.sunsetBright),
                ),
              ],
            ),
          )),
          const SizedBox(height: 24),

          _sectionHeader('App Settings', Icons.tune),
          const SizedBox(height: 12),
          _card(Column(
            children: [
              ListTile(
                title: const Text('Currency'),
                trailing: const Text('GBP', style: TextStyle(fontSize: 14, color: Colors.grey)),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Timezone'),
                trailing: DropdownButton<String>(
                  value: settings.timezone,
                  items: const ['Europe/London', 'Europe/Dublin', 'America/New_York', 'Australia/Sydney']
                      .map((z) => DropdownMenuItem(value: z, child: Text(z)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) ref.read(settingsProvider.notifier).update(settings.copyWith(timezone: v));
                  },
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Push notifications'),
                value: settings.notificationsEnabled,
                onChanged: (v) => ref.read(settingsProvider.notifier).update(settings.copyWith(notificationsEnabled: v)),
                activeThumbColor: AppColors.sunsetBright,
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Email notifications'),
                value: settings.emailNotifications,
                onChanged: (v) => ref.read(settingsProvider.notifier).update(settings.copyWith(emailNotifications: v)),
                activeThumbColor: AppColors.sunsetBright,
              ),
            ],
          )),
          const SizedBox(height: 24),

          _card(ListTile(
            title: const Text('Export all data'),
            subtitle: const Text('Backup your data to a file'),
            leading: const Icon(Icons.download, color: AppColors.sunsetBright),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExportFormScreen())),
          )),
          const SizedBox(height: 12),

          _card(ListTile(
            title: const Text('Sign out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
            leading: const Icon(Icons.logout, color: AppColors.error),
            onTap: _showSignOutDialog,
          )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
