import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';

class SubscriptionPlansScreen extends ConsumerStatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  ConsumerState<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends ConsumerState<SubscriptionPlansScreen> {
  List<Map<String, dynamic>> _plans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    try {
      final response = await Supabase.instance.client
          .from('subscription_plans')
          .select('*')
          .order('price', ascending: true);

      setState(() {
        _plans = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading plans: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  child: Row(
                    children: [
                      const Text(
                        'Subscription Plans',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Flexible(
                        child: ElevatedButton.icon(
                          onPressed: () => _showCreatePlanDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Create Plan', maxLines: 1, overflow: TextOverflow.ellipsis),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.sunset,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Plans list
                Expanded(
                  child: _plans.isEmpty
                      ? const Center(
                          child: Text('No subscription plans found'),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadPlans,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _plans.length,
                            itemBuilder: (context, index) {
                              final plan = _plans[index];
                              return _buildPlanCard(plan);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final name = plan['name'] as String?;
    final price = plan['price'] as num?;
    final durationMonths = plan['duration_months'] as int?;
    final features = plan['features'] as List?;
    final isActive = plan['is_active'] as bool? ?? false;
    final isFreeTier = plan['is_free_tier'] as bool? ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name ?? 'Unknown Plan',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        if (isFreeTier) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'FREE TIER',
                              style: TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${price?.toStringAsFixed(2) ?? '0.00'}/${durationMonths ?? 1} month${(durationMonths ?? 1) > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.sunset,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: isActive ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (features != null && features.isNotEmpty) ...[
            const Text(
              'Features:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            ...features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature.toString(),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            )),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showEditPlanDialog(plan),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _togglePlanActive(plan),
                  icon: Icon(isActive ? Icons.block : Icons.check_circle),
                  label: Text(isActive ? 'Deactivate' : 'Activate'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _deletePlan(plan),
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCreatePlanDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final durationController = TextEditingController();
    final featuresController = TextEditingController();
    bool isFreeTier = false;
    bool isActive = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Subscription Plan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Plan Name',
                    hintText: 'e.g., Basic, Pro, Enterprise',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price (USD)',
                    hintText: 'e.g., 29.99',
                  ),
                  keyboardType: TextInputType.number,
                  enabled: !isFreeTier,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duration (months)',
                    hintText: 'e.g., 1, 3, 6, 12',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: featuresController,
                  decoration: const InputDecoration(
                    labelText: 'Features (comma-separated)',
                    hintText: 'e.g., Unlimited pupils, Priority support, Advanced analytics',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Free Tier (2 months)'),
                  value: isFreeTier,
                  onChanged: (value) => setDialogState(() => isFreeTier = value),
                ),
                SwitchListTile(
                  title: const Text('Active'),
                  value: isActive,
                  onChanged: (value) => setDialogState(() => isActive = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);
                try {
                  await Supabase.instance.client.from('subscription_plans').insert({
                    'name': nameController.text.trim(),
                    'price': isFreeTier ? 0 : double.tryParse(priceController.text) ?? 0,
                    'duration_months': int.tryParse(durationController.text) ?? 1,
                    'features': featuresController.text.split(',').map((e) => e.trim()).toList(),
                    'is_free_tier': isFreeTier,
                    'is_active': isActive,
                    'created_at': DateTime.now().toIso8601String(),
                  });
                  if (!mounted) return;
                  navigator.pop();
                  _loadPlans();
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error creating plan: $e')),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPlanDialog(Map<String, dynamic> plan) {
    final nameController = TextEditingController(text: plan['name'] as String? ?? '');
    final priceController = TextEditingController(text: (plan['price'] as num?)?.toString() ?? '');
    final durationController = TextEditingController(text: (plan['duration_months'] as int?)?.toString() ?? '');
    final featuresController = TextEditingController(
      text: (plan['features'] as List?)?.join(', ') ?? '',
    );
    bool isFreeTier = plan['is_free_tier'] as bool? ?? false;
    bool isActive = plan['is_active'] as bool? ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Subscription Plan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Plan Name',
                    hintText: 'e.g., Basic, Pro, Enterprise',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price (USD)',
                    hintText: 'e.g., 29.99',
                  ),
                  keyboardType: TextInputType.number,
                  enabled: !isFreeTier,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duration (months)',
                    hintText: 'e.g., 1, 3, 6, 12',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: featuresController,
                  decoration: const InputDecoration(
                    labelText: 'Features (comma-separated)',
                    hintText: 'e.g., Unlimited pupils, Priority support, Advanced analytics',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Free Tier (2 months)'),
                  value: isFreeTier,
                  onChanged: (value) => setDialogState(() => isFreeTier = value),
                ),
                SwitchListTile(
                  title: const Text('Active'),
                  value: isActive,
                  onChanged: (value) => setDialogState(() => isActive = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);
                try {
                  await Supabase.instance.client.from('subscription_plans').update({
                    'name': nameController.text.trim(),
                    'price': isFreeTier ? 0 : double.tryParse(priceController.text) ?? 0,
                    'duration_months': int.tryParse(durationController.text) ?? 1,
                    'features': featuresController.text.split(',').map((e) => e.trim()).toList(),
                    'is_free_tier': isFreeTier,
                    'is_active': isActive,
                  }).eq('id', plan['id']);
                  if (!mounted) return;
                  navigator.pop();
                  _loadPlans();
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error updating plan: $e')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePlanActive(Map<String, dynamic> plan) async {
    final newActive = !(plan['is_active'] as bool? ?? false);
    try {
      await Supabase.instance.client
          .from('subscription_plans')
          .update({'is_active': newActive})
          .eq('id', plan['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(newActive ? 'Plan activated' : 'Plan deactivated')),
        );
        _loadPlans();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating plan: $e')),
        );
      }
    }
  }

  Future<void> _deletePlan(Map<String, dynamic> plan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Plan'),
        content: Text('Are you sure you want to delete "${plan['name']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await Supabase.instance.client.from('subscription_plans').delete().eq('id', plan['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Plan deleted')),
        );
        _loadPlans();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting plan: $e')),
        );
      }
    }
  }
}
