
import 'dart:ui';
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
      floatingActionButton: ClipPath(
        clipper: _HalfCircleClipper(),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.sunsetBright.withValues(alpha: 0.9),
                  AppColors.sunset.withValues(alpha: 0.85),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.sunsetBright.withValues(alpha: 0.5),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showQuickActions(context),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 26,
                    color: Colors.white,
                    weight: 2.0,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: const _HalfCircleFabLocation(),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.75),
                    isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.white.withValues(alpha: 0.45),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.6),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                    spreadRadius: -4,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (var i = 0; i < _tabs.length; i++)
                      _GlassNavItem(
                        selected: tab == i,
                        icon: _tabs[i].icon,
                        activeIcon: _tabs[i].active,
                        label: _tabs[i].label,
                        onTap: () => ref.read(currentTabProvider.notifier).state = i,
                      ),
                  ],
                ),
              ),
            ),
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

class _HalfCircleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..addArc(
        Rect.fromCircle(center: Offset(size.width / 2, 0), radius: size.width / 2),
        0,
        3.14,
      );
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class _HalfCircleFabLocation extends FloatingActionButtonLocation {
  const _HalfCircleFabLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabX = (scaffoldGeometry.scaffoldSize.width - 52) / 2;
    final double fabY = scaffoldGeometry.scaffoldSize.height
        - scaffoldGeometry.bottomSheetSize.height
        - 96
        - 16;
    return Offset(fabX, fabY);
  }

  @override
  String toString() => 'HalfCircleFabLocation';
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
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.sunsetBright.withValues(alpha: isDark ? 0.25 : 0.2),
                    AppColors.sunset.withValues(alpha: isDark ? 0.2 : 0.15),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(20),
          border: selected
              ? Border.all(
                  color: AppColors.sunsetBright.withValues(alpha: 0.3),
                  width: 1.0,
                )
              : null,
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.sunsetBright.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: -2,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: child,
              ),
              child: Icon(
                selected ? activeIcon : icon,
                key: ValueKey(selected),
                size: selected ? 24 : 22,
                color: selected
                    ? AppColors.sunsetBright
                    : (isDark ? AppColors.darkMuted : AppColors.lightMuted),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? AppColors.sunsetBright
                    : (isDark ? AppColors.darkMuted : AppColors.lightMuted),
                height: 1.0,
                letterSpacing: selected ? 0.3 : 0.2,
              ),
              child: Text(label),
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
