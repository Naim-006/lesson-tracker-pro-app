import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/models.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/providers/supabase_instructor_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/data_export_service.dart';
import '../../features/auth/role_selection_screen.dart';
import 'vehicles_screen.dart';
import 'work_hours_screen.dart';
import '../finances/export_form_screen.dart';
import 'payment_methods_screen.dart';
import 'teaching_resources_screen.dart';
import 'pricing_packages_screen.dart';
import 'lesson_lengths_screen.dart';
import 'progress_syllabus_screen.dart';
import 'your_terms_screen.dart';
import 'pupil_resources_screen.dart';

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
    _tabController = TabController(length: 3, vsync: this);
    final s = ref.read(settingsProvider);
    _name = TextEditingController(text: s.instructorName);
    _title = TextEditingController(text: s.instructorTitle);
    _businessName = TextEditingController(text: s.businessName ?? '');
    _termsText = TextEditingController(text: s.termsAndConditions ?? '');
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
            Tab(text: 'ACCOUNT'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _BusinessTab(settings: s, nameController: _name, titleController: _title, businessNameController: _businessName, termsController: _termsText, onSave: _save),
          _TeachingTab(settings: s, onSave: _save),
          _AccountTab(settings: s, onSave: _save, nameController: _name, titleController: _title, businessNameController: _businessName),
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

        // Payments
        _SectionHeader(title: 'Payments', icon: Icons.payment),
        const SizedBox(height: 12),
        _SettingsCard(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Accept online payments'),
                subtitle: const Text('Enable Lesson Tracker Payments'),
                value: settings.acceptOnlinePayments,
                onChanged: (v) => onSave(settings.copyWith(acceptOnlinePayments: v)),
                activeColor: AppColors.sunsetBright,
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Payment methods'),
                subtitle: const Text('Configure accepted payment options'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()),
                  );
                },
              ),
            ],
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
            activeColor: AppColors.sunsetBright,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _showRateDialog(BuildContext context, AppSettings settings, Future<void> Function(AppSettings) onSave) {
    final controller = TextEditingController(text: settings.hourlyRate.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Hourly Rate'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Rate (£)', prefixIcon: Icon(Icons.currency_pound)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final rate = double.tryParse(controller.text) ?? settings.hourlyRate;
              onSave(settings.copyWith(hourlyRate: rate));
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
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
                  activeColor: AppColors.sunsetBright,
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

        // Teaching Resources Card
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
                    child: const Icon(Icons.folder_open, color: AppColors.sunsetBright, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('Teaching Resources', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: const Text('Teaching resources', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Documents, handouts, lesson plans'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TeachingResourcesScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(height: 4),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: const Text('Pupil resources', style: TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Share resources with pupils'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PupilResourcesScreen()),
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
                  activeColor: AppColors.sunsetBright,
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
                    value: settings.theoryTestProvider ?? 'DVSA',
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
  late FocusNode _nameFocus;
  late FocusNode _titleFocus;
  late FocusNode _businessNameFocus;

  @override
  void initState() {
    super.initState();
    _nameFocus = FocusNode();
    _titleFocus = FocusNode();
    _businessNameFocus = FocusNode();
    _nameFocus.addListener(_onNameFocusChange);
    _titleFocus.addListener(_onTitleFocusChange);
    _businessNameFocus.addListener(_onBusinessNameFocusChange);
  }

  @override
  void dispose() {
    _nameFocus.removeListener(_onNameFocusChange);
    _titleFocus.removeListener(_onTitleFocusChange);
    _businessNameFocus.removeListener(_onBusinessNameFocusChange);
    _nameFocus.dispose();
    _titleFocus.dispose();
    _businessNameFocus.dispose();
    super.dispose();
  }

  void _onNameFocusChange() {
    if (!_nameFocus.hasFocus) {
      widget.onSave(widget.settings.copyWith(instructorName: widget.nameController.text));
    }
  }

  void _onTitleFocusChange() {
    if (!_titleFocus.hasFocus) {
      widget.onSave(widget.settings.copyWith(instructorTitle: widget.titleController.text));
    }
  }

  void _onBusinessNameFocusChange() {
    if (!_businessNameFocus.hasFocus) {
      widget.onSave(widget.settings.copyWith(businessName: widget.businessNameController.text));
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

  void _showCalendarPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Calendar Access'),
        content: const Text('Lesson Tracker Pro needs access to your device calendar to sync your lessons and events. This allows you to view your schedule in your preferred calendar app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Calendar permission granted')),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.sunsetBright),
            child: const Text('Allow Access'),
          ),
        ],
      ),
    );
  }

  void _showPushNotificationPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Push Notifications'),
        content: const Text('Lesson Tracker Pro needs permission to send you push notifications for lesson reminders, payment alerts, and other important updates.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onSave(widget.settings.copyWith(notificationsEnabled: true));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Push notifications enabled')),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.sunsetBright),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export All Data'),
        content: const Text('This will create a backup file containing all your pupils, lessons, payments, expenses, mileage, and settings. You can use this file to restore your data later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                // Fetch data from Supabase providers
                final pupils = await ref.read(instructorPupilsProvider.future);
                final lessons = await ref.read(instructorLessonsProvider.future);
                final payments = await ref.read(instructorPaymentsProvider.future);
                
                // Create a simplified app state for export
                final exportData = {
                  'pupils': pupils,
                  'lessons': lessons,
                  'payments': payments,
                };
                
                if (context.mounted) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ExportFormScreen()));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error exporting data: $e')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.sunsetBright),
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Data'),
        content: const Text('Import functionality is currently unavailable. Please use the export feature to backup your data.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showCSVExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export to CSV'),
        content: const Text('This will export your pupils, lessons, and payments to separate CSV files that you can open in Excel or other spreadsheet applications.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                // Fetch data from Supabase providers
                final pupils = await ref.read(instructorPupilsProvider.future);
                final lessons = await ref.read(instructorLessonsProvider.future);
                final payments = await ref.read(instructorPaymentsProvider.future);
                
                if (context.mounted) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ExportFormScreen()));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error exporting to CSV: $e')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.sunsetBright),
            child: const Text('Export'),
          ),
        ],
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
        // Details
        _SectionHeader(title: 'Instructor Details', icon: Icons.person),
        const SizedBox(height: 12),
        _SettingsCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: widget.nameController,
                  focusNode: _nameFocus,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: widget.titleController,
                  focusNode: _titleFocus,
                  decoration: const InputDecoration(
                    labelText: 'Title / qualification',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: widget.businessNameController,
                  focusNode: _businessNameFocus,
                  decoration: const InputDecoration(
                    labelText: 'Business name (optional)',
                    prefixIcon: Icon(Icons.business),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Brand
        _SectionHeader(title: 'Brand & Appearance', icon: Icons.palette),
        const SizedBox(height: 12),
        _SettingsCard(
          child: Column(
            children: [
              ListTile(
                title: const Text('Currency'),
                trailing: DropdownButton<String>(
                  value: settings.currency,
                  items: const ['GBP', 'USD', 'EUR']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) onSave(settings.copyWith(currency: v));
                  },
                ),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Timezone'),
                trailing: DropdownButton<String>(
                  value: settings.timezone,
                  items: const [
                    'Europe/London',
                    'Europe/Dublin',
                    'America/New_York',
                    'Australia/Sydney',
                  ]
                      .map((z) => DropdownMenuItem(value: z, child: Text(z)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) onSave(settings.copyWith(timezone: v));
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Calendar Sync
        _SectionHeader(title: 'Calendar Sync', icon: Icons.calendar_today),
        const SizedBox(height: 12),
        _SettingsCard(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Sync with device calendar'),
                subtitle: const Text('Export lessons to Google/Apple calendar'),
                value: settings.calendarSyncEnabled,
                onChanged: (v) => onSave(settings.copyWith(calendarSyncEnabled: v)),
                activeColor: AppColors.sunsetBright,
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Sync calendar'),
                trailing: const Icon(Icons.sync),
                onTap: () => _showCalendarPermissionDialog(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Push Notifications
        _SectionHeader(title: 'Notifications', icon: Icons.notifications),
        const SizedBox(height: 12),
        _SettingsCard(
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Push notifications'),
                value: settings.notificationsEnabled,
                onChanged: (v) {
                  if (v) {
                    _showPushNotificationPermissionDialog(context);
                  } else {
                    onSave(settings.copyWith(notificationsEnabled: v));
                  }
                },
                activeColor: AppColors.sunsetBright,
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Email notifications'),
                value: settings.emailNotifications,
                onChanged: (v) => onSave(settings.copyWith(emailNotifications: v)),
                activeColor: AppColors.sunsetBright,
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Lesson reminder'),
                subtitle: Text('${settings.lessonReminderMinutes} minutes before'),
                trailing: DropdownButton<int>(
                  value: settings.lessonReminderMinutes,
                  items: const [15, 30, 60, 120]
                      .map((m) => DropdownMenuItem(value: m, child: Text('$m min')))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) onSave(settings.copyWith(lessonReminderMinutes: v));
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Data Management
        _SectionHeader(title: 'Data Management', icon: Icons.storage),
        const SizedBox(height: 12),
        _SettingsCard(
          child: Column(
            children: [
              ListTile(
                title: const Text('Export all data'),
                subtitle: const Text('Backup all your data to a file'),
                leading: const Icon(Icons.download),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showExportDialog(context),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Import data'),
                subtitle: const Text('Restore data from a backup file'),
                leading: const Icon(Icons.upload),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showImportDialog(context),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Export to CSV'),
                subtitle: const Text('Export pupils, lessons, and payments to CSV'),
                leading: const Icon(Icons.table_chart),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showCSVExportDialog(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Sign Out
        _SettingsCard(
          child: ListTile(
            title: const Text('Sign out', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
            leading: const Icon(Icons.logout, color: AppColors.error),
            onTap: () => _showSignOutDialog(context),
          ),
        ),
        const SizedBox(height: 24),

        // Version Info
        Center(
          child: Column(
            children: [
              Text(
                'Lesson Tracker Pro v1.4.85',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Checking for updates...')),
                  );
                },
                child: const Text('Check for updates'),
              ),
            ],
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
