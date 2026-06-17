import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../activity/chat_screen.dart';
import '../instructor_monitoring/instructor_monitoring_screen.dart';

class InstructorsScreen extends ConsumerStatefulWidget {
  const InstructorsScreen({super.key});

  @override
  ConsumerState<InstructorsScreen> createState() => _InstructorsScreenState();
}

class _InstructorsScreenState extends ConsumerState<InstructorsScreen> {
  List<Map<String, dynamic>> _instructors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInstructors();
  }

  Future<void> _loadInstructors() async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('''
            id,
            full_name,
            email,
            phone,
            created_at,
            instructor_subscriptions(
              start_date,
              end_date,
              status
            )
          ''')
          .eq('role', 'instructor');

      setState(() {
        _instructors = response as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  color: Colors.white,
                  child: Row(
                    children: [
                      const Text(
                        'Instructors',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Add instructor
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Instructor'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.sunset,
                        ),
                      ),
                    ],
                  ),
                ),
                // Instructors list
                Expanded(
                  child: _instructors.isEmpty
                      ? const Center(
                          child: Text('No instructors found'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _instructors.length,
                          itemBuilder: (context, index) {
                            final instructor = _instructors[index];
                            final subscription = instructor['instructor_subscriptions'] as List?;
                            final hasActiveSubscription = subscription != null && subscription.isNotEmpty;
                            
                            return _buildInstructorCard(
                              instructor,
                              hasActiveSubscription,
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildInstructorCard(Map<String, dynamic> instructor, bool hasActiveSubscription) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.sunset.withValues(alpha: 0.1),
                child: Text(
                  instructor['full_name']?.toString().substring(0, 1).toUpperCase() ?? 'I',
                  style: TextStyle(
                    color: AppColors.sunset,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      instructor['full_name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      instructor['email'] ?? '',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: hasActiveSubscription
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  hasActiveSubscription ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: hasActiveSubscription ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showInstructorDetails(instructor),
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Details'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => InstructorMonitoringScreen(
                        instructorId: instructor['id'],
                        instructorName: instructor['full_name'] ?? 'Unknown',
                      ),
                    ));
                  },
                  icon: const Icon(Icons.monitor),
                  label: const Text('Monitor'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        pupilId: instructor['id'],
                        pupilName: instructor['full_name'] ?? 'Unknown',
                      ),
                    ));
                  },
                  icon: const Icon(Icons.message),
                  label: const Text('Message'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    if (date is String) {
      final dt = DateTime.tryParse(date);
      if (dt != null) {
        return '${dt.day}/${dt.month}/${dt.year}';
      }
    }
    if (date is DateTime) {
      return '${date.day}/${date.month}/${date.year}';
    }
    return date.toString();
  }

  void _showInstructorDetails(Map<String, dynamic> instructor) {
    final subscription = instructor['instructor_subscriptions'] as List?;
    final activeSub = subscription?.isNotEmpty == true ? subscription!.first as Map<String, dynamic> : null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(instructor['full_name'] ?? 'Instructor Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow(Icons.email, 'Email', instructor['email'] ?? 'N/A'),
              const SizedBox(height: 12),
              _detailRow(Icons.phone, 'Phone', instructor['phone'] ?? 'N/A'),
              const SizedBox(height: 12),
              _detailRow(Icons.calendar_today, 'Joined', instructor['created_at'] != null ? _formatDate(instructor['created_at']) : 'N/A'),
              if (activeSub != null) ...[
                const SizedBox(height: 12),
                _detailRow(Icons.subscriptions, 'Subscription Status', activeSub['status'] ?? 'N/A'),
                const SizedBox(height: 12),
                _detailRow(Icons.date_range, 'Start Date', activeSub['start_date'] != null ? _formatDate(activeSub['start_date']) : 'N/A'),
                const SizedBox(height: 12),
                _detailRow(Icons.date_range, 'End Date', activeSub['end_date'] != null ? _formatDate(activeSub['end_date']) : 'N/A'),
              ],
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }
}
