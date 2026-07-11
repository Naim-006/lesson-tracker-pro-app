import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/models.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/theme/app_colors.dart';

import '../../features/auth/role_selection_screen.dart';
import 'vehicles_screen.dart';
import 'work_hours_screen.dart';
import '../finances/export_form_screen.dart';
import 'pricing_packages_screen.dart';
import 'lesson_lengths_screen.dart';
import 'progress_syllabus_screen.dart';
import 'your_terms_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _name;
  late TextEditingController _title;
  late TextEditingController _businessName;
  late TextEditingController _termsText;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final s = ref.read(settingsProvider);
    _name = TextEditingController(text: s.instructorName);
    _title = TextEditingController(text: s.instructorTitle);
    _businessName = TextEditingController(text: s.businessName);
    _termsText = TextEditingController(text: s.termsAndConditions);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _name.dispose();
    _title.dispose();
    _businessName.dispose();
    _termsText.dispose();
    super.dispose();
  }

  Future<void> _save(AppSettings s) async {
    await ref.read(settingsProvider.notifier).update(s);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.sunsetBright,
          indicatorColor: AppColors.sunsetBright,
          tabs: const [
            Tab(text: 'BUSINESS'),
            Tab(text: 'TEACHING'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _BusinessTab(settings: s, nameController: _name, titleController: _title, businessNameController: _businessName, termsController: _termsText, onSave: _save),
          _TeachingTab(settings: s, onSave: _save),
        ],
      ),
    );
  }
}

class _BusinessTab extends StatelessWidget {
  const _BusinessTab({
    required this.settings,
    required this.nameController,
    required this.titleController,
    required this.businessNameController,
    required this.termsController,
    required this.onSave,
  });

  final AppSettings settings;
  final TextEditingController nameController;
  final TextEditingController titleController;
  final TextEditingController businessNameController;
  final TextEditingController termsController;
  final Future<void> Function(AppSettings) onSave;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Pricing
        _SectionHeader(title: 'Pricing', icon: Icons.attach_money),
        const SizedBox(height: 12),
        _SettingsCard(
          child: ListTile(
            title: const Text('Pricing & Packages'),
            subtitle: const Text('Hourly rates, lesson packages'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PricingPackagesScreen()),
              );
            },
          ),
        ),
        const SizedBox(height: 24),

        // Lesson Lengths
        _SectionHeader(title: 'Lesson Lengths', icon: Icons.schedule),
        const SizedBox(height: 12),
        _SettingsCard(
          child: ListTile(
            title: const Text('Manage lesson lengths'),
            subtitle: const Text('Configure available lesson durations'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LessonLengthsScreen()),
              );
            },
          ),
        ),
        const SizedBox(height: 24),

        // Vehicles
        _SectionHeader(title: 'Vehicles', icon: Icons.directions_car),
        const SizedBox(height: 12),
        _SettingsCard(
          child: ListTile(
            title: const Text('Manage vehicles'),
            subtitle: const Text('Add or edit your teaching vehicles'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VehiclesScreen()),
              );
            },
          ),
        ),
        const SizedBox(height: 24),

        // Work Hours
        _SectionHeader(title: 'Work Hours', icon: Icons.access_time),
        const SizedBox(height: 12),
        _SettingsCard(
          child: ListTile(
            title: const Text('Working days'),
            subtitle: const Text('Configure your weekly schedule'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WorkHoursScreen()),
              );
            },
          ),
        ),
        const SizedBox(height: 24),

        // Terms
        _SectionHeader(title: 'Terms & Conditions', icon: Icons.description),
        const SizedBox(height: 12),
        _SettingsCard(
          child: ListTile(
            title: const Text('Your terms'),
            subtitle: const Text('Cancellation period, terms document'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const YourTermsScreen()),
              );
            },
          ),
        ),
        const SizedBox(height: 24),

        // COVID
        _SectionHeader(title: 'COVID-19 Policy', icon: Icons.health_and_safety),
        const SizedBox(height: 12),
        _SettingsCard(
          child: SwitchListTile(
            title: const Text('COVID safety measures'),
            subtitle: const Text('Display safety reminders to pupils'),
            value: settings.covidSafetyEnabled,
            onChanged: (v) => onSave(settings.copyWith(covidSafetyEnabled: v)),
            activeThumbColor: AppColors.sunsetBright,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

}

class _TeachingTab extends StatelessWidget {
  const _TeachingTab({
    required this.settings,
    required this.onSave,
  });

  final AppSettings settings;
  final Future<void> Function(AppSettings) onSave;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Progress Syllabus Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.sunsetBright.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.assessment, color: AppColors.sunsetBright, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('Progress Syllabus', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: const Text('Enable progress tracking', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Track pupil skill development'),
                  value: settings.progressTrackingEnabled,
                  onChanged: (v) => onSave(settings.copyWith(progressTrackingEnabled: v)),
                  activeThumbColor: AppColors.sunsetBright,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: const Text('Manage syllabus', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Categories, scoring, drag-to-reorder'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProgressSyllabusScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Theory Test Integration Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.sunsetBright.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.quiz, color: AppColors.sunsetBright, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('Theory Test Integration', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: const Text('DVSA theory test sync', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Import theory test results'),
                  value: settings.theoryTestSyncEnabled,
                  onChanged: (v) => onSave(settings.copyWith(theoryTestSyncEnabled: v)),
                  activeThumbColor: AppColors.sunsetBright,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: const Text('Theory test provider', style: TextStyle(fontWeight: FontWeight.w700)),
                  trailing: DropdownButton<String>(
                    value: settings.theoryTestProvider,
                    items: const ['DVSA', 'Official DVSA', 'gov.uk', 'Other']
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) onSave(settings.copyWith(theoryTestProvider: v));
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _AccountTab extends ConsumerStatefulWidget {
  const _AccountTab({
    required this.settings,
    required this.onSave,
    required this.nameController,
    required this.titleController,
    required this.businessNameController,
  });

  final AppSettings settings;
  final Future<void> Function(AppSettings) onSave;
  final TextEditingController nameController;
  final TextEditingController titleController;
  final TextEditingController businessNameController;

  @override
  ConsumerState<_AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends ConsumerState<_AccountTab> {
  bool _savingProfile = false;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _bankSortCodeCtrl;
  late TextEditingController _bankAccountCtrl;
  late TextEditingController _bankNameCtrl;
  late TextEditingController _monzoLinkCtrl;
  late TextEditingController _paypalCtrl;

  @override
  void initState() {
    super.initState();
    _phoneCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _bankSortCodeCtrl = TextEditingController();
    _bankAccountCtrl = TextEditingController();
    _bankNameCtrl = TextEditingController();
    _monzoLinkCtrl = TextEditingController();
    _paypalCtrl = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _bankSortCodeCtrl.dispose();
    _bankAccountCtrl.dispose();
    _bankNameCtrl.dispose();
    _monzoLinkCtrl.dispose();
    _paypalCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final res = await Supabase.instance.client
          .from('profiles')
          .select('full_name, phone, email, business_name, payment_info')
          .eq('id', user.id)
          .single();
      if (!mounted) return;
      widget.nameController.text = res['full_name'] ?? '';
      widget.businessNameController.text = res['business_name'] ?? '';
      _phoneCtrl.text = res['phone'] ?? '';
      _emailCtrl.text = res['email'] ?? user.email ?? '';
      final info = (res['payment_info'] as Map<String, dynamic>?) ?? {};
      _bankSortCodeCtrl.text = info['sort_code'] ?? '';
      _bankAccountCtrl.text = info['account_number'] ?? '';
      _bankNameCtrl.text = info['bank_name'] ?? '';
      _monzoLinkCtrl.text = info['monzo_link'] ?? '';
      _paypalCtrl.text = info['paypal'] ?? '';
      setState(() {});
    } catch (_) {}
  }

  Future<void> _saveProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    setState(() { _savingProfile = true; });
    try {
      await Supabase.instance.client.from('profiles').update({
        'full_name': widget.nameController.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'business_name': widget.businessNameController.text.trim().isEmpty
            ? null : widget.businessNameController.text.trim(),
        'payment_info': {
          'sort_code': _bankSortCodeCtrl.text.trim(),
          'account_number': _bankAccountCtrl.text.trim(),
          'bank_name': _bankNameCtrl.text.trim(),
          'monzo_link': _monzoLinkCtrl.text.trim(),
          'paypal': _paypalCtrl.text.trim(),
        },
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() { _savingProfile = false; });
    }
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              Navigator.pop(context);
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

  Widget _tf(String label, TextEditingController ctrl, {IconData? icon, bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null ? Icon(icon) : null,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final onSave = widget.onSave;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionHeader(title: 'Instructor Profile', icon: Icons.person),
        const SizedBox(height: 12),
        _SettingsCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _tf('Full Name', widget.nameController, icon: Icons.person),
                _tf('Phone Number', _phoneCtrl, icon: Icons.phone),
                _tf('Email', _emailCtrl, icon: Icons.email),
                _tf('Qualification / Title', widget.titleController, icon: Icons.badge),
                _tf('Business Name (optional)', widget.businessNameController, icon: Icons.business),
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
          ),
        ),
        const SizedBox(height: 24),

        _SectionHeader(title: 'UK Payment Details (Pupils Pay You)', icon: Icons.account_balance),
        const SizedBox(height: 6),
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text(
            'These details will be visible to your pupils so they know how to pay you. Enter your UK bank account or mobile banking info below.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        _SettingsCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _tf('Bank Name (e.g. Barclays, HSBC)', _bankNameCtrl, icon: Icons.account_balance),
                _tf('Sort Code (e.g. 20-12-34)', _bankSortCodeCtrl, icon: Icons.numbers),
                _tf('Account Number', _bankAccountCtrl, icon: Icons.credit_card),
                _tf('Monzo / Revolut Link (optional)', _monzoLinkCtrl, icon: Icons.link),
                _tf('PayPal (optional)', _paypalCtrl, icon: Icons.payment),
                const SizedBox(height: 4),
                FilledButton.icon(
                  onPressed: _savingProfile ? null : _saveProfile,
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: const Text('Save Payment Info'),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.sunsetBright),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        _SectionHeader(title: 'App Settings', icon: Icons.tune),
        const SizedBox(height: 12),
        _SettingsCard(
          child: Column(
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
                  onChanged: (v) { if (v != null) onSave(settings.copyWith(timezone: v)); },
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Push notifications'),
                value: settings.notificationsEnabled,
                onChanged: (v) => onSave(settings.copyWith(notificationsEnabled: v)),
                activeThumbColor: AppColors.sunsetBright,
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Email notifications'),
                value: settings.emailNotifications,
                onChanged: (v) => onSave(settings.copyWith(emailNotifications: v)),
                activeThumbColor: AppColors.sunsetBright,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        _SettingsCard(
          child: ListTile(
            title: const Text('Export all data'),
            subtitle: const Text('Backup your data to a file'),
            leading: const Icon(Icons.download, color: AppColors.sunsetBright),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExportFormScreen())),
          ),
        ),
        const SizedBox(height: 12),

        _SettingsCard(
          child: ListTile(
            title: const Text('Sign out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
            leading: const Icon(Icons.logout, color: AppColors.error),
            onTap: () => _showSignOutDialog(context),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            'Lesson Tracker Pro - Production Build',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
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
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      surfaceTintColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }
}
