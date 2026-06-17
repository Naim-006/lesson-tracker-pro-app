import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_colors.dart';

class AppAuthException implements Exception {
  final String message;
  final String code;
  const AppAuthException(this.code, this.message);

  static AppAuthException fromSupabase(dynamic error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('user already registered') || msg.contains('already exists')) {
      return const AppAuthException('email_exists', 'An account with this email already exists. Try logging in instead.');
    }
    if (msg.contains('invalid login credentials') || msg.contains('wrong password')) {
      return const AppAuthException('invalid_credentials', 'Incorrect email or password. Please try again.');
    }
    if (msg.contains('email not confirmed') || msg.contains('email_not_confirmed')) {
      return const AppAuthException('email_unconfirmed', 'Please verify your email address before logging in. Check your inbox for the confirmation link.');
    }
    if (msg.contains('rate limit') || msg.contains('too many')) {
      return const AppAuthException('rate_limit', 'Too many attempts. Please wait a moment before trying again.');
    }
    if (msg.contains('smtp') || msg.contains('send') && msg.contains('email')) {
      return const AppAuthException('send_failed', 'Failed to send the email. Please try again later or contact support.');
    }
    if (msg.contains('link expired') || msg.contains('token expired')) {
      return const AppAuthException('expired', 'This link has expired. Please request a new one.');
    }
    if (msg.contains('invalid email') || msg.contains('malformed')) {
      return const AppAuthException('bad_email', 'Please enter a valid email address.');
    }
    if (msg.contains('weak password') || msg.contains('password should be')) {
      return const AppAuthException('weak_password', 'Password must be at least 6 characters long.');
    }
    if (msg.contains('network') || msg.contains('connection') || msg.contains('timeout')) {
      return const AppAuthException('network', 'Unable to connect. Please check your internet connection.');
    }
    return AppAuthException('unknown', msg.isNotEmpty ? msg : 'Something went wrong. Please try again.');
  }
}

String userFriendlyError(dynamic error) {
  if (error is AppAuthException) return error.message;
  if (error is Map && error.containsKey('message')) return error['message'];
  final msg = error.toString();
  if (msg.toLowerCase().contains('user already registered')) {
    return 'An account with this email already exists. Try logging in.';
  }
  if (msg.toLowerCase().contains('invalid login credentials')) {
    return 'Incorrect email or password. Please try again.';
  }
  if (msg.toLowerCase().contains('email not confirmed')) {
    return 'Please verify your email before logging in. Check your inbox.';
  }
  if (msg.contains('rate limit') || msg.toLowerCase().contains('too many requests')) {
    return 'Too many attempts. Please wait a moment and try again.';
  }
  if (msg.contains('smtp') || (msg.toLowerCase().contains('send') && msg.toLowerCase().contains('email'))) {
    return 'Failed to send email. Try again later.';
  }
  if (msg.toLowerCase().contains('weak password') || msg.toLowerCase().contains('password should be')) {
    return 'Password must be at least 6 characters long.';
  }
  if (msg.toLowerCase().contains('timeout') || msg.toLowerCase().contains('connection')) {
    return 'Unable to connect to the server. Check your internet.';
  }
  return 'Something went wrong. Please try again.';
}

void showSuccess(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
        ],
      ),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ),
  );
}

void showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
        ],
      ),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 4),
    ),
  );
}

Future<void> showLoadingDialog(BuildContext context, String message) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      content: Row(
        children: [
          const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 20),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 14))),
        ],
      ),
    ),
  );
}

Future<bool> checkEmailExists(String email) async {
  try {
    await Supabase.instance.client.auth.signInWithPassword(email: email, password: '_check_only_');
  } catch (e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('invalid login credentials')) return true;
    if (msg.contains('email not confirmed')) return true;
    if (msg.contains('user already registered')) return true;
  }
  return false;
}
