import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/models/models.dart';
import '../../core/providers/supabase_instructor_provider.dart';
import '../../core/theme/app_colors.dart';

class PreviousTestsScreen extends ConsumerWidget {
  const PreviousTestsScreen({super.key});

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

    // Filter test reports for past tests
    final previousTests = instructorTestReports.value?.where((report) {
      final testDate = DateTime.parse(report['test_date']);
      return testDate.isBefore(DateTime.now());
    }).toList() ?? [];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Previous Tests', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: previousTests.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: AppColors.sunsetBright.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  const Text(
                    'No previous tests',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Past test results will appear here',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: previousTests.length,
              itemBuilder: (context, index) {
                final report = previousTests[index];
                final pupilData = report['pupils'];
                final result = _mapTestResult(report['result']);
                final passed = result == TestResult.pass;
                final testDate = DateTime.parse(report['test_date']);
                final String pupilName = pupilData != null
                    ? '${pupilData['first_name'] ?? ''} ${pupilData['last_name'] ?? ''}'.trim()
                    : 'Unknown';
                final String resolvedName = pupilName.isNotEmpty ? pupilName : 'Unknown';

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
                      backgroundColor: passed 
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.error.withValues(alpha: 0.1),
                      child: Icon(
                        passed ? Icons.check : Icons.close,
                        color: passed ? AppColors.success : AppColors.error,
                      ),
                    ),
                    title: Text(resolvedName, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('Test date: ${DateFormat('dd MMM yyyy').format(testDate)}'),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: passed 
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        passed ? 'Passed' : 'Failed',
                        style: TextStyle(
                          color: passed ? AppColors.success : AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('View $resolvedName\'s test report')),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
