import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers/theme_provider.dart';
import '../../core/providers/supabase_instructor_provider.dart';
import '../../core/theme/app_colors.dart';
import '../auth/onboarding_screen.dart';
import '../activity/support_screen.dart';
import '../enquiry/enquiry_screen.dart';
import '../help/help_screen.dart';
import '../pupils/pupil_invitation_link_screen.dart';
import '../settings/settings_screen.dart';
import '../test_reports/test_reports_screen.dart';
import '../finances/subscription_screen.dart';
import '../finances/pupil_subscription_screen.dart';
import '../settings/teaching_resources_screen.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instructorEnquiries = ref.watch(instructorEnquiriesProvider);
    final instructorTestReports = ref.watch(instructorTestReportsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final enquiriesCount = instructorEnquiries.value?.length ?? 0;
    final testReportsCount = instructorTestReports.value?.length ?? 0;

    final bgColor = isDark ? AppColors.darkBg : const Color(0xFFF8F6F2);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final mutedColor = isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey.shade500;
    final borderColor = isDark ? AppColors.darkBorder.withValues(alpha: 0.4) : AppColors.lightBorder.withValues(alpha: 0.6);

    return Drawer(
      backgroundColor: bgColor,
      child: SafeArea(
        child: Column(
          children: [
            // Brand header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.sunsetBright, Color(0xFFFF6B35)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(Icons.school_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lesson Tracker',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: textColor,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Instructor Portal',
                        style: TextStyle(fontSize: 11, color: mutedColor, letterSpacing: 0.2),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                children: [
                  _SectionLabel(text: 'Management', mutedColor: mutedColor),
                  _DrawerItem(
                    icon: Icons.mail_outline_rounded,
                    title: 'Pupil Invitations',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PupilInvitationLinkScreen()));
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.person_search_outlined,
                    title: 'Enquiry Manager',
                    subtitle: '$enquiriesCount enquiries',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const EnquiryScreen()));
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.assignment_turned_in_outlined,
                    title: 'Test Reports',
                    subtitle: '$testReportsCount reports',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const TestReportsScreen()));
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.folder_open_outlined,
                    title: 'Resources',
                    subtitle: 'Handouts & lesson plans',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const TeachingResourcesScreen()));
                    },
                  ),

                  _SectionLabel(text: 'Finance', mutedColor: mutedColor),
                  _DrawerItem(
                    icon: Icons.card_membership_outlined,
                    title: 'Subscription',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.payments_outlined,
                    title: 'Pupil Payments',
                    subtitle: 'Bank / mobile money',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PupilSubscriptionScreen()));
                    },
                  ),

                  _SectionLabel(text: 'General', mutedColor: mutedColor),
                  _DrawerItem(
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.help_outline,
                    title: 'Help & tutorials',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpScreen()));
                    },
                  ),
                  _DrawerItem(
                    icon: Icons.support_agent,
                    title: 'Support',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen()));
                    },
                  ),
                  _DrawerItem(
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
                  _DrawerItem(
                    icon: Icons.logout_rounded,
                    title: 'Sign out',
                    isDestructive: true,
                    onTap: () async {
                      Navigator.pop(context);
                      await Supabase.instance.client.auth.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const OnboardingScreen()));
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // Bottom bar — dark mode only
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor, width: 0.5)),
              ),
              child: InkWell(
                onTap: () => ref.read(themeModeProvider.notifier).toggle(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  child: Row(
                    children: [
                      Icon(
                        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                        size: 18,
                        color: mutedColor,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                        style: TextStyle(fontSize: 13, color: mutedColor),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.mutedColor});
  final String text;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: mutedColor,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.isDestructive = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isDestructive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = isDestructive ? AppColors.error : AppColors.sunsetBright;
    final iconBg = isDestructive
        ? AppColors.error.withValues(alpha: 0.1)
        : AppColors.sunsetBright.withValues(alpha: 0.12);
    final titleColor = isDestructive
        ? AppColors.error
        : isDark
            ? Colors.white
            : const Color(0xFF1A1A2E);

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accentColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: titleColor,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.35)
                                : Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
