import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:functions_client/functions_client.dart';

class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._();
  factory SubscriptionService() => _instance;
  SubscriptionService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<bool> createSubscription(String planId) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      final session = _client.auth.currentSession;
      if (session == null) return false;

      final response = await _client.functions.invoke(
        'create-checkout-session',
        body: {'plan_id': planId},
      );

      final data = response.data is Map<String, dynamic> ? response.data as Map<String, dynamic> : null;
      final url = data?['url'] as String?;

      if (url == null || url.isEmpty) return false;

      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      return true;
    } on FunctionException catch (e) {
      final msg = e.details is Map ? (e.details as Map)['error'] ?? 'Payment error' : 'Payment error';
      throw Exception(msg);
    } catch (e) {
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