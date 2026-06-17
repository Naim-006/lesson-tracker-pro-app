import 'package:flutter/material.dart';

class AdminDrawer extends StatelessWidget {
  const AdminDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue.shade700,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  size: 48,
                  color: Colors.white,
                ),
                SizedBox(height: 16),
                Text(
                  'Admin Portal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Lesson Tracker Pro',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to dashboard
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Instructors'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to instructors
            },
          ),
          ListTile(
            leading: const Icon(Icons.subscriptions),
            title: const Text('Subscriptions'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to subscriptions
            },
          ),
          ListTile(
            leading: const Icon(Icons.card_giftcard),
            title: const Text('Promo Codes'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to promo codes
            },
          ),
          ListTile(
            leading: const Icon(Icons.event),
            title: const Text('Events'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to events
            },
          ),
          ListTile(
            leading: const Icon(Icons.payment),
            title: const Text('Payments'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to payments
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text('Support Chat'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to support chat
            },
          ),
          ListTile(
            leading: const Icon(Icons.inbox),
            title: const Text('Enquiries'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to enquiries
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              Navigator.pop(context);
              // Handle logout
            },
          ),
        ],
      ),
    );
  }
}
