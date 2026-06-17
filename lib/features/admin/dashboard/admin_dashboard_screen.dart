import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _totalInstructors = 0;
  int _activeSubscriptions = 0;
  int _totalPupils = 0;
  double _monthlyRevenue = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      // Get total instructors
      final instructorsResponse = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('role', 'instructor');
      _totalInstructors = instructorsResponse.length;

      // Get active subscriptions (instructors with valid subscription)
      final now = DateTime.now();
      final subscriptionsResponse = await Supabase.instance.client
          .from('instructor_subscriptions')
          .select('id')
          .gt('end_date', now.toIso8601String());
      _activeSubscriptions = subscriptionsResponse.length;

      // Get total pupils
      final pupilsResponse = await Supabase.instance.client
          .from('pupils')
          .select('id');
      _totalPupils = pupilsResponse.length;

      // Get monthly revenue (simplified - you'd need to track actual payments)
      // For now, this is a placeholder
      _monthlyRevenue = _activeSubscriptions * 29.99; // Assuming $29.99/month

      setState(() {
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Stats cards
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      int crossAxisCount;
                      if (width >= 600) {
                        crossAxisCount = 4;
                      } else if (width >= 300) {
                        crossAxisCount = 2;
                      } else {
                        crossAxisCount = 1;
                      }
                      final spacing = 16.0;
                      final totalSpacing = spacing * (crossAxisCount - 1);
                      final childWidth = (width - totalSpacing) / crossAxisCount;

                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          SizedBox(width: childWidth, child: _buildStatCard(title: 'Total Instructors', value: _totalInstructors.toString(), icon: Icons.people, color: AppColors.sunset)),
                          SizedBox(width: childWidth, child: _buildStatCard(title: 'Active Subscriptions', value: _activeSubscriptions.toString(), icon: Icons.subscriptions, color: AppColors.success)),
                          SizedBox(width: childWidth, child: _buildStatCard(title: 'Total Pupils', value: _totalPupils.toString(), icon: Icons.school, color: AppColors.sunsetBright)),
                          SizedBox(width: childWidth, child: _buildStatCard(title: 'Monthly Revenue', value: '\$${_monthlyRevenue.toStringAsFixed(2)}', icon: Icons.attach_money, color: AppColors.success)),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  // Recent activity section
                  const Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildActivityCard(
                    title: 'New Instructor Registration',
                    description: 'John Doe registered as instructor',
                    time: '2 hours ago',
                    icon: Icons.person_add,
                  ),
                  const SizedBox(height: 12),
                  _buildActivityCard(
                    title: 'Subscription Renewed',
                    description: 'Jane Smith renewed her subscription',
                    time: '5 hours ago',
                    icon: Icons.subscriptions,
                  ),
                  const SizedBox(height: 12),
                  _buildActivityCard(
                    title: 'Payment Received',
                    description: 'Payment of \$29.99 from instructor #123',
                    time: '1 day ago',
                    icon: Icons.payment,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard({
    required String title,
    required String description,
    required String time,
    required IconData icon,
  }) {
    return Container(
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.sunset.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.sunset, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
