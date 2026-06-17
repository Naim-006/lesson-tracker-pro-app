import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';

class PaymentSettingsScreen extends ConsumerStatefulWidget {
  const PaymentSettingsScreen({super.key});

  @override
  ConsumerState<PaymentSettingsScreen> createState() => _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState extends ConsumerState<PaymentSettingsScreen> {
  final _stripePublicKeyController = TextEditingController();
  final _stripeSecretKeyController = TextEditingController();
  final _webhookSecretController = TextEditingController();
  final _platformFeeController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLiveMode = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _stripePublicKeyController.dispose();
    _stripeSecretKeyController.dispose();
    _webhookSecretController.dispose();
    _platformFeeController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final response = await Supabase.instance.client
          .from('app_settings')
          .select('*')
          .eq('key', 'payment_config')
          .single();

      final config = response['value'] as Map<String, dynamic>?;

      setState(() {
        _stripePublicKeyController.text = config?['stripe_public_key'] ?? '';
        _stripeSecretKeyController.text = config?['stripe_secret_key'] ?? '';
        _webhookSecretController.text = config?['webhook_secret'] ?? '';
        _platformFeeController.text = (config?['platform_fee_percent'] ?? 2.9).toString();
        _isLiveMode = config?['live_mode'] ?? true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    try {
      final fee = double.tryParse(_platformFeeController.text.trim()) ?? 2.9;

      await Supabase.instance.client
          .from('app_settings')
          .upsert({
            'key': 'payment_config',
            'value': {
              'stripe_public_key': _stripePublicKeyController.text.trim(),
              'stripe_secret_key': _stripeSecretKeyController.text.trim(),
              'webhook_secret': _webhookSecretController.text.trim(),
              'platform_fee_percent': fee,
              'live_mode': _isLiveMode,
            },
            'updated_at': DateTime.now().toIso8601String(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment settings saved successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving payment settings: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  color: Colors.white,
                  child: Row(
                    children: [
                      const Text(
                        'Payment Settings',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveSettings,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save),
                        label: Text(_isSaving ? 'Saving...' : 'Save'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.sunset,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stripe Configuration
                        _buildConfigCard(
                          title: 'Stripe Configuration',
                          icon: Icons.payment,
                          children: [
                            _buildModeToggle(),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _stripePublicKeyController,
                              decoration: const InputDecoration(
                                labelText: 'Stripe Public Key',
                                hintText: 'pk_live_... / pk_test_...',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.key),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _stripeSecretKeyController,
                              decoration: const InputDecoration(
                                labelText: 'Stripe Secret Key',
                                hintText: 'sk_live_... / sk_test_...',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                              obscureText: true,
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _webhookSecretController,
                              decoration: const InputDecoration(
                                labelText: 'Webhook Secret',
                                hintText: 'whsec_...',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.webhook),
                              ),
                              obscureText: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Platform & Payouts
                        _buildConfigCard(
                          title: 'Platform & Payouts',
                          icon: Icons.account_balance,
                          children: [
                            TextField(
                              controller: _platformFeeController,
                              decoration: const InputDecoration(
                                labelText: 'Platform Fee (%)',
                                hintText: '2.9',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.percent),
                                suffixText: '%',
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.info.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, color: AppColors.info, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Instructors will receive payouts minus this platform fee. '
                                      'Stripe also charges its own processing fee.',
                                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Stripe Connect
                        _buildConfigCard(
                          title: 'Stripe Connect (Instructor Payouts)',
                          icon: Icons.people_outline,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.check_circle, color: AppColors.success, size: 20),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Connect enabled',
                                        style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.success),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Instructors can connect their Stripe accounts to receive direct payouts. '
                                    'Pupil payment data is encrypted and processed via Stripe — no sensitive data is stored locally.',
                                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Accepted Payment Methods
                        _buildConfigCard(
                          title: 'Accepted Payment Methods',
                          icon: Icons.credit_card,
                          children: [
                            _PaymentMethodTile(
                              icon: Icons.credit_card,
                              title: 'Credit/Debit Cards',
                              subtitle: 'Visa, Mastercard, American Express',
                              enabled: true,
                            ),
                            const SizedBox(height: 12),
                            _PaymentMethodTile(
                              icon: Icons.account_balance,
                              title: 'Bank Transfer',
                              subtitle: 'Direct bank transfer',
                              enabled: true,
                            ),
                            const SizedBox(height: 12),
                            _PaymentMethodTile(
                              icon: Icons.paypal,
                              title: 'PayPal',
                              subtitle: 'PayPal payments',
                              enabled: false,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildConfigCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.sunset.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.sunset),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            _isLiveMode ? Icons.cloud_done : Icons.science,
            size: 20,
            color: _isLiveMode ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 10),
          Text(
            _isLiveMode ? 'Live Mode' : 'Test Mode',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: _isLiveMode ? AppColors.success : AppColors.warning,
            ),
          ),
          const Spacer(),
          Switch(
            value: _isLiveMode,
            activeTrackColor: AppColors.success.withValues(alpha: 0.4),
            activeThumbColor: AppColors.success,
            onChanged: (v) => setState(() => _isLiveMode = v),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: enabled ? AppColors.sunset : Colors.grey),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: enabled ? Colors.black : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Switch(value: enabled, onChanged: null),
        ],
      ),
    );
  }
}
