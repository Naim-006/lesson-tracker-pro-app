import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers/supabase_instructor_provider.dart';
import '../../core/theme/app_colors.dart';

class MileageDialog extends ConsumerStatefulWidget {
  const MileageDialog({super.key});

  @override
  ConsumerState<MileageDialog> createState() => _MileageDialogState();
}

class _MileageDialogState extends ConsumerState<MileageDialog> {
  final _startMiles = TextEditingController();
  final _endMiles = TextEditingController();
  final _notes = TextEditingController();
  final _expenseAmount = TextEditingController();
  bool _isBusiness = true; // Using boolean instead of MileageType
  bool _addExpense = false;

  @override
  void dispose() {
    _startMiles.dispose();
    _endMiles.dispose();
    _notes.dispose();
    _expenseAmount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final start = double.tryParse(_startMiles.text);
    final end = double.tryParse(_endMiles.text);
    
    if (start == null || end == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid mileage values')),
      );
      return;
    }

    if (end < start) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End mileage must be greater than start mileage')),
      );
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final miles = end - start;
    
    try {
      // Add mileage entry
      await Supabase.instance.client.from('mileage_entries').insert({
        'instructor_id': user.id,
        'date': DateTime.now().toIso8601String().split('T')[0],
        'start_mileage': start,
        'end_mileage': end,
        'miles': miles,
        'type': _isBusiness ? 'business' : 'personal',
        'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      });

      // Add expense if enabled
      if (_addExpense) {
        final expenseAmount = double.tryParse(_expenseAmount.text);
        if (expenseAmount != null && expenseAmount > 0) {
          await Supabase.instance.client.from('transactions').insert({
            'instructor_id': user.id,
            'type': 'expense',
            'amount': expenseAmount,
            'description': 'Fuel expense - ${miles.toStringAsFixed(1)} miles',
            'date': DateTime.now().toIso8601String().split('T')[0],
            'category': 'fuel',
            'payment_method': 'cash',
          });
        }
      }

      if (mounted) {
        ref.invalidate(instructorMileageProvider);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mileage logged')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Log Mileage', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Type Selector
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _isBusiness = true),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isBusiness ? AppColors.sunsetBright : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Business',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _isBusiness ? Colors.white : Colors.grey.shade700,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _isBusiness = false),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isBusiness ? AppColors.sunsetBright : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Personal',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: !_isBusiness ? Colors.white : Colors.grey.shade700,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Start/End Miles
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
                          child: const Icon(Icons.speed, color: AppColors.sunsetBright, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text('Odometer Reading', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _startMiles,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Start (miles)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _endMiles,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'End (miles)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Add Expense Toggle
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
                          child: const Icon(Icons.receipt_long, color: AppColors.sunsetBright, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text('Add Expense', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Add fuel expense', style: TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: const Text('Track fuel cost for this trip'),
                      value: _addExpense,
                      onChanged: (v) => setState(() => _addExpense = v),
                      activeThumbColor: AppColors.sunsetBright,
                    ),
                    if (_addExpense) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _expenseAmount,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Amount (£)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Notes
              TextField(
                controller: _notes,
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.all(16),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              // Save Button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.sunsetBright, AppColors.sunsetBright.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.sunsetBright.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Save Mileage', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
