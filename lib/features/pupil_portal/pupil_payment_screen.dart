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
  Map<String, dynamic>? _instructor;
  Map<String, dynamic> _payMethods = {};
  String? _instructorId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    if (user == null) return;
    setState(() => _isLoading = true);
    try {
      final link = await Supabase.instance.client
          .from('instructor_pupil_links')
          .select('instructor_id')
          .eq('pupil_id', user!.id)
          .eq('status', 'active')
          .maybeSingle();

      _instructorId = link?['instructor_id'] as String?;

      // Fetch instructor profile
      _instructor = _instructorId != null
          ? await Supabase.instance.client
              .from('profiles')
              .select('full_name, business_name, phone, email')
              .eq('id', _instructorId!)
              .maybeSingle()
          : null;

      // Fetch instructor payment methods
      if (_instructorId != null) {
        final payInfo = await Supabase.instance.client
            .from('instructor_payment_info')
            .select('methods')
            .eq('instructor_id', _instructorId!)
            .maybeSingle();
        _payMethods = (payInfo?['methods'] as Map?)?.cast<String, dynamic>() ?? {};
      }

      // Fetch data in parallel
      final results = await Future.wait([
        Supabase.instance.client
            .from('instructor_payment_requests')
            .select('*')
            .eq('pupil_id', user!.id)
            .order('created_at', ascending: false),
        Supabase.instance.client
            .from('invoices')
            .select('*')
            .eq('pupil_id', user!.id)
            .order('created_at', ascending: false),
        Supabase.instance.client
            .from('transactions')
            .select('*')
            .eq('pupil_id', user!.id)
            .order('created_at', ascending: false),
      ]);

      if (mounted) {
        setState(() {
          _requests = List<Map<String, dynamic>>.from(results[0]);
          _invoices = List<Map<String, dynamic>>.from(results[1]);
          _payments = List<Map<String, dynamic>>.from(results[2]);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _totalPending => _invoices
      .where((i) => i['status'] == 'pending')
      .fold<double>(0, (s, i) => s + ((i['amount'] as num?)?.toDouble() ?? 0));

  double get _totalPaid => _payments
      .fold<double>(0, (s, p) => s + ((p['amount'] as num?)?.toDouble() ?? 0));

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
      _loadAll();
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

  void _showPaymentSheet(Map<String, dynamic>? invoice) {
    final amount = invoice != null ? (invoice['amount'] as num).toDouble() : 0.0;
    final dollarFormat = '\u00a3${amount.toStringAsFixed(2)}';
    final phone = _instructor?['phone'] as String? ?? '';

    // Get enabled payment methods from instructor data
    final activeMethods = <MapEntry<String, Map<String, dynamic>>>[];
    for (final entry in _payMethods.entries) {
      final m = entry.value;
      if (m is Map && m['enabled'] == true) {
        activeMethods.add(MapEntry(entry.key, Map<String, dynamic>.from(m)));
      }
    }

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
              // Amount header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.sunsetBright, Color(0xFFE85D3A)]),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Text(dollarFormat, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(invoice?['description']?.toString() ?? 'Payment', style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8))),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('How to Pay', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 4),
              Text('Tap any detail to copy it', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 16),
              if (activeMethods.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, color: Colors.grey.shade400, size: 32),
                      const SizedBox(height: 12),
                      Text('Your instructor hasn\'t set up payment methods yet.', style: TextStyle(fontSize: 14, color: Colors.grey.shade600), textAlign: TextAlign.center),
                      if (phone.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () async { final u = Uri.parse('tel:$phone'); if (await canLaunchUrl(u)) await launchUrl(u); },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(color: AppColors.sunsetBright, borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.phone_rounded, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text('Call $phone', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                )
              else
                ...activeMethods.map((entry) => _PayMethodTile(
                  methodKey: entry.key,
                  methodData: entry.value,
                  phone: phone,
                )),
              if (invoice != null && activeMethods.isNotEmpty) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () { Navigator.pop(ctx); _payInvoice(invoice); },
                    style: FilledButton.styleFrom(backgroundColor: AppColors.sunsetBright, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: Text('I\'ve Paid $dollarFormat', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF6F4F0),
      appBar: AppBar(
        title: const Text('Payments', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: AppColors.sunsetBright,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [Tab(text: 'Requests'), Tab(text: 'Invoices'), Tab(text: 'History')],
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
                    children: [_buildRequestsTab(), _buildInvoicesTab(), _buildHistoryTab()],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInstructorPayCard() {
    if (_instructor == null) return const SizedBox.shrink();

    final name = _instructor!['full_name'] as String? ?? 'Your Instructor';
    final business = _instructor!['business_name'] as String?;
    final phone = _instructor!['phone'] as String?;

    final enabledCount = _payMethods.values.where((m) => m is Map && m['enabled'] == true).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.sunsetBright, Color(0xFFE85D3A)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.sunsetBright.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    Text(business ?? name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(enabledCount > 0 ? '$enabledCount payment ${enabledCount == 1 ? 'method' : 'methods'} available' : 'Tap to set up payment', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.8))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.payment_rounded, color: Colors.white, size: 24),
              ),
            ],
          ),
          if (phone != null && phone.isNotEmpty) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () async { final u = Uri.parse('tel:$phone'); if (await canLaunchUrl(u)) await launchUrl(u); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.phone_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(phone, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 0.5)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
              Text(amount, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsTab() {
    if (_requests.isEmpty) {
      return _emptyState(Icons.request_page_rounded, 'No payment requests', 'Your instructor will send requests here');
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
      children: _invoices.map((inv) => _InvoiceCard(invoice: inv, onPay: inv['status'] == 'pending' ? () => _showPaymentSheet(inv) : null)).toList(),
    );
  }

  Widget _buildHistoryTab() {
    if (_payments.isEmpty) {
      return _emptyState(Icons.history_rounded, 'No payment history', 'Your payments will appear here');
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: _payments.map((p) => _PaymentRecordCard(payment: p)).toList(),
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

// ─── Payment Method Tile ──────────────────────────────────────
class _PayMethodTile extends StatelessWidget {
  const _PayMethodTile({required this.methodKey, required this.methodData, required this.phone});
  final String methodKey;
  final Map<String, dynamic> methodData;
  final String phone;

  static const _labels = {
    'bank_transfer': ('Bank Transfer', Icons.account_balance_rounded, Color(0xFF3B82F6)),
    'paypal': ('PayPal', Icons.account_balance_wallet_rounded, Color(0xFF0070BA)),
    'revolut': ('Revolut', Icons.credit_card_rounded, Color(0xFF0075EB)),
    'monzo': ('Monzo', Icons.phone_android_rounded, Color(0xFFFFA500)),
    'starling': ('Starling Bank', Icons.savings_rounded, Color(0xFF6938D9)),
  };

  @override
  Widget build(BuildContext context) {
    final info = _labels[methodKey] ?? ('Payment', Icons.payment_rounded, Colors.grey);
    final label = info.$1;
    final icon = info.$2;
    final color = info.$3;

    final detailItems = <_DetailPair>[];
    final accountName = methodData['account_name'] as String?;
    final accountNumber = methodData['account_number'] as String?;
    final sortCode = methodData['sort_code'] as String?;
    final bankName = methodData['bank_name'] as String?;

    if (accountName != null && accountName.isNotEmpty) detailItems.add(_DetailPair('Account Name', accountName));
    if (bankName != null && bankName.isNotEmpty) detailItems.add(_DetailPair('Bank', bankName));
    if (sortCode != null && sortCode.isNotEmpty) detailItems.add(_DetailPair('Sort Code', sortCode));
    if (accountNumber != null && accountNumber.isNotEmpty) detailItems.add(_DetailPair('Account No', accountNumber));

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: const Border(),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        subtitle: Text(detailItems.isEmpty ? 'No details set' : 'Tap to view & copy ${detailItems.length} details', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        children: [
          if (detailItems.isEmpty)
            Text('No bank details configured. Contact your instructor.', style: TextStyle(fontSize: 13, color: Colors.grey.shade500))
          else
            ...detailItems.map((d) => _CopyableRow(label: d.label, value: d.value)),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () async { final u = Uri.parse('tel:$phone'); if (await canLaunchUrl(u)) await launchUrl(u); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: AppColors.sunsetBright.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.phone_rounded, size: 16, color: AppColors.sunsetBright),
                    const SizedBox(width: 8),
                    Text('Call $phone', style: TextStyle(color: AppColors.sunsetBright, fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailPair {
  final String label;
  final String value;
  _DetailPair(this.label, this.value);
}

class _CopyableRow extends StatelessWidget {
  const _CopyableRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600))),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label copied'), duration: const Duration(seconds: 1)));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isDark ? AppColors.darkBorder : Colors.grey.shade300, width: 0.5),
                ),
                child: Row(
                  children: [
                    Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 0.5))),
                    const SizedBox(width: 8),
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

// ─── Cards ────────────────────────────────────────────────────
class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});
  final Map<String, dynamic> request;

  Color _statusColor(String? s) => switch (s) {
    'pending' => AppColors.warning,
    'paid' => AppColors.success,
    'approved' => AppColors.info,
    'rejected' => AppColors.error,
    _ => Colors.grey,
  };

  @override
  Widget build(BuildContext context) {
    final status = request['status'] as String? ?? 'pending';
    final color = _statusColor(status);
    final date = DateTime.tryParse(request['created_at'] ?? '');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
        border: status == 'pending' ? Border.all(color: AppColors.warning.withValues(alpha: 0.3)) : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(status == 'paid' ? Icons.check_circle_rounded : status == 'rejected' ? Icons.cancel_rounded : Icons.pending_rounded, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('\u00a3${(request['amount'] as num).toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                if (request['description'] != null && request['description'].toString().isNotEmpty)
                  Padding(padding: const EdgeInsets.only(top: 2), child: Text(request['description'].toString(), style: TextStyle(fontSize: 13, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                if (date != null)
                  Padding(padding: const EdgeInsets.only(top: 4), child: Text(DateFormat('d MMM yyyy').format(date), style: TextStyle(fontSize: 11, color: Colors.grey.shade500))),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dueDate = invoice['due_date'] != null ? DateTime.tryParse(invoice['due_date'].toString()) : null;

    final statusColor = switch (status) {
      'paid' => AppColors.success,
      'overdue' => AppColors.error,
      'cancelled' => Colors.grey,
      _ => AppColors.warning,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
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
                Text('\u00a3${(invoice['amount'] as num).toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
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
                    decoration: BoxDecoration(color: AppColors.sunsetBright, borderRadius: BorderRadius.circular(10)),
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

class _PaymentRecordCard extends StatelessWidget {
  const _PaymentRecordCard({required this.payment});
  final Map<String, dynamic> payment;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final date = DateTime.tryParse(payment['created_at'] ?? payment['date'] ?? '');
    final amount = (payment['amount'] as num?)?.toDouble() ?? 0;
    final desc = payment['description'] as String? ?? 'Payment';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5),
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
                if (date != null) Text(DateFormat('d MMM yyyy').format(date), style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Text('-\u00a3${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.success)),
        ],
      ),
    );
  }
}