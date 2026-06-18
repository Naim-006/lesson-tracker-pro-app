
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers/app_state_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/route_transitions.dart';
import '../activity/activity_screen.dart';
import '../auth/onboarding_screen.dart';
import '../diary/diary_screen.dart';
import '../diary/open_slot_form_screen.dart';
import '../finances/expense_form_screen.dart';
import '../finances/finances_screen.dart';
import '../finances/multi_step_payment_screen.dart';
import '../home/home_screen.dart';
import '../notifications/notifications_screen.dart';
import '../pupils/pupils_screen.dart';
import '../pupils/pupil_form_screen.dart';
import '../finances/payment_form_screen.dart';
import '../quick_add/quick_add_sheet.dart';
import '../quick_add/mileage_dialog.dart';
import '../settings/settings_screen.dart';
import 'app_drawer.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _subscriptionValid = true;
  bool _checkingSubscription = true;

  static const _tabs = [
    (icon: Icons.home_outlined, active: Icons.home, label: 'Home'),
    (icon: Icons.people_outline, active: Icons.people, label: 'Pupils'),
    (icon: Icons.calendar_month_outlined, active: Icons.calendar_month, label: 'Diary'),
    (icon: Icons.account_balance_wallet_outlined, active: Icons.account_balance_wallet, label: 'Finances'),
    (icon: Icons.chat_bubble_outline, active: Icons.chat_bubble, label: 'Activity'),
  ];

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    _checkSubscription();
  }

  Future<void> _checkAuthentication() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  Future<void> _checkSubscription() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now();
      final subResponse = await Supabase.instance.client
          .from('instructor_subscriptions')
          .select('id, start_date, end_date, status')
          .eq('instructor_id', user.id)
          .gte('end_date', now.toIso8601String())
          .maybeSingle();

      if (subResponse != null) {
        if (mounted) setState(() { _subscriptionValid = true; _checkingSubscription = false; });
        return;
      }

      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select('created_at')
          .eq('id', user.id)
          .single();

      final createdAt = DateTime.parse(profileResponse['created_at'] as String);
      final trialEnd = createdAt.add(const Duration(days: 60));

      if (now.isAfter(trialEnd)) {
        if (mounted) setState(() { _subscriptionValid = false; _checkingSubscription = false; });
      } else {
        if (mounted) setState(() { _subscriptionValid = true; _checkingSubscription = false; });
        final daysLeft = trialEnd.difference(now).inDays;
        if (daysLeft <= 7 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Your free trial ends in $daysLeft days. Subscribe to continue.'),
              backgroundColor: AppColors.warning,
              action: SnackBarAction(
                label: 'Subscribe',
                textColor: Colors.white,
                onPressed: _showSubscriptionDialog,
              ),
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) setState(() { _subscriptionValid = true; _checkingSubscription = false; });
    }
  }

  void _showSubscriptionDialog() {}

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSubscription) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_subscriptionValid) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.subscriptions_outlined, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 24),
                Text('Subscription Required', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text('Your trial has ended. Subscribe to continue using Lesson Tracker Pro.',
                  textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _showSubscriptionDialog,
                  icon: const Icon(Icons.subscriptions),
                  label: const Text('View Plans'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(onPressed: _logout, child: const Text('Logout')),
              ],
            ),
          ),
        ),
      );
    }

    final tab = ref.watch(currentTabProvider);
    final unread = ref.watch(unreadNotificationsCountProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      drawer: const AppDrawer(),
      backgroundColor: const Color(0xFFF8F6F2),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBg : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shape: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder.withValues(alpha: 0.4) : AppColors.lightBorder.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: IconButton(
            icon: Icon(Icons.menu, size: 24),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
        ),
        title: const _AppWordmark(),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, size: 20),
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 22),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
              ),
              if (unread > 0)
                Positioned(
                  right: 8, top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: AppColors.sunsetBright,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.sunsetBright.withValues(alpha: 0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      unread > 9 ? '9+' : '$unread',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: tab,
        children: const [
          HomeScreen(),
          PupilsScreen(),
          DiaryScreen(),
          FinancesScreen(),
          ActivityScreen(),
        ],
      ),
      floatingActionButton: GestureDetector(
        onTap: () => _showQuickActions(context),
        child: Container(
          width: 60,
          height: 60,
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.sunsetBright, AppColors.sunset],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.sunsetBright.withValues(alpha: 0.5),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: -2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, size: 30, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: ClipPath(
        clipper: _NotchedBarClipper(),
        child: Container(
          height: 92,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : const Color(0xFFE8E4DE),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.6),
                blurRadius: 8,
                offset: const Offset(0, -2),
                spreadRadius: -2,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _GlassNavItem(
                selected: tab == 0,
                icon: _tabs[0].icon,
                activeIcon: _tabs[0].active,
                label: _tabs[0].label,
                onTap: () => ref.read(currentTabProvider.notifier).state = 0,
              ),
              _GlassNavItem(
                selected: tab == 1,
                icon: _tabs[1].icon,
                activeIcon: _tabs[1].active,
                label: _tabs[1].label,
                onTap: () => ref.read(currentTabProvider.notifier).state = 1,
              ),
              const SizedBox(width: 64),
              _GlassNavItem(
                selected: tab == 2,
                icon: _tabs[2].icon,
                activeIcon: _tabs[2].active,
                label: _tabs[2].label,
                onTap: () => ref.read(currentTabProvider.notifier).state = 2,
              ),
              _GlassNavItem(
                selected: tab == 3,
                icon: _tabs[3].icon,
                activeIcon: _tabs[3].active,
                label: _tabs[3].label,
                onTap: () => ref.read(currentTabProvider.notifier).state = 3,
              ),
              _GlassNavItem(
                selected: tab == 4,
                icon: _tabs[4].icon,
                activeIcon: _tabs[4].active,
                label: _tabs[4].label,
                onTap: () => ref.read(currentTabProvider.notifier).state = 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const QuickAddSheet(),
    );
  }
}

class _NotchedBarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    const notchRadius = 38.0;
    final centerX = w / 2;

    path.moveTo(28, 0);
    path.lineTo(centerX - notchRadius - 12, 0);
    path.quadraticBezierTo(
      centerX - notchRadius - 4, 0,
      centerX - notchRadius + 4, 14,
    );
    path.arcToPoint(
      Offset(centerX + notchRadius - 4, 14),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );
    path.quadraticBezierTo(
      centerX + notchRadius + 4, 0,
      centerX + notchRadius + 12, 0,
    );
    path.lineTo(w - 28, 0);
    path.quadraticBezierTo(w, 0, w, 28);
    path.lineTo(w, h - 28);
    path.quadraticBezierTo(w, h, w - 28, h);
    path.lineTo(28, h);
    path.quadraticBezierTo(0, h, 0, h - 28);
    path.lineTo(0, 28);
    path.quadraticBezierTo(0, 0, 28, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _GlassNavItem extends StatelessWidget {
  const _GlassNavItem({
    required this.selected,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 14 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.sunsetBright.withValues(alpha: isDark ? 0.25 : 0.18),
                    AppColors.sunset.withValues(alpha: isDark ? 0.2 : 0.12),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(18),
          border: selected
              ? Border.all(
                  color: AppColors.sunsetBright.withValues(alpha: 0.3),
                  width: 1.0,
                )
              : null,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.sunsetBright.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? activeIcon : icon,
              size: selected ? 22 : 21,
              color: selected
                  ? AppColors.sunsetBright
                  : (isDark ? AppColors.darkMuted : AppColors.lightMuted),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? AppColors.sunsetBright
                    : (isDark ? AppColors.darkMuted : AppColors.lightMuted),
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class _AppWordmark extends StatelessWidget {
  const _AppWordmark();

  @override
  Widget build(BuildContext context) {
    final fg = Theme.of(context).textTheme.titleMedium?.color;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset('assets/images/logo.png', height: 28, width: 28),
        const SizedBox(width: 8),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'LESSON\n',
                style: TextStyle(
                  color: fg, fontSize: 11, fontWeight: FontWeight.w500,
                  letterSpacing: 2.0, height: 1.1,
                ),
              ),
              TextSpan(
                text: 'TRACKER',
                style: TextStyle(
                  color: fg, fontSize: 15, fontWeight: FontWeight.w900,
                  letterSpacing: 1.5, height: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: AppColors.sunsetBright.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(3),
            ),
            child: const Text(
              'PRO',
              style: TextStyle(
                color: AppColors.sunsetBright, fontSize: 8,
                fontWeight: FontWeight.w800, letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
