import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._();
  factory SubscriptionService() => _instance;
  SubscriptionService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<bool> createSubscription(String planId) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      final plan = await _client
          .from('subscription_plans')
          .select('duration_months, price, name')
          .eq('id', planId)
          .single();

      final durationMonths = (plan['duration_months'] as num?)?.toInt() ?? 1;
      final now = DateTime.now();
      final endDate = DateTime(now.year, now.month + durationMonths, now.day);

      await _client.from('instructor_subscriptions').insert({
        'instructor_id': user.id,
        'plan_id': planId,
        'plan_type': plan['name'],
        'amount': plan['price'],
        'start_date': now.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'status': 'active',
        'payment_status': 'pending',
        'created_at': now.toIso8601String(),
      });

      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> activateFreeTrial() async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      final profile = await _client
          .from('profiles')
          .select('created_at')
          .eq('id', user.id)
          .single();

      final createdAt = DateTime.parse(profile['created_at']);
      final trialEnd = createdAt.add(const Duration(days: 60));

      await _client.from('instructor_subscriptions').insert({
        'instructor_id': user.id,
        'plan_type': 'Free Trial',
        'plan_id': null,
        'amount': 0,
        'start_date': createdAt.toIso8601String(),
        'end_date': trialEnd.toIso8601String(),
        'status': 'active',
        'payment_status': 'free_trial',
        'created_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (_) {
      return false;
    }
  }
}