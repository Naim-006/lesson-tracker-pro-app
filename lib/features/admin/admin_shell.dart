import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../auth/onboarding_screen.dart';

import 'dashboard/admin_dashboard_screen.dart';
import 'instructors/instructors_screen.dart';
import 'subscriptions/subscriptions_screen.dart';
import 'promo_codes/promo_codes_screen.dart';
import 'events/events_screen.dart';
import 'payments/payments_screen.dart';

import 'instructor_payment_requests/instructor_payment_requests_screen.dart';
import 'chat/admin_chat_screen.dart';
import 'enquiries/admin_enquiries_screen.dart';
import 'settings/admin_settings_screen.dart';

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _sidebarExtended = true;

  final List<_AdminTab> _tabs = [
    _AdminTab(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard', screen: const AdminDashboardScreen()),
    _AdminTab(icon: Icons.people_outline, activeIcon: Icons.people, label: 'Instructors', screen: const InstructorsScreen()),
    _AdminTab(icon: Icons.subscriptions_outlined, activeIcon: Icons.subscriptions, label: 'Subscriptions', screen: const SubscriptionsScreen()),
    _AdminTab(icon: Icons.discount_outlined, activeIcon: Icons.discount, label: 'Promo Codes', screen: const PromoCodesScreen()),
    _AdminTab(icon: Icons.event_outlined, activeIcon: Icons.event, label: 'Events', screen: const EventsScreen()),
    _AdminTab(icon: Icons.payment_outlined, activeIcon: Icons.payment, label: 'Payments', screen: const PaymentsScreen()),

    _AdminTab(icon: Icons.request_quote_outlined, activeIcon: Icons.request_quote, label: 'Pay Requests', screen: const InstructorPaymentRequestsScreen()),
    _AdminTab(icon: Icons.chat_outlined, activeIcon: Icons.chat, label: 'Chat', screen: const AdminChatScreen()),
    _AdminTab(icon: Icons.contact_mail_outlined, activeIcon: Icons.contact_mail, label: 'Enquiries', screen: const AdminEnquiriesScreen()),
    _AdminTab(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Settings', screen: const AdminSettingsScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 900;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: isDark ? AppColors.darkBg : AppColors.cream,
      appBar: isWide
          ? null
          : AppBar(
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
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              title: Text(
                _tabs[_currentIndex].label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkText : AppColors.lightText,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, size: 20),
                  tooltip: 'Sign out',
                  onPressed: () => _signOut(),
                ),
                const SizedBox(width: 4),
              ],
            ),
      drawer: isWide ? null : _buildDrawer(isDark),
      body: Row(
        children: [
          if (isWide) _buildSidebar(isDark),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _tabs.map((t) => t.screen).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(bool isDark) {
    return Drawer(
      backgroundColor: isDark ? AppColors.darkBg : Colors.white,
      shape: const RoundedRectangleBorder(),
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.sunset, AppColors.sunsetBright],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Admin Panel',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Lesson Tracker Pro',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.only(top: 8),
              children: [
                for (var i = 0; i < _tabs.length; i++) _buildDrawerTile(i, isDark),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                _buildDrawerSignOutTile(isDark),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerTile(int index, bool isDark) {
    final selected = _currentIndex == index;
    final tab = _tabs[index];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() => _currentIndex = index);
            Navigator.pop(_scaffoldKey.currentContext!);
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? AppColors.sunsetBright.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  selected ? tab.activeIcon : tab.icon,
                  size: 22,
                  color: selected ? AppColors.sunsetBright : (isDark ? AppColors.darkMuted : AppColors.lightMuted),
                ),
                const SizedBox(width: 14),
                Text(
                  tab.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected ? AppColors.sunsetBright : (isDark ? AppColors.darkText : AppColors.lightText),
                  ),
                ),
                const Spacer(),
                if (selected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.sunsetBright,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerSignOutTile(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _signOut(),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.logout, size: 22, color: AppColors.error),
                const SizedBox(width: 14),
                Text(
                  'Sign Out',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebar(bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _sidebarExtended ? 220 : 64,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.darkBorder.withValues(alpha: 0.4) : AppColors.lightBorder.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.sunset, AppColors.sunsetBright],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: _sidebarExtended
                ? Row(
                    children: [
                      const SizedBox(width: 16),
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Admin Panel',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
                        onPressed: () => setState(() => _sidebarExtended = false),
                        tooltip: 'Collapse',
                      ),
                    ],
                  )
                : Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, color: Colors.white, size: 20),
                          onPressed: () => setState(() => _sidebarExtended = true),
                          tooltip: 'Expand',
                        ),
                      ],
                    ),
                  ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (var i = 0; i < _tabs.length; i++) _buildSidebarItem(i, isDark),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
          _buildSidebarSignOutItem(isDark),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, bool isDark) {
    final selected = _currentIndex == index;
    final tab = _tabs[index];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _currentIndex = index),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: _sidebarExtended ? 12 : 8,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: selected ? AppColors.sunsetBright.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: _sidebarExtended
                ? Row(
                    children: [
                      Icon(
                        selected ? tab.activeIcon : tab.icon,
                        size: 20,
                        color: selected ? AppColors.sunsetBright : (isDark ? AppColors.darkMuted : AppColors.lightMuted),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                            color: selected ? AppColors.sunsetBright : (isDark ? AppColors.darkText : AppColors.lightText),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (selected)
                        Container(
                          width: 5, height: 5,
                          decoration: const BoxDecoration(
                            color: AppColors.sunsetBright,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  )
                : Center(
                    child: Icon(
                      selected ? tab.activeIcon : tab.icon,
                      size: 22,
                      color: selected ? AppColors.sunsetBright : (isDark ? AppColors.darkMuted : AppColors.lightMuted),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarSignOutItem(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _signOut(),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: _sidebarExtended ? 12 : 8,
              vertical: 10,
            ),
            child: _sidebarExtended
                ? Row(
                    children: [
                      Icon(Icons.logout, size: 20, color: AppColors.error),
                      const SizedBox(width: 12),
                      Text(
                        'Sign Out',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  )
                : const Center(child: Icon(Icons.logout, size: 22, color: AppColors.error)),
          ),
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
}

class _AdminTab {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget screen;

  _AdminTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.screen,
  });
}
