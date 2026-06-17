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

class PupilShell extends ConsumerStatefulWidget {
  const PupilShell({super.key});

  @override
  ConsumerState<PupilShell> createState() => _PupilShellState();
}

class _PupilShellState extends ConsumerState<PupilShell> {
  int _currentIndex = 0;

  final List<_TabItem> _tabs = [
    _TabItem(
      icon: Icons.home,
      label: 'Home',
      screen: const PupilHomeScreen(),
    ),
    _TabItem(
      icon: Icons.calendar_today,
      label: 'Slots',
      screen: const SlotRequestScreen(),
    ),
    _TabItem(
      icon: Icons.trending_up,
      label: 'Progress',
      screen: const PupilProgressScreen(),
    ),
    _TabItem(
      icon: Icons.message,
      label: 'Messages',
      screen: const PupilMessagingScreen(),
    ),
    _TabItem(
      icon: Icons.payment,
      label: 'Payments',
      screen: const PupilPaymentScreen(),
    ),
    _TabItem(
      icon: Icons.school,
      label: 'Resources',
      screen: const PupilResourcesScreen(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tabs[_currentIndex].label),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 22),
            tooltip: 'Sign out',
            onPressed: () async {
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
                if (mounted) {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const OnboardingScreen()));
                }
              }
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs.map((tab) => tab.screen).toList(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: 12,
          ),
          items: _tabs.map((tab) {
            return BottomNavigationBarItem(
              icon: Icon(tab.icon),
              label: tab.label,
            );
          }).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showQuickActions();
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _QuickActionTile(
              icon: Icons.search,
              label: 'Find Tutors',
              color: Colors.orange,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NearbyTutorsScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _QuickActionTile(
              icon: Icons.mail,
              label: 'Send Enquiry',
              color: Colors.orange,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PupilEnquiryScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _QuickActionTile(
              icon: Icons.logout,
              label: 'Logout',
              color: Colors.red,
              onTap: () async {
                Navigator.pop(context);
                await Supabase.instance.client.auth.signOut();
                if (mounted) {
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

class _TabItem {
  final IconData icon;
  final String label;
  final Widget screen;

  _TabItem({
    required this.icon,
    required this.label,
    required this.screen,
  });
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
