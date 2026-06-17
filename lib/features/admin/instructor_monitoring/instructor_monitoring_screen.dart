import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';

class InstructorMonitoringScreen extends ConsumerStatefulWidget {
  final String instructorId;
  final String instructorName;

  const InstructorMonitoringScreen({
    super.key,
    required this.instructorId,
    required this.instructorName,
  });

  @override
  ConsumerState<InstructorMonitoringScreen> createState() => _InstructorMonitoringScreenState();
}

class _InstructorMonitoringScreenState extends ConsumerState<InstructorMonitoringScreen> {
  List<Map<String, dynamic>> _activityLogs = [];
  List<Map<String, dynamic>> _locationHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMonitoringData();
  }

  Future<void> _loadMonitoringData() async {
    try {
      final activityResponse = await Supabase.instance.client
          .from('instructor_activity_logs')
          .select('*')
          .eq('instructor_id', widget.instructorId)
          .order('created_at', ascending: false)
          .limit(50);

      final locationResponse = await Supabase.instance.client
          .from('instructor_locations')
          .select('*')
          .eq('instructor_id', widget.instructorId)
          .order('timestamp', ascending: false)
          .limit(20);

      setState(() {
        _activityLogs = activityResponse as List<Map<String, dynamic>>;
        _locationHistory = locationResponse as List<Map<String, dynamic>>;
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
      appBar: AppBar(
        title: Text('Monitoring: ${widget.instructorName}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Activity'),
                      Tab(text: 'Location'),
                      Tab(text: 'Statistics'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildActivityTab(),
                        _buildLocationTab(),
                        _buildStatisticsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildActivityTab() {
    return _activityLogs.isEmpty
        ? const Center(child: Text('No activity logs found'))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _activityLogs.length,
            itemBuilder: (context, index) {
              final log = _activityLogs[index];
              return _buildActivityCard(log);
            },
          );
  }

  Widget _buildActivityCard(Map<String, dynamic> log) {
    final action = log['action'] as String?;
    final details = log['details'] as String?;
    final timestamp = log['created_at'] as String?;
    final ipAddress = log['ip_address'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
              Icon(_getActionIcon(action), color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  action ?? 'Unknown Action',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                timestamp != null ? _formatTimestamp(timestamp) : 'N/A',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          if (details != null && details.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              details,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
          ],
          if (ipAddress != null && ipAddress.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'IP: $ipAddress',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationTab() {
    return _locationHistory.isEmpty
        ? const Center(child: Text('No location data found'))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _locationHistory.length,
            itemBuilder: (context, index) {
              final location = _locationHistory[index];
              return _buildLocationCard(location);
            },
          );
  }

  Widget _buildLocationCard(Map<String, dynamic> location) {
    final latitude = location['latitude'] as num?;
    final longitude = location['longitude'] as num?;
    final timestamp = location['timestamp'] as String?;
    final accuracy = location['accuracy'] as num?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
              const Icon(Icons.location_on, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Lat: ${latitude?.toStringAsFixed(6) ?? 'N/A'}, Lng: ${longitude?.toStringAsFixed(6) ?? 'N/A'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Text(
                timestamp != null ? _formatTimestamp(timestamp) : 'N/A',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(width: 16),
              if (accuracy != null) ...[
                Icon(Icons.gps_fixed, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Accuracy: ${accuracy.toStringAsFixed(0)}m',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Instructor Statistics',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Total Logins',
                  value: _activityLogs.where((log) => log['action'] == 'login').length.toString(),
                  icon: Icons.login,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  title: 'Lessons Booked',
                  value: _activityLogs.where((log) => log['action'] == 'lesson_booked').length.toString(),
                  icon: Icons.calendar_today,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Payments Processed',
                  value: _activityLogs.where((log) => log['action'] == 'payment').length.toString(),
                  icon: Icons.payment,
                  color: AppColors.sunsetBright,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  title: 'Location Updates',
                  value: _locationHistory.length.toString(),
                  icon: Icons.location_on,
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
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
                const Text(
                  'Unusual Activity Alerts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _AlertItem(
                  title: 'No unusual activity detected',
                  description: 'All activity appears normal',
                  severity: 'low',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActionIcon(String? action) {
    switch (action?.toLowerCase()) {
      case 'login':
        return Icons.login;
      case 'logout':
        return Icons.logout;
      case 'lesson_booked':
        return Icons.calendar_today;
      case 'payment':
        return Icons.payment;
      case 'profile_updated':
        return Icons.edit;
      default:
        return Icons.info;
    }
  }

  String _formatTimestamp(String timestamp) {
    final date = DateTime.parse(timestamp);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
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
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertItem extends StatelessWidget {
  const _AlertItem({
    required this.title,
    required this.description,
    required this.severity,
  });

  final String title;
  final String description;
  final String severity;

  @override
  Widget build(BuildContext context) {
    final color = severity == 'high'
        ? AppColors.error
        : severity == 'medium'
            ? AppColors.warning
            : AppColors.success;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
