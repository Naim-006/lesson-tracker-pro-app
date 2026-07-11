import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_state_provider.dart';

// Provider for instructor profile
final instructorProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  ref.watch(dataRefreshProvider);
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;

  try {
    final response = await Supabase.instance.client
        .from('profiles')
        .select('*')
        .eq('id', user.id)
        .single();

    return response;
  } catch (e) {
    return null;
  }
});

// Provider for instructor's pupils
final instructorPupilsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(dataRefreshProvider);
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];

  try {
    final response = await Supabase.instance.client
        .from('instructor_pupil_links')
        .select('status, pupils!inner(*)')
        .eq('instructor_id', user.id)
        .neq('status', 'revoked');

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    return [];
  }
});

// Provider for instructor's lessons
final instructorLessonsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(dataRefreshProvider);
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];

  try {
    final response = await Supabase.instance.client
        .from('lessons')
        .select('*, pupils!inner(first_name, last_name)')
        .eq('instructor_id', user.id)
        .order('date', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    return [];
  }
});

// Provider for instructor's open slots
final instructorSlotsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(dataRefreshProvider);
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];

  try {
    final response = await Supabase.instance.client
        .from('open_slots')
        .select('*')
        .eq('instructor_id', user.id)
        .eq('is_booked', false)
        .gte('date', DateTime.now().toIso8601String())
        .order('date', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    return [];
  }
});

// Provider for instructor's enquiries
final instructorEnquiriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(dataRefreshProvider);
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];

  try {
    final response = await Supabase.instance.client
        .from('enquiries')
        .select('*, pupils!left(profiles!left(full_name, email))')
        .eq('instructor_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    return [];
  }
});

// Provider for instructor's payments (from instructor_payments + all transactions)
final instructorPaymentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(dataRefreshProvider);
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];

  try {
    final results = <Map<String, dynamic>>[];

    try {
      final payments = await Supabase.instance.client
          .from('instructor_payments')
          .select('*')
          .eq('instructor_id', user.id)
          .order('created_at', ascending: false);
      results.addAll(List<Map<String, dynamic>>.from(payments));
    } catch (_) {}

    try {
      final txns = await Supabase.instance.client
          .from('transactions')
          .select('*')
          .eq('instructor_id', user.id)
          .order('created_at', ascending: false);
      results.addAll(List<Map<String, dynamic>>.from(txns));
    } catch (_) {}

    results.sort((a, b) {
      final da = a['created_at'] as String? ?? a['date'] as String? ?? '';
      final db = b['created_at'] as String? ?? b['date'] as String? ?? '';
      return db.compareTo(da);
    });

    return results;
  } catch (e) {
    return [];
  }
});

// Provider for instructor's invoices
final instructorInvoicesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(dataRefreshProvider);
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];

  try {
    final response = await Supabase.instance.client
        .from('invoices')
        .select('*, pupils!inner(first_name, last_name)')
        .eq('instructor_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    return [];
  }
});

// Provider for instructor's messages
final instructorMessagesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(dataRefreshProvider);
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];

  try {
    final response = await Supabase.instance.client
        .from('messages')
        .select('*, sender:profiles!sender_id(full_name, avatar_url), receiver:profiles!receiver_id(full_name, avatar_url)')
        .or('sender_id.eq.${user.id},receiver_id.eq.${user.id}')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    return [];
  }
});

// Provider for instructor's notifications
final instructorNotificationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(dataRefreshProvider);
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];

  try {
    final response = await Supabase.instance.client
        .from('app_notifications')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    return [];
  }
});

// Provider for instructor's vehicles
final instructorVehiclesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(dataRefreshProvider);
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];

  try {
    final response = await Supabase.instance.client
        .from('vehicles')
        .select('*')
        .eq('instructor_id', user.id)
        .order('is_primary', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    return [];
  }
});

// Provider for instructor's calendar events
final instructorCalendarEventsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(dataRefreshProvider);
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];

  try {
    final response = await Supabase.instance.client
        .from('calendar_events')
        .select('*')
        .eq('instructor_id', user.id)
        .order('start_date', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    return [];
  }
});

// Provider for instructor's teaching resources
final instructorTeachingResourcesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(dataRefreshProvider);
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];

  try {
    final response = await Supabase.instance.client
        .from('teaching_resources')
        .select('*')
        .eq('instructor_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    return [];
  }
});

// Provider for instructor's test reports
final instructorTestReportsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(dataRefreshProvider);
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];

  try {
    final response = await Supabase.instance.client
        .from('test_reports')
        .select('*, pupils!inner(first_name, last_name)')
        .eq('instructor_id', user.id)
        .order('test_date', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    return [];
  }
});

// Provider for instructor's mileage entries
final instructorMileageProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(dataRefreshProvider);
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];

  try {
    final response = await Supabase.instance.client
        .from('mileage_entries')
        .select('*')
        .eq('instructor_id', user.id)
        .order('date', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    return [];
  }
});

// Provider for banners (public)
final bannersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(dataRefreshProvider);
  try {
    final response = await Supabase.instance.client
        .from('banners')
        .select('*')
        .eq('is_active', true)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    return [];
  }
});

// Provider for pupil by ID
final pupilByIdProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, pupilId) async {
  ref.watch(dataRefreshProvider);
  try {
    final response = await Supabase.instance.client
        .from('pupils')
        .select('*')
        .eq('id', pupilId)
        .single();

    return response;
  } catch (e) {
    return null;
  }
});

// Provider for pupil's completed unpaid lessons
final pupilUnpaidLessonsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, pupilId) async {
  ref.watch(dataRefreshProvider);
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];

  try {
    // Fetch completed unpaid + overdue (past scheduled) lessons
    final response = await Supabase.instance.client
        .from('lessons')
        .select('*')
        .eq('instructor_id', user.id)
        .eq('pupil_id', pupilId)
        .or('and(status.eq.completed,paid.eq.false),status.eq.scheduled')
        .order('date', ascending: false);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final results = List<Map<String, dynamic>>.from(response);

    // Filter: completed unpaid always included; scheduled only if past or today
    return results.where((l) {
      if (l['status'] == 'completed') return true;
      // scheduled: include only if date is past or today
      final d = DateTime.parse(l['date'] as String);
      return !d.isAfter(today);
    }).toList();
  } catch (e) {
    return [];
  }
});

