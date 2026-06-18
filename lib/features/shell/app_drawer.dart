import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers/app_state_provider.dart';
import '../../core/providers/supabase_instructor_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/sunset_widgets.dart';
import '../auth/onboarding_screen.dart';
import '../activity/support_screen.dart';
import '../enquiry/enquiry_screen.dart';
import '../help/help_screen.dart';
import '../pupils/pupil_invitation_screen.dart';
import '../settings/settings_screen.dart';
import '../test_reports/test_reports_screen.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final instructorPupils = ref.watch(instructorPupilsProvider);
    final instructorLessons = ref.watch(instructorLessonsProvider);
    final instructorEnquiries = ref.watch(instructorEnquiriesProvider);
    final instructorTestReports = ref.watch(instructorTestReportsProvider);
    final instructorPayments = ref.watch(instructorPaymentsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pupilsCount = instructorPupils.value?.length ?? 0;
    final completed = instructorLessons.value?.where((l) => l['status'] == 'completed').length ?? 0;
    final now = DateTime.now();
    final monthlyIncome = instructorPayments.value?.where((p) {
      final paymentDate = DateTime.parse(p['payment_date']);
      return paymentDate.year == now.year && paymentDate.month == now.month;
    }).fold<double>(0, (sum, p) => sum + (p['amount'] as num).toDouble()) ?? 0.0;
    final enquiriesCount = instructorEnquiries.value?.length ?? 0;
    final testReportsCount = instructorTestReports.value?.length ?? 0;

    return Drawer(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.sunsetBright.withValues(alpha: 0.2),
                    backgroundImage: const NetworkImage('https://i.pravatar.cc/150?img=11'),
                  ),
                  const SizedBox(height: 12),
                  Text(settings.instructorName, style: Theme.of(context).textTheme.titleLarge),
                  Text(settings.instructorTitle.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      StatColumn(value: '$pupilsCount', label: 'Pupils'),
                      StatColumn(value: '$completed', label: 'Done'),
                      StatColumn(value: '\u00A3${monthlyIncome.toStringAsFixed(0)}', label: 'Month'),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  MenuTileCard(
                    icon: Icons.mail_outline,
                    title: 'Pupil Invitations',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PupilInvitationScreen()));
                    },
                  ),
                  const SizedBox(height: 8),
                  MenuTileCard(
                    icon: Icons.person_search_outlined,
                    title: 'Enquiry Manager',
                    subtitle: '$enquiriesCount enquiries',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const EnquiryScreen()));
                    },
                  ),
                  const SizedBox(height: 8),
                  MenuTileCard(
                    icon: Icons.assignment_turned_in_outlined,
                    title: 'Test Reports',
                    subtitle: '$testReportsCount reports',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const TestReportsScreen()));
                    },
                  ),
                  const SizedBox(height: 8),
                  MenuTileCard(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                    },
                  ),
                  const SizedBox(height: 8),
                  MenuTileCard(
                    icon: Icons.support_agent,
                    title: 'Support',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen()));
                    },
                  ),
                  const SizedBox(height: 8),
                  MenuTileCard(
                    icon: Icons.help_outline,
                    title: 'Help & tutorials',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen()));
                    },
                  ),
                  const SizedBox(height: 8),
                  MenuTileCard(
                    icon: Icons.feedback_outlined,
                    title: 'Give feedback',
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Give Feedback'),
                          content: const TextField(
                            decoration: InputDecoration(hintText: 'Tell us how we can improve...'),
                            maxLines: 4,
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                            FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Submit')),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  MenuTileCard(
                    icon: Icons.logout,
                    title: 'Sign out',
                    onTap: () async {
                      Navigator.pop(context);
                      await Supabase.instance.client.auth.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const OnboardingScreen()));
                      }
                    },
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('v1.0.485', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}
