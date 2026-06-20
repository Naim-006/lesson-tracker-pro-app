import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/models.dart';
import '../../core/providers/app_state_provider.dart';
import '../../core/providers/supabase_instructor_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_card.dart';

import 'payment_form_screen.dart';
import 'expense_form_screen.dart';
import 'export_form_screen.dart';
import 'view_all_income_screen.dart';
import 'view_all_expenses_screen.dart';
import 'all_mileage_screen.dart';

class FinancesScreen extends ConsumerStatefulWidget {
  const FinancesScreen({super.key});

  @override
  ConsumerState<FinancesScreen> createState() => _FinancesScreenState();
}

class _FinancesScreenState extends ConsumerState<FinancesScreen> {
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

  void _prevMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final instructorPayments = ref.watch(instructorPaymentsProvider);
    final instructorInvoices = ref.watch(instructorInvoicesProvider);
    final settings = ref.watch(settingsProvider);
    final sym = settings.currencySymbol;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final start = _focusedMonth;
    final end = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0, 23, 59, 59);

    // Convert Supabase payments to Transaction models
    final payments = instructorPayments.value?.map((payment) {
      return Transaction(
        id: payment['id'],
        type: TransactionType.income,
        amount: (payment['amount'] as num).toDouble(),
        date: DateTime.parse(payment['created_at']),
        description: 'Payment from pupil',
        category: ExpenseCategory.other,
      );
    }).toList() ?? [];

    // Convert Supabase invoices to Transaction models (as income)
    final invoices = instructorInvoices.value?.map((invoice) {
      return Transaction(
        id: invoice['id'],
        type: TransactionType.income,
        amount: (invoice['amount'] as num).toDouble(),
        date: DateTime.parse(invoice['created_at']),
        description: 'Invoice #${invoice['invoice_number']}',
        category: ExpenseCategory.other,
      );
    }).toList() ?? [];

    // Combine payments and invoices
    final allTransactions = [...payments, ...invoices];

    final txs = allTransactions.where((t) {
      return !t.date.isBefore(start) && !t.date.isAfter(end);
    }).toList();

    final incomeTxs = txs.where((t) => t.type == TransactionType.income).toList();
    final expenseTxs = txs.where((t) => t.type == TransactionType.expense).toList();

    final income = incomeTxs.fold<double>(0, (s, t) => s + t.amount);
    final expense = expenseTxs.fold<double>(0, (s, t) => s + t.amount);
    final profit = income - expense;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              // Month Navigator
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  children: [
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: _prevMonth,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.chevron_left, size: 20, color: isDark ? AppColors.darkText : AppColors.lightText),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.sunsetBright.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          DateFormat('MMMM yyyy').format(_focusedMonth).toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.sunsetBright,
                            letterSpacing: 0.8,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: _nextMonth,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.chevron_right, size: 20, color: isDark ? AppColors.darkText : AppColors.lightText),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // KPI Block
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: _Kpi(
                        label: 'Income',
                        value: '$sym${income.toStringAsFixed(0)}',
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Kpi(
                        label: 'Expenses',
                        value: '$sym${expense.toStringAsFixed(0)}',
                        color: isDark ? AppColors.darkText : AppColors.lightText,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Kpi(
                        label: 'Net Profit',
                        value: '$sym${profit.toStringAsFixed(0)}',
                        color: profit >= 0 ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Menu Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentFormScreen()));
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add payment'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.sunsetBright,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseFormScreen()));
                        },
                        icon: const Icon(Icons.remove, size: 18),
                        label: const Text('Add expense'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: AppColors.sunsetBright),
                          foregroundColor: AppColors.sunsetBright,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),

        // Section: Income
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Income', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: isDark ? AppColors.darkText : AppColors.lightText)),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ViewAllIncomeScreen()));
                  },
                  child: const Text('View all \u2192', style: TextStyle(color: AppColors.sunsetBright, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
        if (incomeTxs.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_downward, size: 28, color: AppColors.success.withValues(alpha: 0.6)),
                    ),
                    const SizedBox(height: 12),
                    Text('No income recorded this month', style: TextStyle(color: AppColors.lightMuted, fontWeight: FontWeight.w500, fontSize: 14)),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _TransactionTile(t: incomeTxs[index], sym: sym),
                childCount: incomeTxs.length > 3 ? 3 : incomeTxs.length,
              ),
            ),
          ),

        // Section: Expenses
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Expenses', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: isDark ? AppColors.darkText : AppColors.lightText)),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ViewAllExpensesScreen()));
                  },
                  child: const Text('View all \u2192', style: TextStyle(color: AppColors.sunsetBright, fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
        if (expenseTxs.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_upward, size: 28, color: AppColors.error.withValues(alpha: 0.6)),
                    ),
                    const SizedBox(height: 12),
                    Text('No expenses recorded this month', style: TextStyle(color: AppColors.lightMuted, fontWeight: FontWeight.w500, fontSize: 14)),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _TransactionTile(t: expenseTxs[index], sym: sym),
                childCount: expenseTxs.length > 3 ? 3 : expenseTxs.length,
              ),
            ),
          ),

        // Other links
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
            child: Column(
              children: [
                _LinkTile(
                  icon: Icons.directions_car,
                  title: 'View all mileage records',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AllMileageScreen()));
                  },
                ),
                const SizedBox(height: 8),
                _LinkTile(
                  icon: Icons.download,
                  title: 'Export finances',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ExportFormScreen()));
                  },
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      contentPadding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(children: [
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 20, height: 1.1),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.lightMuted, letterSpacing: 0.6),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ]),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.t, required this.sym});
  final Transaction t;
  final String sym;

  @override
  Widget build(BuildContext context) {
    final isIncome = t.type == TransactionType.income;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: (isIncome ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              size: 22,
              color: isIncome ? AppColors.success : AppColors.error,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.description, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 2),
          Text(
            DateFormat('d MMM yyyy').format(t.date) + (t.pupilName != null ? ' \u00b7 ${t.pupilName}' : ''),
            style: TextStyle(fontSize: 12, color: AppColors.lightMuted),
          ),
        ])),
        Flexible(child: Text(
          '${isIncome ? '+' : '-'}$sym${t.amount.toStringAsFixed(2)}',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: isIncome ? AppColors.success : AppColors.error),
          overflow: TextOverflow.ellipsis,
        )),
      ]),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.icon, required this.title, required this.onTap});
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppCard(
      margin: EdgeInsets.zero,
      onTap: onTap,
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.sunsetBright.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.sunsetBright, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? AppColors.darkText : AppColors.lightText))),
        Icon(Icons.chevron_right, size: 20, color: AppColors.lightMuted),
      ]),
    );
  }
}
