import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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
            .select('full_name, business_name, phone, email, payment_info')
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

  void _showPaymentMethodSheet(Map<String, dynamic>? invoice) {
    final amount = invoice != null ? (invoice['amount'] as num).toDouble() : 0.0;
    final desc = invoice?['description']?.toString() ?? 'Payment';
    final payInfo = _instructorInfo?['payment_info'] as Map<String, dynamic>? ?? {};
    final phone = _instructorInfo?['phone'] as String? ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.all(24),
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.sunsetBright, Color(0xFFE85D3A)]), borderRadius: BorderRadius.all(Radius.circular(14))),
                    child: const Icon(Icons.payment_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Make a Payment', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                        const SizedBox(height: 4),
                        Text('Choose how to pay your instructor', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: AppColors.sunsetBright.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.sunsetBright.withValues(alpha: 0.15))),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(desc, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text('Amount due', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    Text('\u00a3${amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.sunsetBright)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Payment Methods', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 14),
              _buildBankTransferTile(payInfo),
              const SizedBox(height: 10),
              _buildCashTile(),
              const SizedBox(height: 10),
              _buildMobilePaymentTile(phone),
              if (invoice != null) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () { Navigator.pop(ctx); _payInvoice(invoice); },
                    icon: const Icon(Icons.check_rounded, size: 20),
                    label: Text('Confirm Payment (\u00a3${amount.toStringAsFixed(2)})'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.sunsetBright, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  ),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBankTransferTile(Map<String, dynamic> payInfo) {
    final bank = payInfo['bank_name'] as String?;
    final account = payInfo['account_number'] as String?;
    final sortCode = payInfo['sort_code'] as String?;
    final name = payInfo['account_name'] as String?;
    final hasDetails = bank != null || account != null || sortCode != null || name != null;

    final items = <_CopyItem>[];
    if (name != null) items.add(_CopyItem('Account Name', name));
    if (bank != null) items.add(_CopyItem('Bank', bank));
    if (sortCode != null) items.add(_CopyItem('Sort Code', sortCode));
    if (account != null) items.add(_CopyItem('Account Number', account));

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.1)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFF3B82F6).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.account_balance_rounded, color: Color(0xFF3B82F6), size: 22),
        ),
        title: const Text('Bank Transfer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        subtitle: Text(hasDetails ? 'Tap to view & copy bank details' : 'Contact instructor for details', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        children: hasDetails
            ? items.map((item) => _CopyableRow(label: item.label, value: item.value)).toList()
            : [
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('Contact your instructor for their bank transfer details.', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                ),
              ],
      ),
    );
  }

  Widget _buildCashTile() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.money_rounded, color: Color(0xFF10B981), size: 22),
        ),
        title: const Text('Cash', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        subtitle: Text('Pay the exact amount in cash during your next driving lesson.', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ),
    );
  }

  Widget _buildMobilePaymentTile(String phone) {
    final canCall = phone.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.1)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.phone_android_rounded, color: Color(0xFF8B5CF6), size: 22),
        ),
        title: const Text('Mobile Payment', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        subtitle: Text(canCall ? 'Pay via Monzo, Starling, Revolut & more' : 'Contact instructor', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Use your mobile banking app to transfer to your instructor.', style: TextStyle(fontSize: 13)),
                if (canCall) ...[
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async { final u = Uri.parse('tel:$phone'); if (await canLaunchUrl(u)) await launchUrl(u); },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(color: AppColors.sunsetBright, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.phone_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Text('Call $phone', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
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
            const Tab(text: 'Requests'),
            const Tab(text: 'Invoices'),
            const Tab(text: 'History'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.sunsetBright))
          : Column(
              children: [
                _buildInstructorPayCard(),
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

  Widget _buildInstructorPayCard() {
    if (_instructorInfo == null) return const SizedBox.shrink();

    final name = _instructorInfo!['full_name'] as String? ?? 'Your Instructor';
    final business = _instructorInfo!['business_name'] as String?;
    final phone = _instructorInfo!['phone'] as String?;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.sunsetBright, Color(0xFFE85D3A)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppColors.sunsetBright.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pay ${business ?? name}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white)),
                const SizedBox(height: 2),
                Text(phone ?? 'Driving Instructor', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
              ],
            ),
          ),
          Icon(Icons.credit_card_rounded, color: Colors.white.withValues(alpha: 0.8), size: 28),
        ],
      ),
    );
  }

  Widget _buildSummaryBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
          Icon(icon, color: color, size: 20),
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
    if (_requests.isEmpty) {
      return _emptyState(Icons.request_page_rounded, 'No payment requests', 'Your instructor will send payment requests here');
    }

    final pending = _requests.where((r) => r['status'] == 'pending').toList();
    final history = _requests.where((r) => r['status'] != 'pending').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (pending.isNotEmpty) ...[
          _sectionHeader('Pending'),
          ...pending.map((r) => _RequestCard(request: r)),
          if (history.isNotEmpty) const SizedBox(height: 20),
        ],
        if (history.isNotEmpty) ...[
          _sectionHeader('History'),
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
        onPay: inv['status'] == 'pending' ? () => _showPaymentMethodSheet(inv) : null,
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

  Widget _sectionHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.grey.shade700)),
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
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});
  final Map<String, dynamic> request;

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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
        border: status == 'pending'
            ? Border.all(color: AppColors.warning.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(
              status == 'paid' ? Icons.check_circle_rounded
                  : status == 'rejected' ? Icons.cancel_rounded
                  : Icons.pending_rounded,
              color: color, size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('\u00a3${(request['amount'] as num).toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                if (request['description'] != null && request['description'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(request['description'].toString(), style: TextStyle(fontSize: 13, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                if (date != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(DateFormat('d MMM yyyy').format(date), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  ),
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
        color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        onTap: onPay,
        borderRadius: BorderRadius.circular(14),
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
            const SizedBox(height: 12),
            Row(
              children: [
                if (dueDate != null) ...[
                  Icon(Icons.event_rounded, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text('Due: ${DateFormat('d MMM yyyy').format(dueDate)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  const Spacer(),
                ],
                if (onPay != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.sunsetBright,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('Pay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
              ],
            ),
          ],
        ),
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

class _CopyItem {
  final String label;
  final String value;
  _CopyItem(this.label, this.value);
}

class _CopyableRow extends StatelessWidget {
  const _CopyableRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 3,
            child: InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$label copied'), duration: const Duration(seconds: 1)),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.5)),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.copy_rounded, size: 14, color: Colors.grey.shade500),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
