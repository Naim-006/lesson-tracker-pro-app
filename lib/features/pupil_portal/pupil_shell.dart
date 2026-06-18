import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/onboarding_screen.dart';
import '../../core/theme/app_colors.dart';
import 'pupil_home_screen.dart';
import 'pupil_progress_screen.dart';
import 'pupil_enquiry_screen.dart';
import 'nearby_tutors_screen.dart';
import 'pupil_messaging_screen.dart';
import 'pupil_resources_screen.dart';
import 'slot_request_screen.dart';
import 'pupil_payment_screen.dart';

import 'pupil_settings_screen.dart';

class PupilShellOld extends ConsumerStatefulWidget {
  const PupilShellOld({super.key});

  @override
  ConsumerState<PupilShellOld> createState() => _PupilShellOldState();
}

class _PupilShellOldState extends ConsumerState<PupilShellOld> {
  int _currentIndex = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<_PupilTab> _tabs = [
    _PupilTab(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home', screen: const PupilHomeScreen()),
    _PupilTab(icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today, label: 'Slots', screen: const SlotRequestScreen()),
    _PupilTab(icon: Icons.trending_up_outlined, activeIcon: Icons.trending_up, label: 'Progress', screen: const PupilProgressScreen()),
    _PupilTab(icon: Icons.message_outlined, activeIcon: Icons.message, label: 'Messages', screen: const PupilMessagingScreen()),
    _PupilTab(icon: Icons.payment_outlined, activeIcon: Icons.payment, label: 'Payments', screen: const PupilPaymentScreen()),
    _PupilTab(icon: Icons.school_outlined, activeIcon: Icons.school, label: 'Resources', screen: const PupilResourcesScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF8F6F2),
      appBar: AppBar(
        toolbarHeight: 56,
        backgroundColor: isDark ? AppColors.darkBg : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.04),
        shape: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
        leadingWidth: 48,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.sunset, AppColors.sunsetBright],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                _tabs[_currentIndex].activeIcon,
                size: 17,
                color: Colors.white,
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _tabs[_currentIndex].label,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkText : AppColors.lightText,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              'Pupil Dashboard',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.grey.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.settings_outlined, size: 19),
              color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
              tooltip: 'Settings',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PupilSettingsScreen())),
            ),
          ),
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.grey.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.logout, size: 18),
              color: AppColors.error.withValues(alpha: 0.7),
              tooltip: 'Sign out',
              onPressed: () => _signOut(),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs.map((tab) => tab.screen).toList(),
      ),
      bottomNavigationBar: SizedBox(
        height: 68,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard.withValues(alpha: 0.92) : Colors.white.withValues(alpha: 0.92),
                  border: Border(
                    top: BorderSide(
                      color: isDark ? AppColors.darkBorder.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.06),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < _tabs.length; i++)
                      Expanded(
                        child: _ChinNavItem(
                          selected: _currentIndex == i,
                          icon: _tabs[i].icon,
                          activeIcon: _tabs[i].activeIcon,
                          onTap: () => setState(() => _currentIndex = i),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -4,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.sunset, AppColors.sunsetBright],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.sunsetBright.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showQuickActions(),
                    customBorder: const CircleBorder(),
                    child: const Icon(Icons.add, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.sunsetBright.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add_rounded, color: AppColors.sunsetBright, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Actions',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Choose an action below',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _PupilQuickActionTile(
              icon: Icons.search,
              label: 'Find Tutors',
              subtitle: 'Search for nearby driving instructors',
              color: AppColors.sunsetBright,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const NearbyTutorsScreen()));
              },
            ),
            const SizedBox(height: 10),
            _PupilQuickActionTile(
              icon: Icons.mail,
              label: 'Send Enquiry',
              subtitle: 'Contact an instructor with questions',
              color: AppColors.info,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PupilEnquiryScreen()));
              },
            ),
            const SizedBox(height: 10),
            _PupilQuickActionTile(
              icon: Icons.logout,
              label: 'Sign Out',
              subtitle: 'Log out of your account',
              color: AppColors.error,
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure?'),
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
            ),
          ],
        ),
      ),
    );
  }
}

class _PupilTab {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget screen;

  _PupilTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.screen,
  });
}

class _ChinNavItem extends StatelessWidget {
  const _ChinNavItem({
    required this.selected,
    required this.icon,
    required this.activeIcon,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final IconData activeIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 52,
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? activeIcon : icon,
              size: 21,
              color: selected
                  ? AppColors.sunsetBright
                  : (isDark ? AppColors.darkMuted : AppColors.lightMuted),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: selected ? 18 : 0,
              height: 2.5,
              decoration: BoxDecoration(
                color: AppColors.sunsetBright,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PupilQuickActionTile extends StatelessWidget {
  const _PupilQuickActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color.withValues(alpha: 0.4), size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
