import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:functions_client/functions_client.dart';

import '../../core/theme/app_colors.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  List<Map<String, dynamic>> _plans = [];
  Map<String, dynamic>? _currentSubscription;
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final plansRes = await Supabase.instance.client
          .from('subscription_plans')
          .select('*')
          .eq('is_active', true)
          .order('price', ascending: true);

      final subRes = await Supabase.instance.client
          .from('instructor_subscriptions')
          .select('*')
          .eq('instructor_id', user.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      final paymentsRes = await Supabase.instance.client
          .from('instructor_payments')
          .select('*')
          .eq('instructor_id', user.id)
          .order('payment_date', ascending: false);

      if (mounted) {
        setState(() {
          _plans = List<Map<String, dynamic>>.from(plansRes);
          _currentSubscription = subRes;
          _payments = List<Map<String, dynamic>>.from(paymentsRes);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pay(String planId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in first'), backgroundColor: AppColors.error),
        );
      }
      setState(() => _isProcessing = false);
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'create-checkout-session',
        body: { 'plan_id': planId },
      );

      final data = response.data is Map<String, dynamic> ? response.data as Map<String, dynamic> : null;
      final url = data?['url'] as String?;

      if (url != null) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create payment session'), backgroundColor: AppColors.error),
          );
        }
      }
    } on FunctionException catch (e) {
      if (mounted) {
        final msg = e.details is Map ? (e.details as Map)['error'] ?? 'Unknown error' : 'Unknown error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$msg (${e.status})'), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF8F6F2),
      appBar: AppBar(
        title: const Text('Subscription & Billing'),
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCurrentPlan(isDark),
                    const SizedBox(height: 16),
                    _buildPaymentHistory(isDark),
                    const SizedBox(height: 16),
                    _buildAvailablePlans(isDark),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCurrentPlan(bool isDark) {
    final isSubscribed = _currentSubscription != null &&
        _currentSubscription!['status'] == 'active' &&
        DateTime.parse(_currentSubscription!['end_date']).isAfter(DateTime.now());

    final planName = _currentSubscription?['plan_type'] as String? ?? 'Free Trial';
    final amount = _currentSubscription?['amount'] as num? ?? 0;
    final endDate = _currentSubscription?['end_date'] as String?;
    final paymentStatus = _currentSubscription?['payment_status'] as String? ?? 'pending';

    final bgColor = isSubscribed
        ? (isDark ? Colors.green.withValues(alpha: 0.08) : const Color(0xFFF0FDF4))
        : (isDark ? AppColors.darkCard : Colors.white);

    final borderColor = isSubscribed
        ? (isDark ? Colors.green.withValues(alpha: 0.2) : const Color(0xFFBBF7D0))
        : (isDark ? AppColors.darkBorder : AppColors.lightBorder);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Current Plan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.grey.shade500)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSubscribed
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isSubscribed ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSubscribed ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            planName,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            amount > 0 ? '£${amount.toStringAsFixed(2)}/month' : 'Free',
            style: TextStyle(fontSize: 14, color: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.grey.shade600),
          ),
          if (endDate != null) ...[
            const SizedBox(height: 4),
            Text(
              'Ends ${_formatDate(endDate)}',
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey.shade500),
            ),
          ],
          if (paymentStatus == 'pending' && amount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Payment pending. Complete payment to activate your subscription.',
                      style: TextStyle(fontSize: 12, color: AppColors.warning, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentHistory(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Payment History', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87)),
              if (_payments.isNotEmpty)
                Text('${_payments.length} total', style: TextStyle(fontSize: 12, color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey.shade500)),
            ],
          ),
          const SizedBox(height: 12),
          if (_payments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 40, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    Text('No payments yet', style: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey.shade500)),
                  ],
                ),
              ),
            )
          else
            ...List.generate(_payments.length, (i) {
              final p = _payments[i];
              return _buildPaymentRow(p, isDark, i == _payments.length - 1);
            }),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(Map<String, dynamic> payment, bool isDark, bool isLast) {
    final date = payment['payment_date'] as String? ?? '';
    final amount = payment['amount'] as num? ?? 0;
    final status = payment['status'] as String? ?? '';
    final description = payment['description'] as String? ?? '';

    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: status == 'completed' ? AppColors.success.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                status == 'completed' ? Icons.check_circle : Icons.pending,
                size: 16,
                color: status == 'completed' ? AppColors.success : AppColors.warning,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description.isNotEmpty ? description : 'Subscription payment',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black87),
                  ),
                  Text(
                    _formatDate(date),
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            Text(
              '£${amount.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87),
            ),
          ],
        ),
        if (!isLast) ...[
          const SizedBox(height: 10),
          Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildAvailablePlans(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Available Plans', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 10),
        ...List.generate(_plans.length, (i) {
          final plan = _plans[i];
          final planId = plan['id'] as String;
          final name = plan['name'] as String? ?? '';
          final price = plan['price'] as num? ?? 0;
          final duration = plan['duration_months'] as num? ?? 1;
          final features = plan['features'] as List? ?? [];
          final isCurrent = _currentSubscription?['plan_id'] == planId;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isCurrent
                  ? LinearGradient(
                      colors: [AppColors.sunsetBright.withValues(alpha: 0.08), AppColors.sunset.withValues(alpha: 0.03)],
                    )
                  : null,
              color: isCurrent ? null : (isDark ? AppColors.darkCard : Colors.white),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isCurrent ? AppColors.sunsetBright.withValues(alpha: 0.3) : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          price > 0 ? '£${price.toStringAsFixed(2)}/mo' : 'Free',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.sunsetBright),
                        ),
                      ],
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.sunsetBright.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Current',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.sunsetBright),
                        ),
                      )
                    else
                      FilledButton(
                        onPressed: price > 0 ? () => _pay(planId) : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.sunsetBright,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isProcessing
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Subscribe'),
                      ),
                  ],
                ),
                if (features.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ...List.generate(features.length, (j) {
                    final feature = features[j] as String? ?? '';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.check, size: 14, color: AppColors.success),
                          const SizedBox(width: 6),
                          Text(
                            feature,
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.grey.shade600),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day} ${_months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
}
