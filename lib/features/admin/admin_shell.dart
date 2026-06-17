import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../auth/onboarding_screen.dart';
import 'admin_drawer.dart';
import 'dashboard/admin_dashboard_screen.dart';
import 'instructors/instructors_screen.dart';
import 'subscriptions/subscriptions_screen.dart';
import 'promo_codes/promo_codes_screen.dart';
import 'events/events_screen.dart';
import 'payments/payments_screen.dart';
import 'instructor_monitoring/instructor_monitoring_screen.dart';
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
  int _selectedIndex = 0;

  static const _navItems = (
    icons: [
      Icons.dashboard,
      Icons.people,
      Icons.subscriptions,
      Icons.card_giftcard,
      Icons.event,
      Icons.payment,
      Icons.request_page,
      Icons.chat,
      Icons.inbox,
      Icons.settings,
    ],
    titles: [
      'Dashboard', 'Instructors', 'Subscriptions', 'Promo Codes',
      'Events', 'Payments', 'Payment Requests', 'Support Chat',
      'Enquiries', 'Settings',
    ],
  );

  final List<Widget> _screens = [
    const AdminDashboardScreen(),
    const InstructorsScreen(),
    const SubscriptionsScreen(),
    const PromoCodesScreen(),
    const EventsScreen(),
    const PaymentsScreen(),
    const InstructorPaymentRequestsScreen(),
    const AdminChatScreen(),
    const AdminEnquiriesScreen(),
    const AdminSettingsScreen(),
  ];

  bool get _isWide => MediaQuery.of(context).size.width >= 600;

  @override
  Widget build(BuildContext context) {
    if (_isWide) {
      return _buildDesktopLayout();
    }
    return _buildMobileLayout();
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        title: Text(_navItems.titles[_selectedIndex], style: const TextStyle(color: Colors.white, fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: _buildDrawer(),
      body: _screens[_selectedIndex],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: AppColors.navy,
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: AppColors.navy.withValues(alpha: 0.9)),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.admin_panel_settings, size: 48, color: Colors.white),
                  SizedBox(height: 12),
                  Text('Admin Portal', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Manage your platform', style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: List.generate(_navItems.titles.length, (i) {
                  return ListTile(
                    leading: Icon(_navItems.icons[i], color: _selectedIndex == i ? Colors.white : Colors.white70),
                    title: Text(
                      _navItems.titles[i],
                      style: TextStyle(
                        color: _selectedIndex == i ? Colors.white : Colors.white70,
                        fontWeight: _selectedIndex == i ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: _selectedIndex == i,
                    selectedTileColor: Colors.white.withValues(alpha: 0.1),
                    onTap: () {
                      setState(() => _selectedIndex = i);
                      Navigator.pop(context);
                    },
                  );
                }),
              ),
            ),
            // Logout
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Supabase.instance.client.auth.signOut();
                    if (mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                        (_) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout, color: Colors.white, size: 18),
                  label: const Text('Logout', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      color: AppColors.navy,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: const Column(
              children: [
                Icon(Icons.admin_panel_settings, size: 44, color: Colors.white),
                SizedBox(height: 10),
                Text('Admin Portal', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: List.generate(_navItems.titles.length, (i) {
                return _buildNavItem(
                  icon: _navItems.icons[i],
                  title: _navItems.titles[i],
                  index: i,
                );
              }),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                      (_) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.white, size: 18),
                label: const Text('Logout', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String title, required int index}) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isSelected ? Colors.white.withValues(alpha: 0.12) : null,
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: isSelected ? Colors.white : Colors.white70, size: 20),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 14,
          ),
        ),
        onTap: () => setState(() => _selectedIndex = index),
      ),
    );
  }
}
