import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/models/models.dart';
import '../../core/providers/supabase_instructor_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/error_handler.dart';

class RequestPaymentFormScreen extends ConsumerStatefulWidget {
  const RequestPaymentFormScreen({super.key, this.initialPupilId});

  final String? initialPupilId;

  @override
  ConsumerState<RequestPaymentFormScreen> createState() => _RequestPaymentFormScreenState();
}

class _RequestPaymentFormScreenState extends ConsumerState<RequestPaymentFormScreen> {
  Pupil? _pupil;
  bool _isPackage = false;
  double _amount = 0;
  final _amountCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  List<Map<String, dynamic>> _unpaid = [];
  final Set<String> _selIds = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPupilId != null) _resolvePupil(widget.initialPupilId!);
  }

  void _resolvePupil(String pid) async {
    final list = await ref.read(instructorPupilsProvider.future);
    final match = list.cast<Map<String, dynamic>?>().firstWhere(
      (l) => (l?['pupils'] as Map<String, dynamic>?)?['id'] == pid, orElse: () => null);
    if (match != null && mounted) {
      final d = match['pupils'] as Map<String, dynamic>;
      setState(() => _pupil = Pupil(
        id: d['id'], firstName: d['first_name'] ?? '', lastName: d['last_name'] ?? '',
        phone: d['phone'] ?? '', email: d['email'] ?? '',
        hourlyRate: (d['hourly_rate'] as num?)?.toDouble() ?? 40,
      ));
      _loadUnpaid(pid);
    }
  }

  @override void dispose() { _amountCtrl.dispose(); _msgCtrl.dispose(); super.dispose(); }

  Future<void> _loadUnpaid(String pid) async {
    setState(() => _loading = true);
    ref.invalidate(pupilUnpaidLessonsProvider(pid));
    final u = await ref.read(pupilUnpaidLessonsProvider(pid).future);
    if (mounted) {
      setState(() {
        _unpaid = u;
        _selIds.addAll(u.map((l) => l['id'] as String));
        _calc();
        _loading = false;
      });
    }
  }

  void _calc() {
    final t = _unpaid.fold<double>(0, (s, l) => _selIds.contains(l['id']) ? s + ((l['rate'] as num?)?.toDouble() ?? 0) : s);
    setState(() { _amount = t; _amountCtrl.text = t.toStringAsFixed(2); });
  }

  void _toggle(String id) { setState(() { _selIds.contains(id) ? _selIds.remove(id) : _selIds.add(id); }); _calc(); }

  Future<void> _send() async {
    if (_pupil == null || _amount <= 0) return;
    final u = Supabase.instance.client.auth.currentUser;
    if (u == null) return;
    try {
      await Supabase.instance.client.from('instructor_payment_requests').insert({
        'instructor_id': u.id, 'pupil_id': _pupil!.id,
        'lesson_ids': _selIds.toList(), 'amount': _amount,
        'description': _msgCtrl.text.trim().isEmpty ? 'Payment for ${_selIds.length} lesson(s)' : _msgCtrl.text.trim(),
        'status': 'pending', 'created_at': DateTime.now().toIso8601String(),
      });
      if (mounted) {
        ref.invalidate(instructorLessonsProvider);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('\u00a3${_amount.toStringAsFixed(2)} requested from ${_pupil!.firstName}')));
        Navigator.pop(context);
      }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(userFriendlyError(e)))); }
  }

  @override
  Widget build(BuildContext context) {
    final pupils = (ref.watch(instructorPupilsProvider).value ?? []).map((l) {
      final d = l['pupils'] ?? <String, dynamic>{};
      return Pupil(
        id: d['id'], firstName: d['first_name'] ?? '', lastName: d['last_name'] ?? '',
        phone: d['phone'] ?? '', email: d['email'] ?? '',
        hourlyRate: (d['hourly_rate'] as num?)?.toDouble() ?? 40,
      );
    }).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fee = _amount * 0.019;
    final takeHome = _amount - fee;

    return Scaffold(
      backgroundColor: isDark ? null : const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        title: Text(_pupil != null ? _pupil!.firstName : 'Payment Request', style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          // Pupil selector
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.4)),
            ),
            child: DropdownMenu<Pupil>(
              initialSelection: _pupil,
              width: MediaQuery.of(context).size.width - 32,
              label: const Text('Select pupil'),
              dropdownMenuEntries: pupils.map((p) => DropdownMenuEntry(value: p, label: p.fullName)).toList(),
              onSelected: (p) {
                setState(() { _pupil = p; _unpaid = []; _selIds.clear(); _amount = 0; _amountCtrl.text = ''; });
                if (p != null) _loadUnpaid(p.id);
              },
            ),
          ),
          if (_pupil == null) const SizedBox(height: 40),
          // Unpaid lessons
          if (_pupil != null && _loading)
            const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
          if (_pupil != null && !_loading && _unpaid.isEmpty)
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 22),
                  const SizedBox(width: 10),
                  Text('${_pupil!.firstName} is all paid up',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.success)),
                ],
              ),
            ),
          if (_pupil != null && !_loading && _unpaid.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Lessons', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15,
                          color: isDark ? AppColors.darkText : AppColors.lightText)),
                      const Spacer(),
                      Text('${_selIds.length} selected',
                          style: TextStyle(fontSize: 11, color: AppColors.sunsetBright, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _selIds.length == _unpaid.length
                            ? () { setState(() => _selIds.clear()); _calc(); }
                            : () { setState(() => _selIds.addAll(_unpaid.map((l) => l['id'] as String))); _calc(); },
                        child: Text(
                          _selIds.length == _unpaid.length ? 'Deselect' : 'Select All',
                          style: TextStyle(fontSize: 12, color: AppColors.sunsetBright, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  ..._unpaid.map((l) {
                    final id = l['id'] as String;
                    final d = DateTime.parse(l['date']);
                    final r = (l['rate'] as num?)?.toDouble() ?? 0;
                    final sel = _selIds.contains(id);
                    final isOverdue = l['status'] == 'scheduled';
                    final statusColor = isOverdue ? AppColors.warning : AppColors.success;
                    final statusLabel = isOverdue ? 'OVERDUE' : 'UNPAID';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: InkWell(
                        onTap: () => _toggle(id),
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.sunsetBright.withValues(alpha: 0.05) : null,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(sel ? Icons.check_circle : Icons.circle_outlined,
                                  size: 20, color: sel ? AppColors.sunsetBright : (isDark ? AppColors.darkMuted : AppColors.lightMuted)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(DateFormat('MMM d, yyyy').format(d),
                                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                                  color: isDark ? AppColors.darkText : AppColors.lightText)),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(statusLabel,
                                              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800,
                                                  color: statusColor, letterSpacing: 0.3)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text('${l['time']} \u00b7 ${l['duration']}min',
                                        style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkMuted : AppColors.lightMuted)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('\u00a3${r.toStringAsFixed(0)}',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.sunsetBright)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          if (_pupil != null && !_loading && _unpaid.isNotEmpty) ...[
            const SizedBox(height: 16),
            // Amount + type
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Amount', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const Spacer(),
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: false, label: Text('Custom', style: TextStyle(fontSize: 11))),
                          ButtonSegment(value: true, label: Text('Package', style: TextStyle(fontSize: 11))),
                        ],
                        selected: {_isPackage},
                        onSelectionChanged: (s) => setState(() => _isPackage = s.first),
                        style: SegmentedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          selectedBackgroundColor: AppColors.sunsetBright.withValues(alpha: 0.1),
                          selectedForegroundColor: AppColors.sunsetBright,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_isPackage)
                    DropdownButtonFormField<int>(
                      decoration: InputDecoration(
                        labelText: 'Package',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        isDense: true,
                      ),
                      items: [2, 5, 10, 20].map((h) => DropdownMenuItem(
                        value: h,
                        child: Text('$h hrs \u00d7 \u00a3${(_pupil!.hourlyRate).toStringAsFixed(0)} = \u00a3${(h * _pupil!.hourlyRate).toStringAsFixed(0)}'),
                      )).toList(),
                      onChanged: (h) {
                        if (h != null) { _amountCtrl.text = (h * _pupil!.hourlyRate).toStringAsFixed(2); setState(() => _amount = h * _pupil!.hourlyRate); }
                      },
                    )
                  else
                    TextFormField(
                      controller: _amountCtrl,
                      decoration: InputDecoration(
                        prefixText: '\u00a3 ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        isDense: true,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => setState(() => _amount = double.tryParse(_amountCtrl.text) ?? 0),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Message
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.4)),
              ),
              child: TextFormField(
                controller: _msgCtrl,
                decoration: InputDecoration(
                  hintText: 'Note (optional)',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
                maxLines: 2,
              ),
            ),
            const SizedBox(height: 16),
            // Fee disclosure
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.sunsetBright.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.sunsetBright.withValues(alpha: 0.12)),
              ),
              child: Column(
                children: [
                  _feeRow('Requested', '\u00a3${_amount.toStringAsFixed(2)}', isDark ? AppColors.darkText : AppColors.lightText),
                  const SizedBox(height: 4),
                  _feeRow('Fee (1.9%)', '-\u00a3${fee.toStringAsFixed(2)}', AppColors.error),
                  const Divider(height: 20),
                  _feeRow('You receive', '\u00a3${takeHome.toStringAsFixed(2)}', AppColors.success),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Send
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _amount > 0 ? _send : null,
                icon: const Icon(Icons.send, size: 16),
                label: Text(_amount > 0 ? 'Send \u00a3${_amount.toStringAsFixed(0)} Request' : 'Enter an amount',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  disabledBackgroundColor: AppColors.success.withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _feeRow(String l, String v, Color c) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(l, style: TextStyle(fontSize: 13, color: c)),
        Text(v, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: c)),
      ],
    );
  }
}
