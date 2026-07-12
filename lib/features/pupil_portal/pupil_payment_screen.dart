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

  static const _methodMeta = {
    'bank_transfer': ('Bank Transfer', Icons.account_balance_rounded, Color(0xFF3B82F6)),
    'paypal': ('PayPal', Icons.account_balance_wallet_rounded, Color(0xFF0070BA)),
    'revolut': ('Revolut', Icons.currency_exchange_rounded, Color(0xFF0075EB)),
    'monzo': ('Monzo', Icons.credit_card_rounded, Color(0xFFFFA500)),
    'starling': ('Starling Bank', Icons.savings_rounded, Color(0xFF6938D9)),
  };

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

  // ─── DATA LOADING (each query independent) ──────────────────
  Future<void> _loadAll() async {
    if (user == null) return;
    setState(() => _isLoading = true);

    // 1. Link
    try {
      final link = await Supabase.instance.client
          .from('instructor_pupil_links')
          .select('instructor_id')
          .eq('pupil_id', user!.id)
          .eq('status', 'active')
          .maybeSingle();
      _instructorId = link?['instructor_id'] as String?;
    } catch (_) { _instructorId = null; }

    // 2. Instructor profile + payment_info JSONB
    _payMethods = {};
    if (_instructorId != null) {
      try {
        _instructor = await Supabase.instance.client
            .from('profiles')
            .select('full_name, business_name, phone, email, payment_info')
            .eq('id', _instructorId!)
            .maybeSingle();
      } catch (_) { _instructor = null; }

      // Source 1: profiles.payment_info JSONB
      if (_instructor != null) {
        final pi = (_instructor!['payment_info'] as Map?)?.cast<String, dynamic>() ?? {};
        if (pi['account_number'] != null && (pi['account_number'] as String).isNotEmpty) {
          _payMethods['bank_transfer'] = {
            'enabled': true,
            'holder_name': pi['account_name'] ?? _instructor!['full_name'] ?? '',
            'bank_name': pi['bank_name'] ?? '',
            'sort_code': pi['sort_code'] ?? '',
            'account_number': pi['account_number'] ?? '',
          };
        }
      }

      // Source 2: instructor_payment_info table (merge over profile data)
      try {
        final payInfo = await Supabase.instance.client
            .from('instructor_payment_info')
            .select('methods')
            .eq('instructor_id', _instructorId!)
            .maybeSingle();
        if (payInfo?['methods'] != null) {
          final tm = (payInfo!['methods'] as Map).cast<String, dynamic>();
          _payMethods.addAll(tm);
        }
      } catch (_) {/* table might not exist */}
    }

    // 3. Requests
    try {
      final r = await Supabase.instance.client
          .from('instructor_payment_requests')
          .select('*')
          .eq('pupil_id', user!.id)
          .order('created_at', ascending: false);
      _requests = List<Map<String, dynamic>>.from(r);
    } catch (_) { _requests = []; }

    // 4. Invoices
    try {
      final r = await Supabase.instance.client
          .from('invoices')
          .select('*')
          .eq('pupil_id', user!.id)
          .order('created_at', ascending: false);
      _invoices = List<Map<String, dynamic>>.from(r);
    } catch (_) { _invoices = []; }

    // 5. Transactions
    try {
      final r = await Supabase.instance.client
          .from('transactions')
          .select('*')
          .eq('pupil_id', user!.id)
          .order('created_at', ascending: false);
      _payments = List<Map<String, dynamic>>.from(r);
    } catch (_) { _payments = []; }

    if (mounted) setState(() => _isLoading = false);
  }

  // List of enabled methods
  List<MapEntry<String, Map<String, dynamic>>> get _enabledMethods {
    final list = <MapEntry<String, Map<String, dynamic>>>[];
    for (final entry in _payMethods.entries) {
      final m = entry.value;
      if (m is Map && m['enabled'] == true) {
        list.add(MapEntry(entry.key, Map<String, dynamic>.from(m)));
      }
    }
    return list;
  }

  // Extract copyable fields for a method
  List<_DetailPair> _fieldsForMethod(String key, Map<String, dynamic> m) {
    final fields = <_DetailPair>[];
    switch (key) {
      case 'bank_transfer':
        if ((m['holder_name'] ?? '').toString().isNotEmpty) fields.add(_DetailPair('Account Holder', m['holder_name'].toString()));
        if ((m['bank_name'] ?? '').toString().isNotEmpty) fields.add(_DetailPair('Bank', m['bank_name'].toString()));
        if ((m['sort_code'] ?? '').toString().isNotEmpty) fields.add(_DetailPair('Sort Code', m['sort_code'].toString()));
        if ((m['account_number'] ?? '').toString().isNotEmpty) fields.add(_DetailPair('Account No', m['account_number'].toString()));
        if ((m['reference'] ?? '').toString().isNotEmpty) fields.add(_DetailPair('Reference', m['reference'].toString()));
      case 'paypal':
        if ((m['email'] ?? '').toString().isNotEmpty) fields.add(_DetailPair('PayPal Email', m['email'].toString()));
      case 'revolut':
        if ((m['revtag'] ?? '').toString().isNotEmpty) fields.add(_DetailPair('Revtag', m['revtag'].toString()));
        if ((m['phone'] ?? '').toString().isNotEmpty) fields.add(_DetailPair('Phone', m['phone'].toString()));
        if ((m['sort_code'] ?? '').toString().isNotEmpty) fields.add(_DetailPair('Sort Code', m['sort_code'].toString()));
        if ((m['account_number'] ?? '').toString().isNotEmpty) fields.add(_DetailPair('Account No', m['account_number'].toString()));
      case 'monzo':
        if ((m['sort_code'] ?? '').toString().isNotEmpty) fields.add(_DetailPair('Sort Code', m['sort_code'].toString()));
        if ((m['account_number'] ?? '').toString().isNotEmpty) fields.add(_DetailPair('Account No', m['account_number'].toString()));
        if ((m['payment_link'] ?? '').toString().isNotEmpty) fields.add(_DetailPair('Payment Link', m['payment_link'].toString()));
      case 'starling':
        if ((m['sort_code'] ?? '').toString().isNotEmpty) fields.add(_DetailPair('Sort Code', m['sort_code'].toString()));
        if ((m['account_number'] ?? '').toString().isNotEmpty) fields.add(_DetailPair('Account No', m['account_number'].toString()));
    }
    return fields;
  }

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
      await Supabase.instance.client.from('invoices').update({'status': 'paid'}).eq('id', invoice['id']);
      if (!mounted) return;
      _loadAll();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment confirmed')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(userFriendlyError(e))));
    }
  }

  void _showPaySheet(Map<String, dynamic>? invoice) {
    final amount = invoice != null ? (invoice['amount'] as num).toDouble() : 0.0;
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
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.sunsetBright, Color(0xFFE85D3A)]), borderRadius: BorderRadius.all(Radius.circular(18))),
                child: Center(child: Text('\u00a3${amount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white))),
              ),
              const SizedBox(height: 24),
              if (_enabledMethods.isEmpty) ...[
                _noMethodsMessage(),
              ] else ...[
                const Text('Payment Methods', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                const SizedBox(height: 4),
                Text('Tap any detail to copy', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                const SizedBox(height: 14),
                ..._enabledMethods.map((e) {
                  final meta = _methodMeta[e.key] ?? ('Payment', Icons.payment_rounded, Colors.grey);
                  return _MethodTile(label: meta.$1, icon: meta.$2, color: meta.$3, fields: _fieldsForMethod(e.key, e.value), phone: _instructor?['phone'] as String?);
                }),
                if (invoice != null) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () { Navigator.pop(ctx); _payInvoice(invoice); },
                      style: FilledButton.styleFrom(backgroundColor: AppColors.sunsetBright, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                      child: Text('I\'ve Paid \u00a3${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _noMethodsMessage() {
    final phone = _instructor?['phone'] as String? ?? '';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Icon(Icons.payment_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text('No Payment Methods Set Up', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text('Your instructor hasn\'t shared any payment details yet. Please contact them to arrange payment.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          if (phone.isNotEmpty) ...[
            const SizedBox(height: 16),
            InkWell(
              onTap: () async { final u = Uri.parse('tel:$phone'); if (await canLaunchUrl(u)) await launchUrl(u); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(color: AppColors.sunsetBright, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [const Icon(Icons.phone_rounded, color: Colors.white, size: 18), const SizedBox(width: 8), Text('Call $phone', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── BUILD ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF6F4F0),
      appBar: AppBar(
        title: const Text('Payments'),
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
                _buildPaymentInfoSection(),
                _buildSummaryBar(),
                Expanded(child: TabBarView(controller: _tabCtrl, children: [_buildRequestsTab(), _buildInvoicesTab(), _buildHistoryTab()])),
              ],
            ),
    );
  }

  // ─── PAYMENT INFO SECTION (shows all enabled methods) ──────
  Widget _buildPaymentInfoSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = _instructor?['full_name'] as String? ?? 'Your Instructor';
    final business = _instructor?['business_name'] as String?;
    final phone = _instructor?['phone'] as String?;
    final methods = _enabledMethods;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.sunsetBright, Color(0xFFE85D3A)]),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                      Text(business ?? name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white)),
                      const SizedBox(height: 2),
                      if (methods.isNotEmpty)
                        Text('${methods.length} payment ${methods.length == 1 ? 'method' : 'methods'} available', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85)))
                      else
                        Text('No payment methods set up', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.85))),
                    ],
                  ),
                ),
                const Icon(Icons.lock_outline, color: Colors.white70, size: 20),
              ],
            ),
          ),
          // Methods
          if (methods.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.payment_outlined, size: 40, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('Your instructor hasn\'t shared payment details yet.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  Text('Contact them directly to arrange payment.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                  if (phone != null && phone.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: () async { final u = Uri.parse('tel:$phone'); if (await canLaunchUrl(u)) await launchUrl(u); },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(color: AppColors.sunsetBright, borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [const Icon(Icons.phone_rounded, color: Colors.white, size: 18), const SizedBox(width: 8), Text('Call $phone', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14))],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
              child: Row(
                children: [
                  Icon(Icons.touch_app_outlined, size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 6),
                  Text('Tap any detail to copy', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ],
              ),
            ),
            ...methods.map((e) {
              final meta = _methodMeta[e.key] ?? ('Payment', Icons.payment_rounded, Colors.grey);
              final fields = _fieldsForMethod(e.key, e.value);
              if (fields.isEmpty) return const SizedBox.shrink();
              return _MethodTile(label: meta.$1, icon: meta.$2, color: meta.$3, fields: fields, phone: phone);
            }),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }

  // ─── SUMMARY ────────────────────────────────────────────────
  Widget _buildSummaryBar() {
    final pending = _invoices.where((i) => i['status'] == 'pending').fold<double>(0, (s, i) => s + ((i['amount'] as num?)?.toDouble() ?? 0));
    final paid = _payments.fold<double>(0, (s, p) => s + ((p['amount'] as num?)?.toDouble() ?? 0));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(child: _chip('Pending', '\u00a3${pending.toStringAsFixed(2)}', AppColors.warning, Icons.pending_rounded)),
          const SizedBox(width: 12),
          Expanded(child: _chip('Paid', '\u00a3${paid.toStringAsFixed(2)}', AppColors.success, Icons.check_circle_rounded)),
        ],
      ),
    );
  }

  Widget _chip(String label, String amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.15))),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w600)), Text(amount, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color))]),
        ],
      ),
    );
  }

  // ─── TABS ───────────────────────────────────────────────────
  Widget _buildRequestsTab() {
    if (_requests.isEmpty) return _empty(Icons.request_page_rounded, 'No payment requests', 'Your instructor will send requests here');
    final pending = _requests.where((r) => r['status'] == 'pending').toList();
    final history = _requests.where((r) => r['status'] != 'pending').toList();
    return ListView(padding: const EdgeInsets.all(16), children: [
      if (pending.isNotEmpty) ...[_header('Pending'), ...pending.map((r) => _RequestCard(request: r)), if (history.isNotEmpty) const SizedBox(height: 20)],
      if (history.isNotEmpty) ...[_header('History'), ...history.map((r) => _RequestCard(request: r))],
    ]);
  }

  Widget _buildInvoicesTab() {
    if (_invoices.isEmpty) return _empty(Icons.receipt_long_rounded, 'No invoices', 'Your instructor hasn\'t sent any invoices yet');
    return ListView(padding: const EdgeInsets.all(16), children: _invoices.map((inv) => _InvoiceCard(invoice: inv, onPay: inv['status'] == 'pending' ? () => _showPaySheet(inv) : null)).toList());
  }

  Widget _buildHistoryTab() {
    if (_payments.isEmpty) return _empty(Icons.history_rounded, 'No payment history', 'Your payments will appear here');
    return ListView(padding: const EdgeInsets.all(16), children: _payments.map((p) => _PaymentCard(payment: p)).toList());
  }

  Widget _header(String t) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Text(t, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.grey.shade700)));

  Widget _empty(IconData icon, String title, String subtitle) {
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 72, color: Colors.grey.shade300), const SizedBox(height: 16), Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.grey.shade500)), const SizedBox(height: 8), Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey.shade500), textAlign: TextAlign.center)])));
  }
}

// ─── DATA TYPES ───────────────────────────────────────────────
class _DetailPair { final String label; final String value; _DetailPair(this.label, this.value); }

// ─── METHOD TILE ──────────────────────────────────────────────
class _MethodTile extends StatelessWidget {
  const _MethodTile({required this.label, required this.icon, required this.color, required this.fields, required this.phone});
  final String label;
  final IconData icon;
  final Color color;
  final List<_DetailPair> fields;
  final String? phone;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.1))),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        shape: const Border(),
        leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 22)),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        subtitle: Text('${fields.length} ${fields.length == 1 ? 'detail' : 'details'} — tap to copy', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        children: [
          ...fields.map((d) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 96, child: Text(d.label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600))),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: d.value));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${d.label} copied'), duration: const Duration(seconds: 1)));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? AppColors.darkBorder : Colors.grey.shade300, width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: Text(d.value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 0.3))),
                          const SizedBox(width: 8),
                          Icon(Icons.copy_rounded, size: 14, color: Colors.grey.shade500),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )),
          if (phone != null && phone!.isNotEmpty) ...[
            const SizedBox(height: 4),
            InkWell(
              onTap: () async { final u = Uri.parse('tel:$phone'); if (await canLaunchUrl(u)) await launchUrl(u); },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: AppColors.sunsetBright.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Icon(Icons.phone_rounded, size: 16, color: AppColors.sunsetBright), const SizedBox(width: 8), Text('Call $phone', style: TextStyle(color: AppColors.sunsetBright, fontWeight: FontWeight.w700, fontSize: 13))],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── CARDS ────────────────────────────────────────────────────
class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});
  final Map<String, dynamic> request;

  Color _c(String? s) => switch (s) { 'pending' => AppColors.warning, 'paid' => AppColors.success, 'rejected' => AppColors.error, 'approved' => AppColors.info, _ => Colors.grey };

  @override
  Widget build(BuildContext context) {
    final status = request['status'] as String? ?? 'pending';
    final color = _c(status);
    final date = DateTime.tryParse(request['created_at'] ?? '');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? AppColors.darkCard : Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))], border: status == 'pending' ? Border.all(color: AppColors.warning.withValues(alpha: 0.3)) : null),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(status == 'paid' ? Icons.check_circle_rounded : status == 'rejected' ? Icons.cancel_rounded : Icons.pending_rounded, color: color, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('\u00a3${(request['amount'] as num).toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            if (request['description'] != null && request['description'].toString().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 2), child: Text(request['description'].toString(), style: TextStyle(fontSize: 13, color: Colors.grey.shade600), maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (date != null) Padding(padding: const EdgeInsets.only(top: 4), child: Text(DateFormat('d MMM yyyy').format(date), style: TextStyle(fontSize: 11, color: Colors.grey.shade500))),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)), child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color))),
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
    final due = invoice['due_date'] != null ? DateTime.tryParse(invoice['due_date'].toString()) : null;
    final sc = switch (status) { 'paid' => AppColors.success, 'overdue' => AppColors.error, 'cancelled' => Colors.grey, _ => AppColors.warning };

    return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: isDark ? AppColors.darkCard : Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))]), child: InkWell(onTap: onPay, borderRadius: BorderRadius.circular(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('\u00a3${(invoice['amount'] as num).toStringAsFixed(2)}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), decoration: BoxDecoration(color: sc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)), child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: sc))),
      ]),
      if (invoice['description'] != null && invoice['description'].toString().isNotEmpty) ...[const SizedBox(height: 6), Text(invoice['description'].toString(), style: TextStyle(fontSize: 13, color: Colors.grey.shade600))],
      const SizedBox(height: 12),
      Row(children: [
        if (due != null) ...[Icon(Icons.event_rounded, size: 14, color: Colors.grey.shade500), const SizedBox(width: 4), Text('Due: ${DateFormat('d MMM yyyy').format(due)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)), const Spacer()],
        if (onPay != null) Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: AppColors.sunsetBright, borderRadius: BorderRadius.circular(10)), child: const Text('Pay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13))),
      ]),
    ])));
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment});
  final Map<String, dynamic> payment;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final date = DateTime.tryParse(payment['created_at'] ?? payment['date'] ?? '');
    final amount = (payment['amount'] as num?)?.toDouble() ?? 0;
    final desc = payment['description'] as String? ?? 'Payment';

    return Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: isDark ? AppColors.darkCard : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 0.5)), child: Row(children: [
      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(desc, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis), if (date != null) Text(DateFormat('d MMM yyyy').format(date), style: TextStyle(fontSize: 12, color: Colors.grey.shade500))])),
      Text('-\u00a3${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.success)),
    ]));
  }
}