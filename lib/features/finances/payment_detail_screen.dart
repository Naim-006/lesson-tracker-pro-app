import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/models.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/providers/supabase_instructor_provider.dart';
import '../../core/services/receipt_storage_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/transaction_share.dart';

class PaymentDetailScreen extends ConsumerWidget {
  const PaymentDetailScreen({
    super.key,
    required this.transaction,
  });

  final Transaction transaction;

  bool get _isIncome => transaction.type == TransactionType.income;

  String get _screenTitle => _isIncome ? 'Payment Details' : 'Expense Details';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final sym = settings.currencySymbol;
    final hasReceipt = transaction.receiptUrl != null && transaction.receiptUrl!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_screenTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteDialog(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _isIncome ? AppColors.sunsetBright : AppColors.error,
                  (_isIncome ? AppColors.sunsetBright : AppColors.error).withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (_isIncome ? AppColors.sunsetBright : AppColors.error).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isIncome ? 'Amount Received' : 'Amount Paid',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  '$sym${transaction.amount.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                Text(
                  _isIncome ? 'Payment Details' : 'Expense Details',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 16),
                _DetailRow(
                  label: 'Date',
                  value: DateFormat('dd MMM yyyy').format(transaction.date),
                ),
                if (_isIncome) ...[
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: 'Pupil',
                    value: transaction.pupilName ?? 'General',
                  ),
                ],
                if (!_isIncome && transaction.category != null) ...[
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: 'Category',
                    value: labelEnum(transaction.category!),
                  ),
                ],
                const SizedBox(height: 12),
                _DetailRow(
                  label: 'Payment Method',
                  value: transaction.paymentMethod != null
                      ? labelEnum(transaction.paymentMethod!)
                      : 'N/A',
                ),
                if (_isIncome) ...[
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: 'Payment Type',
                    value: transaction.paymentType != null
                        ? labelEnum(transaction.paymentType!)
                        : 'N/A',
                  ),
                ],
                const SizedBox(height: 12),
                _DetailRow(
                  label: 'Description',
                  value: transaction.description,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                const Text('Receipt', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 16),
                if (hasReceipt) ...[
                  OutlinedButton.icon(
                    onPressed: () => _showReceiptDialog(context),
                    icon: const Icon(Icons.visibility),
                    label: const Text('View receipt'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: AppColors.sunsetBright),
                      foregroundColor: AppColors.sunsetBright,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _downloadReceipt(context),
                    icon: const Icon(Icons.download),
                    label: const Text('Download receipt'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: Colors.grey.shade400),
                      foregroundColor: Colors.grey.shade700,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ] else
                  Text(
                    'No receipt attached',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                const Text('Actions', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.share, color: AppColors.sunsetBright),
                  title: Text(
                    _isIncome ? 'Share payment' : 'Share expense',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text('Generate PDF and send'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _shareTransaction(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _shareTransaction(BuildContext context, WidgetRef ref) async {
    final sym = ref.read(settingsProvider).currencySymbol;
    try {
      await shareTransactionPdf(transaction: transaction, currencySymbol: sym);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not share: $e')),
        );
      }
    }
  }

  Future<void> _downloadReceipt(BuildContext context) async {
    final receiptRef = transaction.receiptUrl;
    if (receiptRef == null) return;

    try {
      final ext = receiptRef.contains('.') ? receiptRef.split('.').last : 'jpg';
      await ReceiptStorageService.downloadAndShare(
        receiptRef,
        'receipt_${transaction.id.substring(0, 8)}.$ext',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    final label = _isIncome ? 'payment' : 'expense';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${_isIncome ? 'Payment' : 'Expense'}'),
        content: Text('Are you sure you want to delete this $label? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              try {
                await Supabase.instance.client
                    .from('transactions')
                    .delete()
                    .eq('id', transaction.id);
                if (context.mounted) {
                  ref.invalidate(instructorPaymentsProvider);
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${_isIncome ? 'Payment' : 'Expense'} deleted')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting: $e')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showReceiptDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Receipt'),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder<String?>(
            future: ReceiptStorageService.resolveReceiptUrl(transaction.receiptUrl),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final url = snapshot.data;
              if (url == null) {
                return const Text('Could not load receipt. Check your connection and try again.');
              }
              return InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (_, __, ___) => const Text('Failed to display receipt image.'),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _downloadReceipt(context);
            },
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
