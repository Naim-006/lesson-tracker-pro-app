import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_state_provider.dart';

// Provider for pupil profile
final pupilProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
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

// Provider for pupil's instructor link
final pupilInstructorLinkProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  ref.watch(dataRefreshProvider);
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return null;

  try {
    final response = await Supabase.instance.client
        .from('instructor_pupil_links')
        .select('*, instructor:profiles!instructor_id(full_name, email, avatar_url, business_name)')
        .eq('pupil_id', user.id)
        .eq('status', 'active')
        .maybeSingle();

    return response;
  } catch (e) {
    return null;
  }
});

// Provider for pupil's lessons
final pupilLessonsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(dataRefreshProvider);
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];

  try {
    final response = await Supabase.instance.client
        .from('lessons')
        .select('*, instructor:profiles!instructor_id(full_name, business_name, phone, email)')
        .eq('pupil_id', user.id)
        .order('date', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    return [];
  }
});

// Provider for pupil's upcoming lessons
final pupilUpcomingLessonsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(dataRefreshProvider);
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];

  try {
    final response = await Supabase.instance.client
        .from('lessons')
        .select('*, instructor:profiles!instructor_id(full_name, business_name)')
        .eq('pupil_id', user.id)
        .gte('date', DateTime.now().toIso8601String())
        .order('date', ascending: true)
        .limit(10);

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    return [];
  }
});

// Provider for pupil's progress skills
final pupilProgressSkillsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(dataRefreshProvider);
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];

    try {
      final response = await Supabase.instance.client
          .from('progress_skills')
          .select('*, progress_categories!inner(title, order_index)')
          .eq('pupil_id', user.id)
          .order('progress_categories(order_index)', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    return [];
  }
});

// Provider for pupil's messages
final pupilMessagesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
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

// Provider for pupil's notifications
final pupilNotificationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
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

// Provider for pupil's payments/invoices
final pupilPaymentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(dataRefreshProvider);
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];

  try {
    final response = await Supabase.instance.client
        .from('instructor_payments')
        .select('*')
        .eq('pupil_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    return [];
  }
});

// Provider for pupil's invoices
final pupilInvoicesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(dataRefreshProvider);
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];

  try {
    final response = await Supabase.instance.client
        .from('invoices')
        .select('*')
        .eq('pupil_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    return [];
  }
});

// Provider for pupil's teaching resources
final pupilTeachingResourcesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(dataRefreshProvider);
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];

  try {
    final linkResponse = await Supabase.instance.client
        .from('instructor_pupil_links')
        .select('instructor_id')
        .eq('pupil_id', user.id)
        .eq('status', 'active')
        .maybeSingle();

    if (linkResponse == null) return [];

    final instructorId = linkResponse['instructor_id'];

    final response = await Supabase.instance.client
        .from('teaching_resources')
        .select('*')
        .eq('instructor_id', instructorId)
        .or('visibility.eq.public,visibility.eq.selective')
        .order('created_at', ascending: false);

    final allResources = List<Map<String, dynamic>>.from(response);

    return allResources.where((r) {
      final visibility = r['visibility'] as String?;
      if (visibility == 'public') return true;
      if (visibility == 'selective') {
        final selectedIds = r['selected_pupil_ids'] as List<dynamic>?;
        if (selectedIds != null) {
          return selectedIds.map((e) => e.toString()).contains(user.id);
        }
      }
      return false;
    }).toList();
  } catch (e) {
    return [];
  }
});

// Provider for pupil's test reports
final pupilTestReportsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(dataRefreshProvider);
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];

  try {
    final response = await Supabase.instance.client
        .from('test_reports')
        .select('*')
        .eq('pupil_id', user.id)
        .order('test_date', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    return [];
  }
});

// Provider for available open slots from instructor
final pupilOpenSlotsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(dataRefreshProvider);
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];

  try {
    final linkResponse = await Supabase.instance.client
        .from('instructor_pupil_links')
        .select('instructor_id')
        .eq('pupil_id', user.id)
        .eq('status', 'active')
        .maybeSingle();

    if (linkResponse == null) return [];

    final instructorId = linkResponse['instructor_id'];

    final response = await Supabase.instance.client
        .from('open_slots')
        .select('*')
        .eq('instructor_id', instructorId)
        .eq('is_booked', false)
        .gte('date', DateTime.now().toIso8601String().split('T')[0])
        .order('date', ascending: true)
        .order('start_time', ascending: true);

    final pupilId = user.id;
    final slots = List<Map<String, dynamic>>.from(response).where((slot) {
      final filter = slot['group_filter'] as String? ?? 'current_pupils_only';
      if (filter == 'specific_pupils') {
        final targets = slot['target_pupil_ids'];
        if (targets is List) {
          return targets.map((e) => e.toString()).contains(pupilId);
        }
        return false;
      }
      return filter == 'current_pupils_only' || filter == 'private_to_school';
    }).toList();

    return slots;
  } catch (e) {
    return [];
  }
});

// Provider for pupil invitations
final pupilInvitationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(dataRefreshProvider);
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];

  try {
    final response = await Supabase.instance.client
        .from('pupil_invitations')
        .select('*')
        .eq('email', user.email ?? '')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    return [];
  }
});