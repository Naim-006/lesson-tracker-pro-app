import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/app_state_provider.dart';
import '../../core/providers/supabase_instructor_provider.dart';
import '../../core/theme/app_colors.dart';

class ViewAllIncomeScreen extends ConsumerWidget {
  const ViewAllIncomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final instructorPayments = ref.watch(instructorPaymentsProvider);
    final instructorPupils = ref.watch(instructorPupilsProvider);
    final sym = settings.currencySymbol;

    // Create a map of pupil IDs to names
    final pupilNames = <String, String>{};
    for (final link in instructorPupils.value ?? []) {
      final pupilData = link['pupils'];
      if (pupilData != null) {
        final fullName = '${pupilData['first_name'] ?? ''} ${pupilData['last_name'] ?? ''}'.trim();
        pupilNames[pupilData['id']] = fullName.isNotEmpty ? fullName : 'Unknown';
      }
    }

    DateTime parseDate(Map<String, dynamic> m) {
      final s = (m['payment_date'] ?? m['date'] ?? m['created_at']) as String;
      return DateTime.parse(s);
    }

    // Filter income (type = 'income' or no type filter)
    final incomePayments = (instructorPayments.value ?? [])
        .where((p) => p['type'] == null || p['type'] == 'income')
        .toList()
      ..sort((a, b) => parseDate(b).compareTo(parseDate(a)));

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('All Income', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: incomePayments.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_downward,
                        size: 48,
                        color: AppColors.success.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'No income recorded',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: incomePayments.length,
              itemBuilder: (context, index) {
                final payment = incomePayments[index];
                final amount = (payment['amount'] as num).toDouble();
                final description = payment['description'] as String? ?? 'Payment';
                final paymentDate = parseDate(payment);
                final pupilId = payment['pupil_id'];
                final pupilName = pupilNames[pupilId];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.success, AppColors.success.withValues(alpha: 0.7)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.arrow_downward,
                              size: 24,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                description,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('d MMM yyyy').format(paymentDate) + (pupilName != null ? ' · $pupilName' : ''),
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '+$sym${amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
