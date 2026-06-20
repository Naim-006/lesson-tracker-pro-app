import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';

class PupilInvitationLinkScreen extends ConsumerStatefulWidget {
  const PupilInvitationLinkScreen({super.key});

  @override
  ConsumerState<PupilInvitationLinkScreen> createState() => _PupilInvitationLinkScreenState();
}

class _PupilInvitationLinkScreenState extends ConsumerState<PupilInvitationLinkScreen> {
  String? _linkToken;
  bool _isLoading = true;
  bool _isCreating = false;
  List<Map<String, dynamic>> _submissions = [];
  int _pendingCount = 0;
  int _approvedCount = 0;
  int _rejectedCount = 0;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadLink();
  }

  Future<void> _loadLink() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final linkResult = await Supabase.instance.client
          .from('pupil_invite_links')
          .select('id, token, is_active')
          .eq('instructor_id', user.id)
          .eq('is_active', true)
          .maybeSingle();

      if (linkResult == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final subsResult = await Supabase.instance.client
          .from('pupil_invite_submissions')
          .select('*')
          .eq('link_id', linkResult['id'])
          .order('created_at', ascending: false);

      final subsList = subsResult as List?;

      if (mounted) {
        setState(() {
          _linkToken = linkResult['token'];
          _submissions = List<Map<String, dynamic>>.from(subsList ?? []);
          _pendingCount = _submissions.where((s) => s['status'] == 'pending').length;
          _approvedCount = _submissions.where((s) => s['status'] == 'approved').length;
          _rejectedCount = _submissions.where((s) => s['status'] == 'rejected').length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createLink() async {
    setState(() => _isCreating = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789';
      final token = List.generate(12, (_) => chars[(chars.length * (DateTime.now().millisecond % 1000) / 1000).floor() % chars.length]).join();

      await Supabase.instance.client.from('pupil_invite_links').insert({
        'instructor_id': user.id,
        'token': token,
      });

      setState(() => _isCreating = false);
      await _loadLink();
    } catch (e) {
      if (mounted) {
        setState(() => _isCreating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _reviewSubmission(String id, String action, {String? notes}) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client
          .from('pupil_invite_submissions')
          .update({
            'status': action == 'approve' ? 'approved' : 'rejected',
            'reviewed_at': DateTime.now().toIso8601String(),
            'review_notes': notes,
          })
          .eq('id', id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(action == 'approve' ? 'Approved! Pupil will be created.' : 'Rejected.'),
            backgroundColor: action == 'approve' ? AppColors.success : AppColors.error,
          ),
        );
        _loadLink();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  String _getInviteUrl() => 'https://lessontracker.pro/i/$_linkToken';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF8F6F2),
      appBar: AppBar(
        title: const Text('Pupil Registration'),
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_linkToken != null)
            IconButton(
              icon: const Icon(Icons.open_in_browser),
              onPressed: () => _showWebDashboard(),
              tooltip: 'Open Web Dashboard',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _linkToken == null
              ? _buildCreateLinkView(isDark)
              : _buildLinkView(isDark),
    );
  }

  Widget _buildCreateLinkView(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.sunsetBright.withValues(alpha: 0.1), AppColors.sunset.withValues(alpha: 0.05)],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.link, color: AppColors.sunsetBright, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              'Create Your Invite Link',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Generate a unique link that pupils can use to register.\nYou review and approve each registration.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isCreating ? null : _createLink,
                icon: _isCreating
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.add_link),
                label: Text(_isCreating ? 'Creating...' : 'Generate Invite Link'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.sunsetBright,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkView(bool isDark) {
    final filtered = _submissions.where((s) => _filter == 'all' || s['status'] == _filter).toList();

    return RefreshIndicator(
      onRefresh: _loadLink,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLinkCard(isDark),
            const SizedBox(height: 16),
            _buildStatsRow(isDark),
            const SizedBox(height: 16),
            _buildFilterTabs(isDark),
            const SizedBox(height: 12),
            if (filtered.isEmpty)
              _buildEmptyState(isDark)
            else
              ...filtered.map((sub) => _buildSubmissionCard(sub, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.sunsetBright.withValues(alpha: 0.08), AppColors.sunset.withValues(alpha: 0.03)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.sunsetBright.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.link, color: AppColors.sunsetBright, size: 20),
              const SizedBox(width: 8),
              Text(
                'Your Invite Link',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: isDark ? Colors.white : Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _getInviteUrl(),
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _getInviteUrl()));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link copied!')),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share, size: 18),
                  onPressed: () {
                    Share.share('Join my driving school! Register here: ${_getInviteUrl()}');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Share this link with potential pupils. They fill in the form, you approve.',
            style: TextStyle(fontSize: 12, color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isDark) {
    return Row(
      children: [
        _buildStat('Total', _submissions.length, Colors.grey, isDark),
        const SizedBox(width: 8),
        _buildStat('Pending', _pendingCount, AppColors.warning, isDark),
        const SizedBox(width: 8),
        _buildStat('Approved', _approvedCount, AppColors.success, isDark),
        const SizedBox(width: 8),
        _buildStat('Rejected', _rejectedCount, AppColors.error, isDark),
      ],
    );
  }

  Widget _buildStat(String label, int count, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _filterTab('all', 'All'),
          _filterTab('pending', 'Pending', badge: _pendingCount),
          _filterTab('approved', 'Approved'),
          _filterTab('rejected', 'Rejected'),
        ],
      ),
    );
  }

  Widget _filterTab(String value, String label, {int? badge}) {
    final isActive = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _filter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isActive ? AppColors.sunsetBright : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isActive ? AppColors.sunsetBright : AppColors.lightBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : Colors.grey.shade600,
                ),
              ),
              if (badge != null && badge > 0) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white.withValues(alpha: 0.3) : AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                  child: Text('$badge', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: isActive ? Colors.white : Colors.white)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.people_outline, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              _filter == 'all' ? 'No registrations yet' : 'No $_filter registrations',
              style: TextStyle(color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmissionCard(Map<String, dynamic> sub, bool isDark) {
    final status = sub['status'] ?? 'pending';
    final name = '${sub['first_name'] ?? ''} ${sub['last_name'] ?? ''}'.trim();
    final email = sub['email'] ?? '';

    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'approved':
        statusColor = AppColors.success;
        statusLabel = 'Approved';
        break;
      case 'rejected':
        statusColor = AppColors.error;
        statusLabel = 'Rejected';
        break;
      default:
        statusColor = AppColors.warning;
        statusLabel = 'Pending';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.sunsetBright.withValues(alpha: 0.1),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(color: AppColors.sunsetBright, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
                    Text(email, style: TextStyle(fontSize: 12, color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey.shade500)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
              ),
            ],
          ),
          if (sub['experience_level'] != null || sub['preferred_days'] != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (sub['experience_level'] != null)
                  _infoChip('${sub['experience_level']}'.replaceAll('_', ' '), isDark),
                if (sub['preferred_days'] != null && (sub['preferred_days'] as List).isNotEmpty)
                  _infoChip((sub['preferred_days'] as List).join(', '), isDark),
              ],
            ),
          ],
          if (status == 'pending') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectDialog(sub['id']),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _reviewSubmission(sub['id'], 'approve'),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approve'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoChip(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.grey.shade600),
      ),
    );
  }

  void _showRejectDialog(String submissionId) {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject Registration'),
        content: TextField(
          controller: notesController,
          decoration: const InputDecoration(hintText: 'Reason (optional)', border: OutlineInputBorder()),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _reviewSubmission(submissionId, 'reject', notes: notesController.text);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _showWebDashboard() {
    final url = 'https://lessontracker.pro/dashboard';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Web Dashboard'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.open_in_browser, size: 48, color: AppColors.sunsetBright),
            const SizedBox(height: 12),
            Text(
              'Open the full web dashboard to manage registrations, review submissions, and more.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
              child: Text(url, style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close')),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // Would open URL in browser
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.sunsetBright),
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }
}
