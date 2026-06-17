import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/models.dart';
import '../../core/providers/supabase_instructor_provider.dart';
import '../../core/theme/app_colors.dart';

class UpcomingTestsScreen extends ConsumerWidget {
  const UpcomingTestsScreen({super.key});

  TestResult _mapTestResult(String? result) {
    switch (result) {
      case 'pass': return TestResult.pass;
      case 'fail': return TestResult.fail;
      case 'pending': return TestResult.pending;
      default: return TestResult.pending;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instructorTestReports = ref.watch(instructorTestReportsProvider);

    // Filter test reports for upcoming tests (pending result)
    final upcomingTests = instructorTestReports.value?.where((report) {
      final result = _mapTestResult(report['result']);
      final testDate = DateTime.parse(report['test_date']);
      return result == TestResult.pending && testDate.isAfter(DateTime.now());
    }).toList() ?? [];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Upcoming Tests', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: upcomingTests.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event, size: 64, color: AppColors.sunsetBright.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  const Text(
                    'No upcoming tests',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pupils with scheduled tests will appear here',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: upcomingTests.length,
              itemBuilder: (context, index) {
                final report = upcomingTests[index];
                final pupilData = report['pupils'];
                final profile = pupilData?['profiles'];
                final testDate = DateTime.parse(report['test_date']);
                final pupilName = profile?['full_name'] ?? 'Unknown';
                final firstName = pupilName.split(' ').first;
                final daysUntil = testDate.difference(DateTime.now()).inDays;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.sunsetBright.withValues(alpha: 0.1),
                      child: Text(
                        firstName.isNotEmpty ? firstName[0] : '?',
                        style: TextStyle(color: AppColors.sunsetBright, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(pupilName, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('Test date: ${DateFormat('dd MMM yyyy').format(testDate)}'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: daysUntil <= 7 
                            ? AppColors.error.withValues(alpha: 0.1)
                            : AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        daysUntil == 0 ? 'Today' : daysUntil == 1 ? 'Tomorrow' : '$daysUntil days',
                        style: TextStyle(
                          color: daysUntil <= 7 ? AppColors.error : AppColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('View $firstName\'s test details')),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
