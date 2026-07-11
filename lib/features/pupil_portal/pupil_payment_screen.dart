import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/error_handler.dart';

class PupilPaymentScreen extends StatefulWidget {
  const PupilPaymentScreen({super.key});

  @override
  State<PupilPaymentScreen> createState() => _PupilPaymentScreenState();
}

class _PupilPaymentScreenState extends State<PupilPaymentScreen>
    with SingleTickerProviderStateMixin {
  final user = Supabase.instance.client.auth.currentUser;
  late TabController _tabCtrl;

  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _invoices = [];
  List<Map<String, dynamic>> _payments = [];
  Map<String, dynamic>? _instructorInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (user == null) return;
    setState(() => _isLoading = true);

    try {
      final linkRes = await Supabase.instance.client
          .from('instructor_pupil_links')
          .select('instructor_id')
          .eq('pupil_id', user!.id)
          .eq('status', 'active')
          .maybeSingle();

      final instructorId = linkRes?['instructor_id'] as String?;

      Map<String, dynamic>? instructor;
      if (instructorId != null) {
        instructor = await Supabase.instance.client
            .from('profiles')
            .select('full_name, business_name, phone, email')
            .eq('id', instructorId)
            .maybeSingle();
      }

      final requestsRes = await Supabase.instance.client
          .from('instructor_payment_requests')
          .select('*')
          .eq('pupil_id', user!.id)
          .order('created_at', ascending: false);

      final invoicesRes = await Supabase.instance.client
          .from('invoices')
          .select('*')
          .eq('pupil_id', user!.id)
          .order('created_at', ascending: false);

      final paymentsRes = await Supabase.instance.client
          .from('transactions')
          .select('*')
          .eq('pupil_id', user!.id)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _instructorInfo = instructor;
          _requests = List<Map<String, dynamic>>.from(requestsRes);
          _invoices = List<Map<String, dynamic>>.from(invoicesRes);
          _payments = List<Map<String, dynamic>>.from(paymentsRes);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _totalPending =>
      _invoices.where((i) => i['status'] == 'pending').fold<double>(0, (s, i) => s + ((i['amount'] as num?)?.toDouble() ?? 0));

  double get _totalPaid =>
      _payments.fold<double>(0, (s, p) => s + ((p['amount'] as num?)?.toDouble() ?? 0));

  Future<void> _payInvoice(Map<String, dynamic> invoice) async {
    try {
      await Supabase.instance.client.from('transactions').insert({
        'instructor_id': invoice['instructor_id'],
        'pupil_id': user!.id,
        'pupil_name': invoice['pupil_name'] ?? '',
        'amount': invoice['amount'],
        'description': invoice['description'] ?? 'Invoice payment',
        'date': DateTime.now().toIso8601String().split('T')[0],
        'type': 'income',
        'payment_method': 'bank_transfer',
      });

      await Supabase.instance.client
          .from('invoices')
          .update({'status': 'paid'})
          .eq('id', invoice['id']);

      if (!mounted) return;
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment recorded successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyError(e))),
      );
    }
  }

  Future<void> _markRequestPaid(Map<String, dynamic> request) async {
    try {
      await Supabase.instance.client.from('transactions').insert({
        'instructor_id': request['instructor_id'],
        'pupil_id': user!.id,
        'pupil_name': _instructorInfo?['full_name'] ?? '',
        'amount': request['amount'],
        'description': request['description'] ?? 'Payment request',
        'date': DateTime.now().toIso8601String().split('T')[0],
        'type': 'income',
        'payment_method': 'bank_transfer',
      });

      await Supabase.instance.client
          .from('instructor_payment_requests')
          .update({'status': 'paid'})
          .eq('id', request['id']);

      if (!mounted) return;
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment confirmed')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userFriendlyError(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        backgroundColor: AppColors.sunsetBright,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: [
            Tab(text: 'Requests (${_requests.where((r) => r['status'] == 'pending').length})'),
            const Tab(text: 'Invoices'),
            const Tab(text: 'History'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.sunsetBright))
          : Column(
              children: [
                _buildSummaryBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabCtrl,
                    children: [
                      _buildRequestsTab(),
                      _buildInvoicesTab(),
                      _buildHistoryTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : Colors.white,
      child: Row(
        children: [
          Expanded(child: _summaryChip('Pending', '\u00a3${_totalPending.toStringAsFixed(2)}', AppColors.warning, Icons.pending_rounded)),
          const SizedBox(width: 12),
          Expanded(child: _summaryChip('Paid', '\u00a3${_totalPaid.toStringAsFixed(2)}', AppColors.success, Icons.check_circle_rounded)),
        ],
      ),
    );
  }

  Widget _summaryChip(String label, String amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
              Text(amount, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsTab() {
    final pending = _requests.where((r) => r['status'] == 'pending').toList();
    final history = _requests.where((r) => r['status'] != 'pending').toList();

    if (_requests.isEmpty) {
      return _emptyState(Icons.request_page_rounded, 'No payment requests', 'Your instructor will send requests here');
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (pending.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('Pending Requests', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.grey.shade700)),
          ),
          ...pending.map((r) => _RequestCard(
            request: r,
            onPay: () => _showPayDialog(r, _markRequestPaid),
          )),
          if (history.isNotEmpty) const SizedBox(height: 24),
        ],
        if (history.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('History', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.grey.shade700)),
          ),
          ...history.map((r) => _RequestCard(request: r)),
        ],
      ],
    );
  }

  Widget _buildInvoicesTab() {
    if (_invoices.isEmpty) {
      return _emptyState(Icons.receipt_long_rounded, 'No invoices', 'Your instructor hasn\'t sent any invoices yet');
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: _invoices.map((inv) => _InvoiceCard(
        invoice: inv,
        onPay: inv['status'] == 'pending' ? () => _showPayDialog(inv, _payInvoice) : null,
      )).toList(),
    );
  }

  Widget _buildHistoryTab() {
    if (_payments.isEmpty) {
      return _emptyState(Icons.history_rounded, 'No payment history', 'Your payments will appear here');
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: _payments.map((p) => _PaymentCard(payment: p)).toList(),
    );
  }

  Widget _emptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.grey.shade500)),
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade500), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  void _showPayDialog(Map<String, dynamic> item, Function(Map<String, dynamic>) onPay) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.sunsetBright.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.payment_rounded, color: AppColors.sunsetBright, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Confirm Payment', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('\u00a3${(item['amount'] as num).toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.sunsetBright)),
            const SizedBox(height: 8),
            if (item['description'] != null && item['description'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(item['description'].toString(), style: TextStyle(fontSize: 14, color: Colors.grey.shade600), textAlign: TextAlign.center),
              ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.amber, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('This records the payment. Transfer the amount to your instructor using their bank details.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onPay(item);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.sunsetBright),
            child: const Text('Confirm Paid'),
          ),
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, this.onPay});
  final Map<String, dynamic> request;
  final VoidCallback? onPay;

  Color _statusColor(String? status) {
    switch (status) {
      case 'pending': return AppColors.warning;
      case 'approved': return AppColors.info;
      case 'paid': return AppColors.success;
      case 'rejected': return AppColors.error;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = request['status'] as String? ?? 'pending';
    final color = _statusColor(status);
    final date = DateTime.tryParse(request['created_at'] ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
        border: status == 'pending'
            ? Border.all(color: AppColors.sunsetBright.withValues(alpha: 0.3), width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(
                  status == 'paid' ? Icons.check_circle_rounded
                      : status == 'rejected' ? Icons.cancel_rounded
                      : Icons.pending_rounded,
                  color: color, size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('\u00a3${(request['amount'] as num).toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    if (request['description'] != null && request['description'].toString().isNotEmpty)
                      Text(request['description'].toString(), style: TextStyle(fontSize: 13, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
              ),
            ],
          ),
          if (date != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 12, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(DateFormat('d MMM yyyy').format(date), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ],
          if (onPay != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onPay,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Mark as Paid'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({required this.invoice, this.onPay});
  final Map<String, dynamic> invoice;
  final VoidCallback? onPay;

  @override
  Widget build(BuildContext context) {
    final status = invoice['status'] as String? ?? 'pending';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dueDate = invoice['due_date'] != null ? DateTime.tryParse(invoice['due_date'].toString()) : null;

    Color statusColor;
    switch (status) {
      case 'paid': statusColor = AppColors.success; break;
      case 'overdue': statusColor = AppColors.error; break;
      case 'cancelled': statusColor = Colors.grey; break;
      default: statusColor = AppColors.warning;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('\u00a3${(invoice['amount'] as num).toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor)),
              ),
            ],
          ),
          if (invoice['description'] != null && invoice['description'].toString().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(invoice['description'].toString(), style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              if (dueDate != null) ...[
                Icon(Icons.event_rounded, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text('Due: ${DateFormat('d MMM yyyy').format(dueDate)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                const Spacer(),
              ],
              if (onPay != null)
                FilledButton(
                  onPressed: onPay,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.sunsetBright,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Pay Now', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment});
  final Map<String, dynamic> payment;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(payment['created_at'] ?? payment['date'] ?? '');
    final amount = (payment['amount'] as num?)?.toDouble() ?? 0;
    final desc = payment['description'] as String? ?? 'Payment';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(desc, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                if (date != null)
                  Text(DateFormat('d MMM yyyy').format(date), style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Text('-\u00a3${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.success)),
        ],
      ),
    );
  }
}
