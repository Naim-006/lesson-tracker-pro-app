import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../content/terms_conditions_screen.dart';
import '../content/privacy_policy_screen.dart';
import '../payment_settings/payment_settings_screen.dart';
import '../subscription_plans/subscription_plans_screen.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // Payment Settings
            _buildSettingsSection(
              title: 'Payment Settings',
              icon: Icons.payment,
              children: [
                _buildSettingTile(
                  title: 'Stripe API Key',
                  subtitle: 'Configure your Stripe payment gateway',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PaymentSettingsScreen()),
                    );
                  },
                ),
                _buildSettingTile(
                  title: 'Subscription Plans',
                  subtitle: 'Manage subscription pricing and tiers',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SubscriptionPlansScreen()),
                    );
                  },
                ),
                _buildSettingTile(
                  title: 'Payment Methods',
                  subtitle: 'Configure accepted payment methods',
                  onTap: () {
                    // Configure payment methods
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Content Settings
            _buildSettingsSection(
              title: 'Content Settings',
              icon: Icons.article,
              children: [
                _buildSettingTile(
                  title: 'Terms and Conditions',
                  subtitle: 'Manage app terms and conditions',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TermsConditionsScreen()),
                    );
                  },
                ),
                _buildSettingTile(
                  title: 'Privacy Policy',
                  subtitle: 'Manage privacy policy',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                    );
                  },
                ),
                _buildSettingTile(
                  title: 'Teaching Resources',
                  subtitle: 'Manage teaching resources for instructors',
                  onTap: () {
                    // Manage resources
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            // App Settings
            _buildSettingsSection(
              title: 'App Settings',
              icon: Icons.settings,
              children: [
                _buildSettingTile(
                  title: 'App Configuration',
                  subtitle: 'Configure app-wide settings',
                  onTap: () {
                    // Configure app
                  },
                ),
                _buildSettingTile(
                  title: 'Email Settings',
                  subtitle: 'Configure email notifications',
                  onTap: () {
                    // Configure email
                  },
                ),
                _buildSettingTile(
                  title: 'Security Settings',
                  subtitle: 'Manage security configurations',
                  onTap: () {
                    // Configure security
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(icon, color: AppColors.sunset),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
