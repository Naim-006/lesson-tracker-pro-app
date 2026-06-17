import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/models.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/providers/supabase_instructor_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/csv_export.dart';

class ExportFormScreen extends ConsumerStatefulWidget {
  const ExportFormScreen({super.key});

  @override
  ConsumerState<ExportFormScreen> createState() => _ExportFormScreenState();
}

class _ExportFormScreenState extends ConsumerState<ExportFormScreen> {
  // Default to current UK fiscal year: April 1 → March 31
  late DateTime _from;
  late DateTime _to;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final fiscalYear = now.month >= 4 ? now.year : now.year - 1;
    _from = DateTime(fiscalYear, 4, 1);
    _to = DateTime(fiscalYear + 1, 3, 31);
  }

  Future<void> _pickFrom() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _from,
      firstDate: DateTime(2020),
      lastDate: _to,
    );
    if (d != null) setState(() => _from = d);
  }

  Future<void> _pickTo() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _to,
      firstDate: _from,
      lastDate: DateTime(2030),
    );
    if (d != null) setState(() => _to = d);
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final settings = ref.read(settingsProvider);
      final instructorPayments = ref.read(instructorPaymentsProvider);
      final instructorPupils = ref.read(instructorPupilsProvider);
      
      // Create pupil name map
      final pupilNames = <String, String>{};
      for (final link in instructorPupils.value ?? []) {
        final pupilData = link['pupils'];
        final profile = pupilData?['profiles'];
        if (pupilData != null && profile != null) {
          pupilNames[pupilData['id']] = profile['full_name'] ?? 'Unknown';
        }
      }
      
      // Convert Supabase payments to Transaction objects
      final transactions = instructorPayments.value?.map((payment) {
        final paymentTypeStr = payment['payment_type'] as String?;
        final type = paymentTypeStr == 'expense' ? TransactionType.expense : TransactionType.income;
        
        final paymentMethodStr = payment['payment_method'] as String?;
        PaymentMethod? paymentMethod;
        if (paymentMethodStr != null) {
          switch (paymentMethodStr) {
            case 'cash': paymentMethod = PaymentMethod.cash; break;
            case 'card': paymentMethod = PaymentMethod.card; break;
            case 'paypal': paymentMethod = PaymentMethod.paypal; break;
            case 'cheque': paymentMethod = PaymentMethod.cheque; break;
            case 'online': paymentMethod = PaymentMethod.online; break;
            default: paymentMethod = PaymentMethod.bankTransfer;
          }
        }
        
        final categoryStr = payment['category'] as String?;
        ExpenseCategory? category;
        if (categoryStr != null) {
          switch (categoryStr) {
            case 'accounts': category = ExpenseCategory.accounts; break;
            case 'advertising': category = ExpenseCategory.advertising; break;
            case 'association': category = ExpenseCategory.association; break;
            case 'bank_charges': category = ExpenseCategory.bankCharges; break;
            case 'computer': category = ExpenseCategory.computer; break;
            case 'dvsa_fees': category = ExpenseCategory.dvsaFees; break;
            case 'equipment': category = ExpenseCategory.equipment; break;
            case 'food_drink': category = ExpenseCategory.foodDrink; break;
            case 'franchise_fee': category = ExpenseCategory.franchiseFee; break;
            case 'fuel': category = ExpenseCategory.fuel; break;
            case 'insurance_business': category = ExpenseCategory.insuranceBusiness; break;
            case 'insurance_personal': category = ExpenseCategory.insurancePersonal; break;
            case 'insurance_vehicle': category = ExpenseCategory.insuranceVehicle; break;
            case 'insurance': category = ExpenseCategory.insurance; break;
            case 'maintenance': category = ExpenseCategory.maintenance; break;
            case 'lease': category = ExpenseCategory.lease; break;
            case 'training': category = ExpenseCategory.training; break;
            default: category = ExpenseCategory.other;
          }
        }
        
        final pupilId = payment['pupil_id'] as String?;
        final pupilName = pupilId != null ? pupilNames[pupilId] : null;
        
        return Transaction(
          id: payment['id'] as String,
          type: type,
          amount: (payment['amount'] as num).toDouble(),
          description: payment['description'] ?? 'Payment',
          date: DateTime.parse(payment['payment_date']),
          pupilId: pupilId,
          pupilName: pupilName,
          paymentMethod: paymentMethod,
          category: category,
        );
      }).toList() ?? [];

      await exportTransactionsCsv(
        transactions: transactions,
        start: _from,
        end: _to,
        currencySymbol: settings.currencySymbol,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report generating: Check your email in the next 5 min...')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('d MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Export Finances', style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.sunsetBright,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: _exporting ? null : _export,
              child: _exporting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Export', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.sunsetBright.withValues(alpha: 0.1), AppColors.sunsetBright.withValues(alpha: 0.05)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.sunsetBright.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.sunsetBright, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Exports all transactions within the selected date range as a CSV file. Defaults to the current UK fiscal year.',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Date Range Card
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.sunsetBright.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.date_range, color: AppColors.sunsetBright, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text('Date Range', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // From Date
                  InkWell(
                    onTap: _pickFrom,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: AppColors.sunsetBright, size: 20),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('From', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(df.format(_from), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                            ],
                          ),
                          const Spacer(),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // To Date
                  InkWell(
                    onTap: _pickTo,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: AppColors.sunsetBright, size: 20),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('To', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(df.format(_to), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                            ],
                          ),
                          const Spacer(),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Export Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.success, AppColors.success.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FilledButton.icon(
                onPressed: _exporting ? null : _export,
                icon: _exporting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.download),
                label: Text(_exporting ? 'Exporting…' : 'Export Finances'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
