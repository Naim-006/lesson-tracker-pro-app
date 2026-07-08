import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentService {
  static final PaymentService instance = PaymentService._();
  PaymentService._();

  /// Mock payment initiation. In a real production app, this would integrate
  /// with Stripe SDK or a backend endpoint to initialize a payment intent.
  Future<Map<String, dynamic>> initializePayment({
    required String pupilId,
    required double amount,
    required String description,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 1));

    // Create a mock check-out session token/intent
    final sessionId = 'mock_stripe_session_${DateTime.now().millisecondsSinceEpoch}';
    
    return {
      'success': true,
      'sessionId': sessionId,
      'amount': amount,
      'currency': 'gbp',
      'status': 'requires_payment_method',
    };
  }

  /// Process direct payment using mock bank transfer or manual flow.
  Future<bool> processDirectPayment({
    required String pupilId,
    required String instructorId,
    required double amount,
    required String paymentMethod,
    String? lessonId,
  }) async {
    try {
      final client = Supabase.instance.client;
      
      // Update instructor_payments or payments table
      await client.from('instructor_payments').insert({
        'instructor_id': instructorId,
        'pupil_id': pupilId,
        'type': 'income',
        'amount': amount,
        'payment_method': paymentMethod,
        'status': 'completed',
        'payment_date': DateTime.now().toIso8601String(),
        'description': 'Direct payment processed via $paymentMethod',
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check subscription status of an instructor
  Future<bool> checkSubscriptionStatus(String instructorId) async {
    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('instructor_subscriptions')
          .select('status, end_date')
          .eq('instructor_id', instructorId)
          .maybeSingle();

      if (response == null) return false;

      final status = response['status'] as String?;
      final endDateStr = response['end_date'] as String?;
      
      if (status == 'active' || status == 'trial') {
        if (endDateStr != null) {
          final endDate = DateTime.tryParse(endDateStr);
          if (endDate != null && endDate.isAfter(DateTime.now())) {
            return true;
          }
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
