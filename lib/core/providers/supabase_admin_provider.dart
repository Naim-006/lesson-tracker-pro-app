import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_state_provider.dart';

// Provider for all instructors (for admin panel)
final adminInstructorsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(dataRefreshProvider);
  try {
    final response = await Supabase.instance.client
        .from('profiles')
        .select('''
          id,
          full_name,
          email,
          phone,
          created_at,
          instructor_subscriptions(
            start_date,
            end_date,
            status
          )
        ''')
        .eq('role', 'instructor')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    return [];
  }
});

// Provider for all subscriptions (for admin panel)
final adminSubscriptionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(dataRefreshProvider);
  try {
    final response = await Supabase.instance.client
        .from('instructor_subscriptions')
        .select('''
          id,
          start_date,
          end_date,
          status,
          plan_type,
          profiles(
            full_name,
            email
          )
        ''')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    return [];
  }
});

// Provider for resource/subscription plans
final adminSubscriptionPlansProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(dataRefreshProvider);
  try {
    final response = await Supabase.instance.client
        .from('subscription_plans')
        .select('*')
        .order('sort_order', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    return [];
  }
});

// Provider for promo codes (for admin panel)
final adminPromoCodesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(dataRefreshProvider);
  try {
    final response = await Supabase.instance.client
        .from('promo_codes')
        .select('*')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    return [];
  }
});

// Provider for events (for admin panel)
final adminEventsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(dataRefreshProvider);
  try {
    final response = await Supabase.instance.client
        .from('events')
        .select('*')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    return [];
  }
});

// Provider for platform payments (for admin panel)
final adminPaymentsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(dataRefreshProvider);
  try {
    final response = await Supabase.instance.client
        .from('instructor_payments')
        .select('*, profiles(full_name)')
        .order('payment_date', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    return [];
  }
});

// Provider for instructor payment requests (for admin panel)
final adminPaymentRequestsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(dataRefreshProvider);
  try {
    final response = await Supabase.instance.client
        .from('instructor_payment_requests')
        .select('*, profiles(full_name)')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    return [];
  }
});

// Provider for enquiries (for admin panel)
final adminEnquiriesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  ref.watch(dataRefreshProvider);
  try {
    final response = await Supabase.instance.client
        .from('enquiries')
        .select('*')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  } catch (e) {
    return [];
  }
});
