import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/error_handler.dart';

class MarkPaidResult {
  final String? paymentMethod;
  final bool skipRecording;

  const MarkPaidResult({this.paymentMethod, this.skipRecording = false});
}

class MarkPaidDialog extends ConsumerStatefulWidget {
  final Lesson lesson;

  const MarkPaidDialog({super.key, required this.lesson});

  @override
  ConsumerState<MarkPaidDialog> createState() => _MarkPaidDialogState();
}

class _MarkPaidDialogState extends ConsumerState<MarkPaidDialog> {
  String? _selectedMethod;
  bool _skipRecording = false;

  static const _methods = [
    ('Bank Transfer', Icons.account_balance, 'bank_transfer'),
    ('Cash', Icons.money, 'cash'),
    ('Card', Icons.credit_card, 'card'),
    ('Cheque', Icons.receipt_long, 'cheque'),
    ('PayPal', Icons.payments, 'paypal'),
    ('Revolut', Icons.currency_exchange, 'revolut'),
    ('Monzo', Icons.smartphone, 'monzo'),
    ('Stripe', Icons.bolt, 'stripe'),
    ('Other', Icons.more_horiz, 'other'),
  ];

  void _confirm() async {
    if (_skipRecording && _selectedMethod != null) {
      // Both selected — prefer skip recording? Or ask? For now, skip takes priority.
      // Actually let's just proceed with skip if it's checked.
    }

    if (_skipRecording) {
      try {
        await Supabase.instance.client
            .from('lessons')
            .update({'paid': true})
            .eq('id', widget.lesson.id);
        if (mounted) Navigator.pop(context, const MarkPaidResult(skipRecording: true));
      } catch (e) {
        if (mounted) _showError(e);
      }
      return;
    }

    if (_selectedMethod == null) return;

    try {
      await Supabase.instance.client
          .from('lessons')
          .update({'paid': true})
          .eq('id', widget.lesson.id);

      final now = DateTime.now();
      await Supabase.instance.client.from('transactions').insert({
        'instructor_id': Supabase.instance.client.auth.currentUser!.id,
        'pupil_id': widget.lesson.pupilId,
        'pupil_name': widget.lesson.pupilName,
        'type': 'income',
        'amount': widget.lesson.rate,
        'description': 'Lesson payment — ${widget.lesson.pupilName}',
        'date': DateFormat('yyyy-MM-dd').format(now),
        'payment_method': _selectedMethod,
      });

      if (mounted) Navigator.pop(context, MarkPaidResult(paymentMethod: _selectedMethod));
    } catch (e) {
      if (mounted) _showError(e);
    }
  }

  void _showError(Object e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(userFriendlyError(e))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Mark as Paid',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkText : AppColors.lightText)),
          const SizedBox(height: 4),
          Text('${widget.lesson.pupilName} — £${widget.lesson.rate.toStringAsFixed(0)}',
              style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkMuted : AppColors.lightMuted)),
          const SizedBox(height: 20),
          Text('Payment Method', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkText : AppColors.lightText)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _methods.map((m) {
              final label = m.$1;
              final icon = m.$2;
              final value = m.$3;
              final selected = _selectedMethod == value;
              return ActionChip(
                avatar: Icon(icon, size: 16,
                    color: selected ? Colors.white : (isDark ? AppColors.darkText : AppColors.lightText)),
                label: Text(label, style: TextStyle(
                    fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? Colors.white : (isDark ? AppColors.darkText : AppColors.lightText))),
                backgroundColor: selected ? AppColors.sunsetBright : null,
                side: selected ? BorderSide.none : BorderSide(
                    color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                onPressed: () => setState(() {
                  _selectedMethod = value;
                  if (_skipRecording) _skipRecording = false;
                }),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => setState(() {
              _skipRecording = !_skipRecording;
              if (_skipRecording) _selectedMethod = null;
            }),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(
                    _skipRecording ? Icons.check_box : Icons.check_box_outline_blank,
                    size: 22, color: _skipRecording ? AppColors.warning : (isDark ? AppColors.darkMuted : AppColors.lightMuted),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Skip recording payment', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkText : AppColors.lightText)),
                        Text('Mark as paid without saving to finances',
                            style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkMuted : AppColors.lightMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: (_skipRecording || _selectedMethod != null) ? _confirm : null,
              style: FilledButton.styleFrom(
                backgroundColor: _skipRecording ? AppColors.warning : AppColors.success,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                _skipRecording
                    ? 'Mark as Paid (skip recording)'
                    : 'Confirm — £${widget.lesson.rate.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
