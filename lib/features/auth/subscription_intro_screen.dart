import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/services/subscription_service.dart';
import '../shell/app_shell.dart';

class SubscriptionIntroScreen extends StatefulWidget {
  const SubscriptionIntroScreen({super.key});

  @override
  State<SubscriptionIntroScreen> createState() => _SubscriptionIntroScreenState();
}

class _SubscriptionIntroScreenState extends State<SubscriptionIntroScreen> {
  List<Map<String, dynamic>> _plans = [];
  bool _isLoading = true;
  bool _isSubscribed = false;
  int _trialDaysLeft = 0;
  String? _selectedPlanId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final plansResponse = await Supabase.instance.client
          .from('subscription_plans')
          .select('*')
          .eq('is_active', true)
          .order('price', ascending: true);

      final subResponse = await Supabase.instance.client
          .from('instructor_subscriptions')
          .select('id, end_date, status')
          .eq('instructor_id', user.id)
          .maybeSingle();

      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select('created_at')
          .eq('id', user.id)
          .single();

      final now = DateTime.now();
      bool subscribed = false;
      int trialDays = 0;

      if (subResponse != null) {
        final endDate = DateTime.parse(subResponse['end_date']);
        if (endDate.isAfter(now) && subResponse['status'] == 'active') {
          subscribed = true;
        }
      }

      if (!subscribed) {
        final createdAt = DateTime.parse(profileResponse['created_at']);
        final trialEnd = createdAt.add(const Duration(days: 60));
        if (trialEnd.isAfter(now)) {
          trialDays = trialEnd.difference(now).inDays;
        }
      }

      if (mounted) {
        setState(() {
          _plans = List<Map<String, dynamic>>.from(plansResponse);
          _isSubscribed = subscribed;
          _trialDaysLeft = trialDays;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _selectPlan(Map<String, dynamic> plan) {
    setState(() => _selectedPlanId = plan['id']);
  }

  Future<void> _continueFree() async {
    setState(() => _isLoading = true);
    final success = await SubscriptionService().activateFreeTrial();
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AppShell()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not activate free trial. Please try again.')),
        );
      }
    }
  }

  Future<void> _subscribeToPlan(Map<String, dynamic> plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _PaymentConfirmDialog(plan: plan),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    final success = await SubscriptionService().createSubscription(plan['id']);
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AppShell()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription failed. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF8F6F2),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildHeader(isDark),
                          const SizedBox(height: 32),
                          if (_isSubscribed)
                            _buildSubscribedBanner(isDark)
                          else if (_trialDaysLeft > 0)
                            _buildTrialBanner(isDark),
                          const SizedBox(height: 24),
                          _buildFeaturesSection(isDark),
                          const SizedBox(height: 24),
                          _buildPlansSection(isDark),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomBar(isDark),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.sunsetBright, AppColors.sunset],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.sunsetBright.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.school_rounded, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 20),
        Text(
          'Welcome to Lesson Tracker',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'The professional platform for driving instructors.\nManage pupils, diary, finances & more.',
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTrialBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4CAF50).withValues(alpha: 0.1),
            const Color(0xFF66BB6A).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4CAF50).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.celebration, color: Color(0xFF4CAF50), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Free Trial Active',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$_trialDaysLeft days remaining. Explore all features freely.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscribedBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.sunsetBright.withValues(alpha: 0.1),
            AppColors.sunset.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sunsetBright.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.sunsetBright.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.verified, color: AppColors.sunsetBright, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pro Subscriber',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'You have full access to all features.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(bool isDark) {
    final features = [
      _Feature(icon: Icons.calendar_month, title: 'Smart Diary', desc: 'Schedule lessons, manage slots'),
      _Feature(icon: Icons.people, title: 'Pupil Management', desc: 'Track progress & communication'),
      _Feature(icon: Icons.account_balance_wallet, title: 'Finances', desc: 'Income, expenses & reports'),
      _Feature(icon: Icons.message, title: 'Messaging', desc: 'Chat with pupils in real-time'),
      _Feature(icon: Icons.map, title: 'Route Planning', desc: 'Pickup & dropoff locations'),
      _Feature(icon: Icons.analytics, title: 'Progress Tracking', desc: 'Skills matrix & test reports'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Everything You Need',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Professional tools to run your driving school',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 16),
        ...features.map((f) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.sunsetBright.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(f.icon, color: AppColors.sunsetBright, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.title, style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14,
                      color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                    )),
                    Text(f.desc, style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey.shade500,
                    )),
                  ],
                ),
              ),
              Icon(Icons.check_circle, color: AppColors.sunsetBright.withValues(alpha: 0.5), size: 18),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildPlansSection(bool isDark) {
    if (_plans.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Your Plan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Select a plan that suits your needs',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 16),
        ..._plans.map((plan) => _buildPlanCard(plan, isDark)),
      ],
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan, bool isDark) {
    final id = plan['id'] as String;
    final name = plan['name'] as String? ?? 'Plan';
    final price = (plan['price'] as num?)?.toDouble() ?? 0;
    final duration = plan['duration_months'] as int? ?? 1;
    final features = List<String>.from(plan['features'] as List? ?? []);
    final isFree = plan['is_free_tier'] as bool? ?? false;
    final isSelected = _selectedPlanId == id;
    final isPopular = !isFree && price > 0 && duration >= 12;

    return GestureDetector(
      onTap: () => _selectPlan(plan),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    AppColors.sunsetBright.withValues(alpha: 0.12),
                    AppColors.sunset.withValues(alpha: 0.06),
                  ],
                )
              : null,
          color: isSelected ? null : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.sunsetBright
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.sunsetBright.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isFree
                        ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                        : AppColors.sunsetBright.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isFree ? 'FREE' : 'PRO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isFree ? const Color(0xFF4CAF50) : AppColors.sunsetBright,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (isPopular) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'POPULAR',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.warning,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (isSelected)
                  Icon(Icons.check_circle, color: AppColors.sunsetBright, size: 22)
                else
                  Icon(Icons.radio_button_unchecked, color: Colors.grey.shade400, size: 22),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isFree ? 'Free' : '£${price.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (!isFree) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, left: 4),
                    child: Text(
                      '/ $duration ${duration == 1 ? 'month' : 'months'}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey.shade500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black87,
              ),
            ),
            if (features.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(Icons.check, color: AppColors.sunsetBright, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    final hasSelectedPlan = _selectedPlanId != null;
    final selectedPlan = _plans.where((p) => p['id'] == _selectedPlanId).firstOrNull;
    final isFreeSelected = selectedPlan?['is_free_tier'] == true;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_trialDaysLeft > 0 && !_isSubscribed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => _continueFree(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(
                      color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    'Continue with Free Trial ($_trialDaysLeft days)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: (hasSelectedPlan && !_isLoading)
                  ? () {
                      if (isFreeSelected) {
                        _continueFree();
                      } else {
                        _subscribeToPlan(selectedPlan!);
                      }
                    }
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.sunsetBright,
                disabledBackgroundColor: AppColors.sunsetBright.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                hasSelectedPlan
                    ? (isFreeSelected ? 'Get Started Free' : 'Subscribe Now')
                    : 'Select a Plan',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentConfirmDialog extends StatelessWidget {
  final Map<String, dynamic> plan;
  const _PaymentConfirmDialog({required this.plan});

  @override
  Widget build(BuildContext context) {
    final price = plan['price'];
    final name = plan['name'];
    final duration = plan['duration_months'];
    final features = (plan['features'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return AlertDialog(
      title: Text('Subscribe to $name'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Plan: $name', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Price: \u00a3$price/month'),
          Text('Duration: $duration month(s)'),
          const SizedBox(height: 12),
          if (features.isNotEmpty) ...[
            const Text('Includes:', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(children: [
                    const Icon(Icons.check, size: 16, color: Colors.green),
                    const SizedBox(width: 6),
                    Expanded(child: Text(f, style: const TextStyle(fontSize: 13))),
                  ]),
                )),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline, size: 18, color: Colors.amber),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You will be redirected to complete payment. Your subscription will activate immediately.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ]),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.sunsetBright),
          child: const Text('Confirm & Pay'),
        ),
      ],
    );
  }
}

class _Feature {
  final IconData icon;
  final String title;
  final String desc;
  _Feature({required this.icon, required this.title, required this.desc});
}
