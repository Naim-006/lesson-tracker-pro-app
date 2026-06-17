import 'package:supabase_flutter/supabase_flutter.dart';

/// Utility to migrate local data to Supabase
/// 
/// This utility helps migrate data from the local appStateProvider
/// to Supabase. Run this once after setting up Supabase to transfer
/// existing data.
class DataMigration {
  final SupabaseClient _supabase;

  DataMigration(this._supabase);

  /// Migrate all local data to Supabase
  /// 
  /// This method should be called once after Supabase is set up
  /// to transfer existing local data. It returns a report of what was migrated.
  Future<MigrationReport> migrateAll({
    required List<Map<String, dynamic>> localPupils,
    required List<Map<String, dynamic>> localLessons,
    required List<Map<String, dynamic>> localSlots,
    required List<Map<String, dynamic>> localTransactions,
  }) async {
    final report = MigrationReport();

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to migrate data');
      }

      // Check if instructor profile exists
      final instructorExists = await _supabase
          .from('instructors')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (instructorExists == null) {
        // Create instructor profile
        await _supabase.from('instructors').insert({
          'id': user.id,
          'hourly_rate': 30.0, // Default rate
          'is_verified': true, // Auto-verify existing instructors
          'rating': 5.0,
        });
        report.instructorsCreated++;
      }

      // Migrate pupils
      for (final pupil in localPupils) {
        try {
          // Create profile
          final profileData = {
            'id': _generateId(),
            'full_name': '${pupil['firstName']} ${pupil['lastName']}',
            'email': pupil['email'] ?? '',
            'phone': pupil['phone'] ?? '',
            'role': 'pupil',
            'email_verified': true,
          };

          await _supabase.from('profiles').insert(profileData);

          // Create pupil record
          final pupilData = {
            'id': profileData['id'],
            'address': pupil['address'] ?? '',
            'postcode': pupil['postcode'] ?? '',
            'test_progress': {},
          };

          await _supabase.from('pupils').insert(pupilData);

          // Link to instructor
          await _supabase.from('instructor_pupil_links').insert({
            'instructor_id': user.id,
            'pupil_id': profileData['id'],
            'status': _mapPupilStatus(pupil['status']),
            'linked_at': DateTime.now().toIso8601String(),
          });

          report.pupilsMigrated++;
        } catch (e) {
          report.pupilsFailed++;
          report.errors.add('Failed to migrate pupil ${pupil['firstName']}: $e');
        }
      }

      // Migrate lessons
      for (final lesson in localLessons) {
        try {
          final lessonData = {
            'id': _generateId(),
            'instructor_id': user.id,
            'pupil_id': lesson['pupilId'],
            'date': lesson['date'].toIso8601String(),
            'time': lesson['time'],
            'duration': lesson['duration'],
            'pickup_location': lesson['pickupLocation'] ?? '',
            'status': _mapLessonStatus(lesson['status']),
            'notes': lesson['notes'] ?? '',
          };

          await _supabase.from('lessons').insert(lessonData);
          report.lessonsMigrated++;
        } catch (e) {
          report.lessonsFailed++;
          report.errors.add('Failed to migrate lesson: $e');
        }
      }

      // Migrate open slots
      for (final slot in localSlots) {
        try {
          final slotData = {
            'id': _generateId(),
            'instructor_id': user.id,
            'date': slot['date'].toIso8601String(),
            'start_time': slot['startTime'],
            'duration': slot['duration'],
            'location': slot['location'] ?? '',
            'is_booked': slot['isBooked'] ?? false,
            'booked_by': slot['bookedBy'],
          };

          await _supabase.from('open_slots').insert(slotData);
          report.slotsMigrated++;
        } catch (e) {
          report.slotsFailed++;
          report.errors.add('Failed to migrate slot: $e');
        }
      }

      // Migrate transactions as payments
      for (final tx in localTransactions) {
        try {
          if (tx['type'] == 'income') {
            final paymentData = {
              'id': _generateId(),
              'instructor_id': user.id,
              'pupil_id': tx['pupilId'],
              'amount': tx['amount'],
              'payment_method': 'cash',
              'status': 'completed',
              'created_at': tx['date'].toIso8601String(),
            };

            await _supabase.from('payments').insert(paymentData);
            report.paymentsMigrated++;
          }
        } catch (e) {
          report.paymentsFailed++;
          report.errors.add('Failed to migrate payment: $e');
        }
      }

      report.success = true;
    } catch (e) {
      report.success = false;
      report.errors.add('Migration failed: $e');
    }

    return report;
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        (DateTime.now().microsecond % 10000).toString();
  }

  String _mapPupilStatus(dynamic status) {
    switch (status?.toString()) {
      case 'current':
        return 'active';
      case 'waiting':
        return 'pending';
      case 'passed':
        return 'passed';
      case 'archived':
        return 'archived';
      default:
        return 'active';
    }
  }

  String _mapLessonStatus(dynamic status) {
    switch (status?.toString()) {
      case 'scheduled':
        return 'scheduled';
      case 'completed':
        return 'completed';
      case 'cancelled':
        return 'cancelled';
      default:
        return 'scheduled';
    }
  }
}

class MigrationReport {
  bool success = false;
  int instructorsCreated = 0;
  int pupilsMigrated = 0;
  int pupilsFailed = 0;
  int lessonsMigrated = 0;
  int lessonsFailed = 0;
  int slotsMigrated = 0;
  int slotsFailed = 0;
  int paymentsMigrated = 0;
  int paymentsFailed = 0;
  final List<String> errors = [];

  @override
  String toString() {
    return '''
Migration Report:
================
Success: $success

Instructors Created: $instructorsCreated
Pupils Migrated: $pupilsMigrated (Failed: $pupilsFailed)
Lessons Migrated: $lessonsMigrated (Failed: $lessonsFailed)
Slots Migrated: $slotsMigrated (Failed: $slotsFailed)
Payments Migrated: $paymentsMigrated (Failed: $paymentsFailed)

${errors.isEmpty ? 'No errors' : 'Errors:\n${errors.join('\n')}'}
''';
  }
}
