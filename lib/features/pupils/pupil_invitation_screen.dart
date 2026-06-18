import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/theme/app_colors.dart';

class PupilInvitationScreen extends ConsumerStatefulWidget {
  const PupilInvitationScreen({super.key});

  @override
  ConsumerState<PupilInvitationScreen> createState() => _PupilInvitationScreenState();
}

class _PupilInvitationScreenState extends ConsumerState<PupilInvitationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _postcodeController = TextEditingController();

  List<Map<String, dynamic>> _invitations = [];
  Map<String, int> _stats = {};
  bool _isLoading = true;
  bool _isSubmitting = false;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _postcodeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('pupil_invitations')
          .select('*')
          .eq('instructor_id', user.id)
          .order('created_at', ascending: false);

      final statsResponse = await Supabase.instance.client
          .rpc('get_invitation_stats', params: {'p_instructor_id': user.id});

      if (mounted) {
        setState(() {
          _invitations = response as List<Map<String, dynamic>>;
          _stats = Map<String, int>.from(statsResponse ?? {});
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generateInvitation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final uuid = const Uuid();
      final token = uuid.v4();
      final invitationCode = uuid.v4().substring(0, 8).toUpperCase();

      await Supabase.instance.client.from('pupil_invitations').insert({
        'instructor_id': user.id,
        'email': _emailController.text.trim().toLowerCase(),
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'postcode': _postcodeController.text.trim(),
        'invitation_code': invitationCode,
        'token': token,
        'status': 'pending',
        'source': 'manual',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invitation created! Share the link with your pupil.'),
            backgroundColor: AppColors.success,
          ),
        );
        _formKey.currentState!.reset();
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _approveInvitation(String id) async {
    try {
      await Supabase.instance.client
          .rpc('approve_pupil_invitation', params: {'invite_id': id});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation approved! Pupil can now sign up.'),
            backgroundColor: AppColors.success,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _rejectInvitation(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Invitation'),
        content: const Text('Are you sure you want to reject this pupil registration?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await Supabase.instance.client
          .rpc('reject_pupil_invitation', params: {'invite_id': id});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation rejected.')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _deleteInvitation(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Invitation'),
        content: const Text('Are you sure? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await Supabase.instance.client.from('pupil_invitations').delete().eq('id', id);
      if (mounted) {
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitation deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  String _getInvitationUrl(Map<String, dynamic> invitation) {
    final token = invitation['token'] ?? '';
    return 'https://lessontracker.pro/invite?token=$token';
  }

  List<Map<String, dynamic>> get _filteredInvitations {
    if (_filterStatus == 'all') return _invitations;
    return _invitations.where((i) => i['status'] == _filterStatus).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF8F6F2),
      appBar: AppBar(
        title: const Text('Pupil Invitations'),
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkBg : Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.sunsetBright,
          unselectedLabelColor: isDark ? Colors.white54 : Colors.grey,
          indicatorColor: AppColors.sunsetBright,
          tabs: const [
            Tab(text: 'Create'),
            Tab(text: 'Waiting'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCreateTab(isDark),
                _buildWaitingTab(isDark),
                _buildAllTab(isDark),
              ],
            ),
    );
  }

  Widget _buildCreateTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsRow(isDark),
            const SizedBox(height: 24),
            Text(
              'New Invitation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Create an invitation link to share with a potential pupil',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white54 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            _buildFormField(
              controller: _emailController,
              label: 'Email Address',
              hint: 'pupil@example.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              required: true,
              isDark: isDark,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildFormField(
                    controller: _firstNameController,
                    label: 'First Name',
                    hint: 'John',
                    icon: Icons.person_outline,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFormField(
                    controller: _lastNameController,
                    label: 'Last Name',
                    hint: 'Doe',
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildFormField(
                    controller: _phoneController,
                    label: 'Phone',
                    hint: '+44 7123 456789',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFormField(
                    controller: _postcodeController,
                    label: 'Postcode',
                    hint: 'SW1A 1AA',
                    icon: Icons.location_on_outlined,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _generateInvitation,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.link),
                label: Text(_isSubmitting ? 'Creating...' : 'Generate Invitation Link'),
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

  Widget _buildWaitingTab(bool isDark) {
    final waiting = _invitations.where((i) => i['status'] == 'submitted').toList();

    if (waiting.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No pending registrations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'When pupils submit their form,\nthey will appear here for approval',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white38 : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: waiting.length,
      itemBuilder: (context, index) => _buildWaitingCard(waiting[index], isDark),
    );
  }

  Widget _buildWaitingCard(Map<String, dynamic> invitation, bool isDark) {
    final firstName = invitation['first_name'] as String? ?? '';
    final lastName = invitation['last_name'] as String? ?? '';
    final email = invitation['email'] as String? ?? '';
    final phone = invitation['phone'] as String? ?? '';
    final postcode = invitation['postcode'] as String? ?? '';
    final dropoff = invitation['dropoff_address'] as String?;
    final formData = invitation['form_data'] as Map<String, dynamic>?;
    final submittedAt = invitation['form_submitted_at'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.sunsetBright.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.sunsetBright.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.sunsetBright.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.sunsetBright.withValues(alpha: 0.2),
                  child: Text(
                    '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.sunsetBright,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$firstName $lastName'.trim(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white54 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'WAITING',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.warning,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (phone.isNotEmpty) _buildInfoRow(Icons.phone, phone, isDark),
                if (postcode.isNotEmpty) _buildInfoRow(Icons.location_on, postcode, isDark),
                if (dropoff != null && dropoff.isNotEmpty) _buildInfoRow(Icons.home, dropoff, isDark),
                if (formData != null && formData.isNotEmpty) ...[
                  const Divider(height: 24),
                  Text(
                    'Form Details',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white54 : Colors.grey.shade500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (formData['experience'] != null && formData['experience'].toString().isNotEmpty)
                    _buildInfoRow(Icons.school, 'Experience: ${formData['experience']}', isDark),
                  if (formData['gearbox'] != null && formData['gearbox'].toString().isNotEmpty)
                    _buildInfoRow(Icons.settings, 'Gearbox: ${formData['gearbox']}', isDark),
                  if (formData['notes'] != null && formData['notes'].toString().isNotEmpty)
                    _buildInfoRow(Icons.note, formData['notes'], isDark),
                ],
                if (submittedAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Submitted: ${_formatDate(submittedAt)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.grey.shade400,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _approveInvitation(invitation['id']),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Approve'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _rejectInvitation(invitation['id']),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllTab(bool isDark) {
    return Column(
      children: [
        _buildFilterChips(isDark),
        Expanded(
          child: _filteredInvitations.isEmpty
              ? Center(
                  child: Text(
                    'No invitations found',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.grey.shade600,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredInvitations.length,
                  itemBuilder: (context, index) => _buildInvitationCard(_filteredInvitations[index], isDark),
                ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(bool isDark) {
    return Row(
      children: [
        _buildStatChip('Total', _stats['total'] ?? 0, Colors.blue, isDark),
        const SizedBox(width: 8),
        _buildStatChip('Waiting', _stats['submitted'] ?? 0, AppColors.warning, isDark),
        const SizedBox(width: 8),
        _buildStatChip('Approved', _stats['approved'] ?? 0, AppColors.success, isDark),
        const SizedBox(width: 8),
        _buildStatChip('Rejected', _stats['rejected'] ?? 0, AppColors.error, isDark),
      ],
    );
  }

  Widget _buildStatChip(String label, int count, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip('All', 'all', isDark),
          const SizedBox(width: 8),
          _buildFilterChip('Pending', 'pending', isDark),
          const SizedBox(width: 8),
          _buildFilterChip('Submitted', 'submitted', isDark),
          const SizedBox(width: 8),
          _buildFilterChip('Approved', 'approved', isDark),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDark) {
    final isSelected = _filterStatus == value;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.sunsetBright.withValues(alpha: 0.15)
              : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.sunsetBright : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.sunsetBright : (isDark ? Colors.white54 : Colors.grey.shade600),
          ),
        ),
      ),
    );
  }

  Widget _buildInvitationCard(Map<String, dynamic> invitation, bool isDark) {
    final email = invitation['email'] as String? ?? '';
    final firstName = invitation['first_name'] as String? ?? '';
    final lastName = invitation['last_name'] as String? ?? '';
    final status = invitation['status'] as String?;
    final createdAt = invitation['created_at'] as String?;
    final token = invitation['token'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$firstName $lastName'.trim().isNotEmpty ? '$firstName $lastName' : email,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (firstName.isNotEmpty && lastName.isNotEmpty)
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ),
              _buildStatusBadge(status, isDark),
            ],
          ),
          const SizedBox(height: 12),
          if (token != null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.sunsetBright.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.link, color: AppColors.sunsetBright, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getInvitationUrl(invitation),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 16),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _getInvitationUrl(invitation)));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copied!')),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (status == 'submitted')
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _approveInvitation(invitation['id']),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Approve'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              if (status == 'submitted') const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Share.share('Join my driving school! Sign up here: ${_getInvitationUrl(invitation)}');
                  },
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('Share'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _deleteInvitation(invitation['id']),
                icon: const Icon(Icons.delete_outline, size: 20),
                color: AppColors.error.withValues(alpha: 0.7),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String? status, bool isDark) {
    Color color;
    String label;
    switch (status) {
      case 'submitted':
        color = AppColors.warning;
        label = 'WAITING';
        break;
      case 'approved':
        color = AppColors.success;
        label = 'APPROVED';
        break;
      case 'rejected':
        color = AppColors.error;
        label = 'REJECTED';
        break;
      case 'accepted':
        color = Colors.blue;
        label = 'ACCEPTED';
        break;
      case 'expired':
        color = Colors.grey;
        label = 'EXPIRED';
        break;
      default:
        color = Colors.grey;
        label = 'PENDING';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    TextInputType? keyboardType,
    bool required = false,
    bool isDark = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null ? Icon(icon, size: 20) : null,
            filled: true,
            fillColor: isDark ? AppColors.darkCard : Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.sunsetBright, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          validator: required
              ? (value) {
                  if (value == null || value.trim().isEmpty) return 'Required';
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: isDark ? Colors.white38 : Colors.grey.shade400),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }
}
