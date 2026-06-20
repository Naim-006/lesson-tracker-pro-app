import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading = true;
  String? _error;
  final Set<String> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await Supabase.instance.client
          .from('instructor_payments')
          .select('''
            id,
            amount,
            payment_date,
            status,
            payment_method,
            profiles(
              full_name,
              email
            )
          ''')
          .order('payment_date', ascending: false);

      setState(() {
        _payments = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load payments. Please try again.';
      });
    }
  }

  void _showCreatePaymentDialog() {
    final amountController = TextEditingController();
    String? selectedMethod;
    final methods = ['bank_transfer', 'credit_card', 'cash', 'other'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text('Process Payment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount (\$)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedMethod,
                  decoration: const InputDecoration(
                    labelText: 'Payment Method',
                    border: OutlineInputBorder(),
                  ),
                  items: methods
                      .map((m) => DropdownMenuItem(value: m, child: Text(m.toUpperCase())))
                      .toList(),
                  onChanged: (value) {
                    setDialogState(() => selectedMethod = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0 || selectedMethod == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid amount and method')),
                  );
                  return;
                }
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                try {
                  await Supabase.instance.client.from('instructor_payments').insert({
                    'amount': amount,
                    'payment_date': DateTime.now().toIso8601String(),
                    'status': 'pending',
                    'payment_method': selectedMethod,
                  });
                  if (!mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Payment created successfully')),
                  );
                  _loadPayments();
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(content: Text('Failed to create payment: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.sunset),
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentDetails(Map<String, dynamic> payment, Map? profile) {
    final status = payment['status'] as String? ?? 'unknown';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Payment Details',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 20),
              _detailRow(context, 'Instructor', profile?['full_name'] ?? 'Unknown'),
              _detailRow(context, 'Email', profile?['email'] ?? ''),
              _detailRow(context, 'Amount',
                  '\$${(payment['amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
              _detailRow(context, 'Date',
                  payment['payment_date'] != null ? _formatDate(payment['payment_date'] as String) : 'N/A'),
              _detailRow(context, 'Method',
                  (payment['payment_method'] as String?)?.toUpperCase() ?? 'N/A'),
              _detailRow(context, 'Status', status.toUpperCase(),
                  valueColor: _getStatusColor(status)),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)), overflow: TextOverflow.ellipsis, maxLines: 1),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: valueColor), overflow: TextOverflow.ellipsis, maxLines: 1, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }

  Future<void> _approvePayment(String id) async {
    setState(() => _processingIds.add(id));
    try {
      await Supabase.instance.client
          .from('instructor_payments')
          .update({'status': 'approved'}).eq('id', id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment approved')),
        );
        _loadPayments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(id));
    }
  }

  Future<void> _rejectPayment(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: const Text('Reject Payment'),
        content: const Text('Are you sure you want to reject this payment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _processingIds.add(id));
    try {
      await Supabase.instance.client
          .from('instructor_payments')
          .update({'status': 'rejected'}).eq('id', id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment rejected')),
        );
        _loadPayments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reject: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _processingIds.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(_error!, style: TextStyle(color: isDark ? AppColors.darkMuted : AppColors.lightMuted)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPayments,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPayments,
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(24),
                        color: isDark ? AppColors.darkCard : AppColors.lightCard,
                        child: Row(
                          children: [
                            Text(
                              'Payments',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.darkText : AppColors.lightText,
                              ),
                            ),
                            const Spacer(),
                            ElevatedButton.icon(
                              onPressed: _showCreatePaymentDialog,
                              icon: const Icon(Icons.payment),
                              label: const Text('Process Payment'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.sunset,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Payments list
                      Expanded(
                        child: _payments.isEmpty
                            ? Center(
                                child: Text(
                                  'No payments found',
                                  style: TextStyle(
                                    color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: _payments.length,
                                itemBuilder: (context, index) {
                                  final payment = _payments[index];
                                  final profile = payment['profiles'] as Map?;
                                  return _buildPaymentCard(payment, profile);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment, Map? profile) {
    final amount = payment['amount'] as num?;
    final paymentDate = payment['payment_date'] as String?;
    final status = payment['status'] as String?;
    final paymentMethod = payment['payment_method'] as String?;
    final id = payment['id'] as String?;
    final isProcessing = id != null && _processingIds.contains(id);
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile?['email'] ?? '',
                      style: TextStyle(
                        color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${amount?.toStringAsFixed(2) ?? '0.00'}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  title: 'Date',
                  value: paymentDate != null ? _formatDate(paymentDate) : 'N/A',
                  icon: Icons.calendar_today,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  title: 'Method',
                  value: paymentMethod?.toUpperCase() ?? 'N/A',
                  icon: Icons.payment,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  title: 'Status',
                  value: status?.toUpperCase() ?? 'UNKNOWN',
                  icon: Icons.info,
                  color: _getStatusColor(status),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showPaymentDetails(payment, profile),
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Details'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isProcessing || id == null
                      ? null
                      : () => _approvePayment(id),
                  icon: isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle),
                  label: const Text('Approve'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isProcessing || id == null
                      ? null
                      : () => _rejectPayment(id),
                  icon: isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cancel),
                  label: const Text('Reject'),
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

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    Color? color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardElevated : AppColors.lightBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color ?? (isDark ? AppColors.darkMuted : AppColors.lightMuted)),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkMuted : AppColors.lightMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
      case 'approved':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'failed':
      case 'rejected':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateString;
    }
  }
}
