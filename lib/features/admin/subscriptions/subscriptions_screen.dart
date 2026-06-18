import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';

class SubscriptionsScreen extends ConsumerStatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  ConsumerState<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends ConsumerState<SubscriptionsScreen> {
  List<Map<String, dynamic>> _subscriptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubscriptions();
  }

  Future<void> _loadSubscriptions() async {
    try {
      final response = await Supabase.instance.client
          .from('instructor_subscriptions')
          .select('''
            id,
            start_date,
            end_date,
            status,
            plan_type,
            profiles(
              full_name,
              email
            )
          ''')
          .order('created_at', ascending: false);

      setState(() {
        _subscriptions = response as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading subscriptions: $e')),
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
                        'Subscriptions',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () => _showCreateDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Create Subscription'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.sunset,
                        ),
                      ),
                    ],
                  ),
                ),
                // Subscriptions list
                Expanded(
                  child: _subscriptions.isEmpty
                      ? const Center(
                          child: Text('No subscriptions found'),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadSubscriptions,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _subscriptions.length,
                            itemBuilder: (context, index) {
                              final subscription = _subscriptions[index];
                              final profile = subscription['profiles'] as Map?;
                              return _buildSubscriptionCard(subscription, profile);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSubscriptionCard(Map<String, dynamic> subscription, Map? profile) {
    final status = subscription['status'] as String?;
    final isActive = status == 'active';
    final planType = subscription['plan_type'] as String? ?? 'basic';
    final startDate = subscription['start_date'] as String?;
    final endDate = subscription['end_date'] as String?;
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
                    Text(
                      profile?['full_name'] ?? 'Unknown Instructor',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile?['email'] ?? '',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
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
                  status?.toUpperCase() ?? 'UNKNOWN',
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
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  title: 'Plan',
                  value: planType.toUpperCase(),
                  icon: Icons.subscriptions,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  title: 'Start Date',
                  value: startDate != null ? _formatDate(startDate) : 'N/A',
                  icon: Icons.calendar_today,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  title: 'End Date',
                  value: endDate != null ? _formatDate(endDate) : 'N/A',
                  icon: Icons.event,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showDetailsDialog(subscription, profile),
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Details'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showEditDialog(subscription),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _cancelSubscription(subscription['id']),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel'),
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

  void _showDetailsDialog(Map<String, dynamic> subscription, Map? profile) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(profile?['full_name'] ?? 'Subscription Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Instructor: ${profile?['full_name'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Email: ${profile?['email'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Plan: ${subscription['plan_type'] ?? 'basic'}'),
            const SizedBox(height: 8),
            Text('Status: ${subscription['status'] ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Start: ${_formatDate(subscription['start_date'])}'),
            const SizedBox(height: 8),
            Text('End: ${_formatDate(subscription['end_date'])}'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  void _showCreateDialog() async {
    final instructors = await Supabase.instance.client
        .from('profiles')
        .select('id, full_name')
        .eq('role', 'instructor')
        .order('full_name');

    if (!mounted) return;

    final instructorsList = (instructors as List).cast<Map<String, dynamic>>();
    String? selectedInstructorId;
    final planController = TextEditingController();
    final startDateCtrl = TextEditingController(text: DateTime.now().toIso8601String().split('T')[0]);
    final endDateCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Subscription'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Instructor'),
                items: instructorsList.map((i) => DropdownMenuItem(
                  value: i['id'] as String,
                  child: Text(i['full_name'] as String? ?? ''),
                )).toList(),
                onChanged: (v) => selectedInstructorId = v,
              ),
              const SizedBox(height: 12),
              TextField(controller: planController, decoration: const InputDecoration(labelText: 'Plan Type (e.g. monthly, yearly)')),
              const SizedBox(height: 12),
              TextField(controller: startDateCtrl, decoration: const InputDecoration(labelText: 'Start Date (YYYY-MM-DD)')),
              const SizedBox(height: 12),
              TextField(controller: endDateCtrl, decoration: const InputDecoration(labelText: 'End Date (YYYY-MM-DD)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (selectedInstructorId == null || planController.text.isEmpty || endDateCtrl.text.isEmpty) return;
              try {
                await Supabase.instance.client.from('instructor_subscriptions').insert({
                  'instructor_id': selectedInstructorId,
                  'plan_type': planController.text.trim(),
                  'status': 'active',
                  'start_date': startDateCtrl.text.trim(),
                  'end_date': endDateCtrl.text.trim(),
                  'created_at': DateTime.now().toIso8601String(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subscription created')));
                  _loadSubscriptions();
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> subscription) {
    final id = subscription['id'] as String?;
    if (id == null) return;

    final statusCtrl = TextEditingController(text: subscription['status'] as String? ?? '');
    final endDateCtrl = TextEditingController(text: (subscription['end_date'] as String? ?? '').split('T')[0]);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Subscription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: statusCtrl, decoration: const InputDecoration(labelText: 'Status')),
            const SizedBox(height: 12),
            TextField(controller: endDateCtrl, decoration: const InputDecoration(labelText: 'End Date (YYYY-MM-DD)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              try {
                await Supabase.instance.client.from('instructor_subscriptions').update({
                  'status': statusCtrl.text.trim(),
                  'end_date': endDateCtrl.text.trim(),
                }).eq('id', id);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subscription updated')));
                  _loadSubscriptions();
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelSubscription(String? id) async {
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text('Are you sure you want to cancel this subscription?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Yes, Cancel'), style: FilledButton.styleFrom(backgroundColor: AppColors.error)),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await Supabase.instance.client.from('instructor_subscriptions').update({'status': 'cancelled'}).eq('id', id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Subscription cancelled')));
        _loadSubscriptions();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardElevated : AppColors.lightCard,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    final date = DateTime.tryParse(dateString);
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }
}
