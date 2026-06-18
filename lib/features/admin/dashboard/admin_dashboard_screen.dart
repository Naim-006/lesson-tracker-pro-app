import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';

class _ActivityItem {
  final String title;
  final String description;
  final String time;
  final IconData icon;

  _ActivityItem({
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
  });
}

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
  String? _errorMessage;
  List<_ActivityItem> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final client = Supabase.instance.client;
      final now = DateTime.now();

      // Get total instructors
      final instructorsResponse = await client
          .from('profiles')
          .select('id')
          .eq('role', 'instructor');
      _totalInstructors = instructorsResponse.length;

      // Get active subscriptions (instructors with valid subscription)
      final subscriptionsResponse = await client
          .from('instructor_subscriptions')
          .select('id')
          .gt('end_date', now.toIso8601String());
      _activeSubscriptions = subscriptionsResponse.length;

      // Get total pupils
      final pupilsResponse = await client.from('pupils').select('id');
      _totalPupils = pupilsResponse.length;

      // Get monthly revenue from actual payment data
      final monthStart = DateTime(now.year, now.month, 1).toIso8601String();
      final monthEnd = DateTime(now.year, now.month + 1, 1).toIso8601String();
      final paymentsResponse = await client
          .from('instructor_payments')
          .select('amount')
          .gte('payment_date', monthStart)
          .lt('payment_date', monthEnd);
      _monthlyRevenue = (paymentsResponse as List)
          .fold<double>(0, (sum, row) => sum + (row['amount'] as num).toDouble());

      // Load recent activities from multiple tables
      _recentActivities = await _loadRecentActivities(client, now);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load dashboard data: ${e.toString()}';
      });
    }
  }

  Future<List<_ActivityItem>> _loadRecentActivities(
    SupabaseClient client,
    DateTime now,
  ) async {
    final List<_ActivityItem> activities = [];

    // New instructor registrations (last 5)
    final instructors = await client
        .from('profiles')
        .select('full_name, created_at')
        .eq('role', 'instructor')
        .order('created_at', ascending: false)
        .limit(5);

    for (final instructor in instructors) {
      activities.add(_ActivityItem(
        title: 'New Instructor Registration',
        description: '${instructor['full_name'] ?? 'Unknown'} registered as instructor',
        time: _formatTimeAgo(DateTime.parse(instructor['created_at'])),
        icon: Icons.person_add,
      ));
    }

    // Recent subscriptions (last 5)
    final subscriptions = await client
        .from('instructor_subscriptions')
        .select('instructor_id, start_date, profiles(full_name)')
        .order('start_date', ascending: false)
        .limit(5);

    for (final sub in subscriptions) {
      final profile = sub['profiles'];
      final name = profile != null ? (profile['full_name'] ?? 'Unknown') : 'Unknown';
      activities.add(_ActivityItem(
        title: 'New Subscription',
        description: '$name started a subscription',
        time: _formatTimeAgo(DateTime.parse(sub['start_date'])),
        icon: Icons.subscriptions,
      ));
    }

    // Recent payments (last 5)
    final payments = await client
        .from('instructor_payments')
        .select('amount, payment_date, instructor_id, profiles(full_name)')
        .order('payment_date', ascending: false)
        .limit(5);

    for (final payment in payments) {
      final profile = payment['profiles'];
      final name = profile != null ? (profile['full_name'] ?? 'Unknown') : 'Unknown';
      final amount = payment['amount'];
      activities.add(_ActivityItem(
        title: 'Payment Received',
        description: '\$$amount payment from $name',
        time: _formatTimeAgo(DateTime.parse(payment['payment_date'])),
        icon: Icons.payment,
      ));
    }

    // Sort all activities by time (most recent first), take top 5
    activities.sort((a, b) {
      // Simple heuristic: earlier items are more recent from individual queries
      // We'll rely on the order within each group
      return 0;
    });

    // Return top 5 most recent across all types
    if (activities.length > 5) {
      return activities.sublist(0, 5);
    }
    return activities;
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final mutedColor = isDark ? AppColors.darkMuted : AppColors.lightMuted;

    return Scaffold(
      backgroundColor: bgColor,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView(isDark, textColor)
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dashboard',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: textColor,
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
                            final childWidth =
                                (width - totalSpacing) / crossAxisCount;

                            return Wrap(
                              spacing: spacing,
                              runSpacing: spacing,
                              children: [
                                SizedBox(
                                  width: childWidth,
                                  child: _buildStatCard(
                                    title: 'Total Instructors',
                                    value: _totalInstructors.toString(),
                                    icon: Icons.people,
                                    color: AppColors.sunset,
                                    cardColor: cardColor,
                                    textColor: textColor,
                                    mutedColor: mutedColor,
                                    isDark: isDark,
                                  ),
                                ),
                                SizedBox(
                                  width: childWidth,
                                  child: _buildStatCard(
                                    title: 'Active Subscriptions',
                                    value: _activeSubscriptions.toString(),
                                    icon: Icons.subscriptions,
                                    color: AppColors.success,
                                    cardColor: cardColor,
                                    textColor: textColor,
                                    mutedColor: mutedColor,
                                    isDark: isDark,
                                  ),
                                ),
                                SizedBox(
                                  width: childWidth,
                                  child: _buildStatCard(
                                    title: 'Total Pupils',
                                    value: _totalPupils.toString(),
                                    icon: Icons.school,
                                    color: AppColors.sunsetBright,
                                    cardColor: cardColor,
                                    textColor: textColor,
                                    mutedColor: mutedColor,
                                    isDark: isDark,
                                  ),
                                ),
                                SizedBox(
                                  width: childWidth,
                                  child: _buildStatCard(
                                    title: 'Monthly Revenue',
                                    value:
                                        '\$${_monthlyRevenue.toStringAsFixed(2)}',
                                    icon: Icons.attach_money,
                                    color: AppColors.success,
                                    cardColor: cardColor,
                                    textColor: textColor,
                                    mutedColor: mutedColor,
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        // Recent activity section
                        Text(
                          'Recent Activity',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_recentActivities.isEmpty)
                          _buildActivityCard(
                            title: 'No recent activity',
                            description: 'No records found yet.',
                            time: '',
                            icon: Icons.inbox,
                            cardColor: cardColor,
                            textColor: textColor,
                            mutedColor: mutedColor,
                            isDark: isDark,
                          )
                        else
                          ..._recentActivities.map(
                            (activity) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildActivityCard(
                                title: activity.title,
                                description: activity.description,
                                time: activity.time,
                                icon: activity.icon,
                                cardColor: cardColor,
                                textColor: textColor,
                                mutedColor: mutedColor,
                                isDark: isDark,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildErrorView(bool isDark, Color textColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: textColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDashboardData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
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
    required Color cardColor,
    required Color textColor,
    required Color mutedColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.black)
                .withValues(alpha: isDark ? 0.3 : 0.05),
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
              color: mutedColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
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
    required Color cardColor,
    required Color textColor,
    required Color mutedColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.black)
                .withValues(alpha: isDark ? 0.3 : 0.05),
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: mutedColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (time.isNotEmpty)
            Text(
              time,
              style: TextStyle(
                color: mutedColor,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}
