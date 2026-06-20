import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';

class AdminEnquiriesScreen extends ConsumerStatefulWidget {
  const AdminEnquiriesScreen({super.key});

  @override
  ConsumerState<AdminEnquiriesScreen> createState() => _AdminEnquiriesScreenState();
}

class _AdminEnquiriesScreenState extends ConsumerState<AdminEnquiriesScreen> {
  List<Map<String, dynamic>> _enquiries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEnquiries();
  }

  Future<void> _loadEnquiries() async {
    try {
      final response = await Supabase.instance.client
          .from('enquiries')
          .select('''
            id,
            instructor_id,
            instructor_name,
            instructor_email,
            instructor_phone,
            first_name,
            last_name,
            email,
            phone,
            experience_level,
            gearbox_preference,
            message,
            status,
            created_at
          ''')
          .order('created_at', ascending: false);

      setState(() {
        _enquiries = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading enquiries: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  child: const Text(
                    'Enquiries',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Enquiries list
                Expanded(
                  child: _enquiries.isEmpty
                      ? const Center(
                          child: Text('No enquiries found'),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadEnquiries,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _enquiries.length,
                            itemBuilder: (context, index) {
                              final enquiry = _enquiries[index];
                              return _buildEnquiryCard(enquiry);
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildEnquiryCard(Map<String, dynamic> enquiry) {
    final firstName = enquiry['first_name'] as String?;
    final lastName = enquiry['last_name'] as String?;
    final fullName = [firstName, lastName].where((n) => n != null && n.isNotEmpty).join(' ');
    final email = enquiry['email'] as String?;
    final phone = enquiry['phone'] as String?;
    final experienceLevel = enquiry['experience_level'] as String?;
    final gearboxPreference = enquiry['gearbox_preference'] as String?;
    final message = enquiry['message'] as String?;
    final status = enquiry['status'] as String?;
    final createdAt = enquiry['created_at'] as String?;
    final enquiryId = enquiry['id'] as String?;
    final instructorName = enquiry['instructor_name'] as String?;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName.isNotEmpty ? fullName : 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email ?? '',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    if (phone != null && phone.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        phone,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status?.toUpperCase() ?? 'UNKNOWN',
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (instructorName != null && instructorName.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.sunset.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.support_agent, size: 14, color: AppColors.sunset),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Managed by $instructorName',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.sunset),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.school, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Experience: ${experienceLevel ?? 'N/A'}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.settings, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Gearbox: ${gearboxPreference ?? 'N/A'}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          if (message != null && message.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                createdAt != null ? _formatDate(createdAt) : 'N/A',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _updateEnquiryStatus(enquiryId, 'responded');
                  },
                  icon: const Icon(Icons.reply),
                  label: const Text('Reply'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _updateEnquiryStatus(enquiryId, 'contacted');
                  },
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Contacted'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _acceptLead(enquiry),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Accept Lead'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.success,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _deleteEnquiry(enquiryId),
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _updateEnquiryStatus(String? id, String newStatus) async {
    if (id == null) return;
    try {
      await Supabase.instance.client
          .from('enquiries')
          .update({'status': newStatus})
          .eq('id', id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Enquiry marked as $newStatus')),
        );
        _loadEnquiries();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating enquiry: $e')),
        );
      }
    }
  }

  Future<void> _deleteEnquiry(String? id) async {
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Enquiry'),
        content: const Text('Are you sure you want to delete this enquiry?'),
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
      await Supabase.instance.client.from('enquiries').delete().eq('id', id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enquiry deleted')),
        );
        _loadEnquiries();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting enquiry: $e')),
        );
      }
    }
  }

  Future<void> _acceptLead(Map<String, dynamic> enquiry) async {
    final instructors = await Supabase.instance.client
        .from('profiles')
        .select('id, full_name, email')
        .eq('role', 'instructor')
        .order('full_name');

    if (!mounted) return;

    final instructorsList = instructors;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign to Instructor'),
        content: SizedBox(
          width: double.maxFinite,
          child: instructorsList.isEmpty
              ? const Text('No instructors available')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: instructorsList.length,
                  itemBuilder: (context, index) {
                    final instructor = instructorsList[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.sunset.withValues(alpha: 0.1),
                        child: Text(
                          (instructor['full_name'] as String? ?? '?')[0].toUpperCase(),
                          style: const TextStyle(color: AppColors.sunset),
                        ),
                      ),
                      title: Text(instructor['full_name'] ?? 'Unknown'),
                      subtitle: Text(instructor['email'] ?? ''),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _createInvitation(enquiry, instructor['id'] as String, instructor['full_name'] as String? ?? '');
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ],
      ),
    );
  }

  Future<void> _createInvitation(Map<String, dynamic> enquiry, String instructorId, String instructorName) async {
    final enquiryId = enquiry['id'] as String?;
    final firstName = enquiry['first_name'] as String? ?? '';
    final lastName = enquiry['last_name'] as String? ?? '';
    final email = enquiry['email'] as String? ?? '';
    final phone = enquiry['phone'] as String? ?? '';

    try {
      final uuid = const Uuid();
      final code = uuid.v4().substring(0, 8).toUpperCase();

      await Supabase.instance.client.from('pupil_invitations').insert({
        'instructor_id': instructorId,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'invitation_code': code,
        'status': 'pending',
        'source': 'admin_conversion',
        'created_at': DateTime.now().toIso8601String(),
      });

      if (enquiryId != null) {
        await Supabase.instance.client
            .from('enquiries')
            .update({'status': 'converted', 'assigned_to_id': instructorId})
            .eq('id', enquiryId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lead assigned to $instructorName. Invitation code: $code')),
        );
        _loadEnquiries();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accepting lead: $e')),
        );
      }
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'contacted':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'not_interested':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String dateString) {
    final date = DateTime.tryParse(dateString);
    if (date == null) return 'N/A';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
