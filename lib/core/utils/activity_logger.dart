import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityLogger {
  static Future<void> log({
    required String action,
    String? details,
    String? ipAddress,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('instructor_activity_logs').insert({
        'instructor_id': user.id,
        'action': action,
        'details': details,
        'ip_address': ipAddress,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  static Future<void> logLogin() => log(action: 'login', details: 'User logged in');
  static Future<void> logLogout() => log(action: 'logout', details: 'User logged out');
  static Future<void> logLessonBooked(String pupilName) =>
      log(action: 'lesson_booked', details: 'Lesson booked for $pupilName');
  static Future<void> logLessonCompleted(String pupilName) =>
      log(action: 'lesson_completed', details: 'Lesson completed for $pupilName');
  static Future<void> logPayment(double amount) =>
      log(action: 'payment', details: 'Payment of \$${amount.toStringAsFixed(2)} processed');
  static Future<void> logPupilAdded(String pupilName) =>
      log(action: 'pupil_added', details: 'New pupil added: $pupilName');
  static Future<void> logProfileUpdated() =>
      log(action: 'profile_updated', details: 'Profile updated');
  static Future<void> logLocation(double lat, double lng) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      await Supabase.instance.client.from('instructor_locations').insert({
        'instructor_id': user.id,
        'latitude': lat,
        'longitude': lng,
        'accuracy': 0,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }
}
