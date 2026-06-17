import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../auth/onboarding_screen.dart';

class PupilSettingsScreen extends ConsumerStatefulWidget {
  const PupilSettingsScreen({super.key});

  @override
  ConsumerState<PupilSettingsScreen> createState() => _PupilSettingsScreenState();
}

class _PupilSettingsScreenState extends ConsumerState<PupilSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF8F6F2),
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
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsSection(
            title: 'Banking & Payments',
            icon: Icons.account_balance,
            children: [
              _SettingsTile(
                icon: Icons.credit_card_outlined,
                title: 'Payment Methods',
                subtitle: 'Manage your saved payment methods',
                onTap: () => _showPaymentMethods(),
              ),
              _SettingsTile(
                icon: Icons.add_card_outlined,
                title: 'Add Card',
                subtitle: 'Securely add a new card via Stripe',
                onTap: () => _showAddCard(),
              ),
              _SettingsTile(
                icon: Icons.receipt_long_outlined,
                title: 'Payment History',
                subtitle: 'View all your past payments',
                onTap: () => _showPaymentHistory(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'Account',
            icon: Icons.person_outline,
            children: [
              _SettingsTile(
                icon: Icons.info_outline,
                title: 'Personal Details',
                subtitle: 'View your account information',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.logout,
                title: 'Sign Out',
                subtitle: 'Log out of your account',
                iconColor: AppColors.error,
                titleColor: AppColors.error,
                onTap: () => _signOut(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPaymentMethods() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Saved Payment Methods',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.sunsetBright.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.sunsetBright.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Icon(Icons.credit_card, size: 40, color: AppColors.sunsetBright),
                  const SizedBox(height: 12),
                  const Text(
                    'No cards saved yet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add a payment method to pay for lessons securely.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCard() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.sunsetBright.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.lock_outline, color: AppColors.sunsetBright, size: 22),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Add Card',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Your card details are encrypted and processed securely by Stripe. We never store your full card number.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.credit_card_outlined, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'Card Number',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Stripe Secure Field',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'MM/YY  CVC',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Stripe payment form will be integrated here'),
                      backgroundColor: AppColors.sunsetBright,
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.sunsetBright,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Continue to Stripe', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _PaymentHistoryScreen()),
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

class _PaymentHistoryScreen extends StatelessWidget {
  const _PaymentHistoryScreen();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF8F6F2),
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBg : Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('Payment History'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No payment history yet',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder.withValues(alpha: 0.3) : AppColors.lightBorder.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppColors.sunsetBright),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkText : AppColors.lightText,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? AppColors.darkBorder.withValues(alpha: 0.3) : AppColors.lightBorder.withValues(alpha: 0.6)),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.titleColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? AppColors.darkText : AppColors.lightText;
    return ListTile(
      leading: Icon(icon, size: 22, color: iconColor ?? AppColors.sunsetBright.withValues(alpha: 0.8)),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: titleColor ?? defaultColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
        ),
      ),
      trailing: Icon(Icons.chevron_right, size: 20, color: isDark ? AppColors.darkMuted : AppColors.lightMuted),
      onTap: onTap,
    );
  }
}
