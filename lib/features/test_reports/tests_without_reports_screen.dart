import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/models.dart';
import '../../core/providers/supabase_instructor_provider.dart';
import '../../core/theme/app_colors.dart';
import 'test_report_form_screen.dart';

class TestsWithoutReportsScreen extends ConsumerWidget {
  const TestsWithoutReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instructorPupils = ref.watch(instructorPupilsProvider);
    final instructorTestReports = ref.watch(instructorTestReportsProvider);

    // Get pupil IDs that have test reports
    final pupilIdsWithReports = instructorTestReports.value?.map((r) => r['pupil_id']).toSet() ?? {};

    // Filter pupils who don't have test reports
    final pupilsWithoutReports = instructorPupils.value?.where((link) {
      final pupilId = link['pupil_id'];
      return !pupilIdsWithReports.contains(pupilId);
    }).toList() ?? [];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Tests Without Reports', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: pupilsWithoutReports.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 64, color: AppColors.success.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  const Text(
                    'All caught up!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All test reports have been completed',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pupilsWithoutReports.length,
              itemBuilder: (context, index) {
                final link = pupilsWithoutReports[index];
                final pupilData = link['pupils'] ?? <String, dynamic>{};
                final pupilId = pupilData['id'];
                final firstName = pupilData['first_name'] ?? '';
                final lastName = pupilData['last_name'] ?? '';
                final pupilName = '$firstName $lastName'.trim();
                final resolvedTitle = pupilName.isNotEmpty ? pupilName : 'Unknown';

                // Create a Pupil object for the form
                final pupil = Pupil(
                  id: pupilId,
                  firstName: firstName,
                  lastName: lastName,
                  phone: pupilData['phone'] ?? '',
                  email: pupilData['email'] ?? '',
                  postcode: pupilData['postcode'],
                  pickupAddresses: pupilData['pickup_addresses'] != null
                      ? List<String>.from(pupilData['pickup_addresses'])
                      : [],
                );

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
                    title: Text(resolvedTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: const Text('No test report on file'),
                    trailing: const Text('Missing Report', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => TestReportFormScreen(pupil: pupil)),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
