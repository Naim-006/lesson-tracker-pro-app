import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

import '../../core/theme/app_colors.dart';
import '../../core/utils/error_handler.dart';
import '../shell/app_shell.dart';
import 'subscription_intro_screen.dart';

class InstructorAuthScreen extends StatefulWidget {
  const InstructorAuthScreen({super.key});

  @override
  State<InstructorAuthScreen> createState() => _InstructorAuthScreenState();
}

class _InstructorAuthScreenState extends State<InstructorAuthScreen> {
  bool _isLogin = true;
  bool _showForgotPassword = false;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _forgotEmailController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _saveLogin = false;
  String? _errorMessage;
  String? _successMessage;
  final _secureStorage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();
  bool _biometricAvailable = false;
  bool _hasSavedCredentials = false;

  @override
  void initState() {
    super.initState();
    _checkSavedCredentials();
  }

  Future<void> _checkSavedCredentials() async {
    try {
      final email = await _secureStorage.read(key: 'instructor_email');
      final password = await _secureStorage.read(key: 'instructor_password');
      if (email != null && password != null && email.isNotEmpty && password.isNotEmpty) {
        setState(() {
          _emailController.text = email;
          _passwordController.text = password;
          _hasSavedCredentials = true;
          _saveLogin = true;
        });
        _checkBiometric();
      }
    } catch (_) {}
  }

  Future<void> _checkBiometric() async {
    try {
      final available = await _localAuth.canCheckBiometrics;
      final enrolled = await _localAuth.isDeviceSupported();
      setState(() => _biometricAvailable = available && enrolled);
    } catch (_) {
      setState(() => _biometricAvailable = false);
    }
  }

  Future<void> _authenticateWithBiometric() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Sign in to your instructor account',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (authenticated && mounted) {
        _handleSubmit(skipValidation: true);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _forgotEmailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit({bool skipValidation = false}) async {
    if (_showForgotPassword) {
      await _handleForgotPassword();
      return;
    }
    if (!skipValidation && !_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; _errorMessage = null; _successMessage = null; });

    try {
      if (_isLogin) {
        await _login();
      } else {
        await _signup();
      }
    } on AppAuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      final err = AppAuthException.fromSupabase(e);
      setState(() => _errorMessage = err.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();

    final response = await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: _passwordController.text,
    );

    if (response.user == null) {
      throw const AppAuthException('unknown', 'Unable to sign in. Please try again.');
    }

    if (response.user!.emailConfirmedAt == null) {
      await Supabase.instance.client.auth.signOut();
      throw const AppAuthException('email_unconfirmed', 'Please verify your email address before logging in. Check your inbox for the confirmation link.');
    }

    final profileResponse = await Supabase.instance.client
        .from('profiles')
        .select('role')
        .eq('id', response.user!.id)
        .single();

    if (profileResponse['role'] != 'instructor') {
      await Supabase.instance.client.auth.signOut();
      throw AppAuthException('wrong_role', 'This account is not registered as an instructor. Please sign up as an instructor.');
    }

    if (_saveLogin) {
      await _secureStorage.write(key: 'instructor_email', value: email);
      await _secureStorage.write(key: 'instructor_password', value: _passwordController.text);
    } else {
      await _secureStorage.delete(key: 'instructor_email');
      await _secureStorage.delete(key: 'instructor_password');
    }

    if (mounted) {
      final hasSubscription = await _checkSubscription(response.user!.id);
      if (!mounted) return;
      if (hasSubscription) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AppShell()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SubscriptionIntroScreen()));
      }
    }
  }

  Future<bool> _checkSubscription(String userId) async {
    try {
      final sub = await Supabase.instance.client
          .from('instructor_subscriptions')
          .select('id')
          .eq('instructor_id', userId)
          .maybeSingle();
      return sub != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> _signup() async {
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    final phoneCheck = await Supabase.instance.client
        .from('profiles')
        .select('id')
        .eq('phone', phone)
        .maybeSingle();
    if (phoneCheck != null) {
      throw const AppAuthException('phone_taken', 'This phone number is already registered with another account.');
    }

    final response = await Supabase.instance.client.auth.signUp(
      email: email,
      password: _passwordController.text,
      data: {
        'full_name': _fullNameController.text.trim(),
        'role': 'instructor',
        'phone': phone,
      },
    );

    if (response.user != null) {
      try {
        await Supabase.instance.client.from('instructors').insert({
          'id': response.user!.id,
          'phone': phone,
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}

      if (mounted) {
        setState(() {
          _isLogin = true;
          _errorMessage = null;
          _successMessage = 'Account created! A verification email has been sent to $email. Please check your inbox and verify your email before logging in.';
        });
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _forgotEmailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; _successMessage = null; });

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      setState(() {
        _successMessage = 'If an account exists with $email, a password reset link has been sent. Check your inbox (and spam folder).';
        _showForgotPassword = false;
      });
    } on AppAuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      final err = AppAuthException.fromSupabase(e);
      if (err.code == 'send_failed') {
        setState(() => _errorMessage = 'We couldn\'t send the reset email. Please try again later or contact support.');
      } else {
        setState(() => _errorMessage = err.message);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number is required';
    final cleaned = value.trim().replaceAll(' ', '');
    if (!RegExp(r'^(\+44|0)[0-9]{10}$').hasMatch(cleaned) &&
        !RegExp(r'^07[0-9]{9}$').hasMatch(cleaned)) {
      return 'Enter a valid UK phone number';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_showForgotPassword ? 'Reset Password' : (_isLogin ? 'Instructor Login' : 'Instructor Signup')),
        backgroundColor: AppColors.sunsetBright,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _showForgotPassword ? _buildForgotPasswordForm() : _buildAuthForm(),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          Icon(Icons.lock_reset, size: 80, color: AppColors.sunsetBright),
          const SizedBox(height: 24),
          Text('Reset Your Password', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Enter your email address and we\'ll send you a link to reset your password.',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                const Icon(Icons.error, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 14))),
              ]),
            ),
            const SizedBox(height: 16),
          ],
          if (_successMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(_successMessage!, style: const TextStyle(color: Colors.green, fontSize: 14))),
              ]),
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: _forgotEmailController,
            decoration: const InputDecoration(
              labelText: 'Email Address',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: _isLoading ? null : _handleForgotPassword,
              style: FilledButton.styleFrom(backgroundColor: AppColors.sunsetBright, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                  : Text('Send Reset Link', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => setState(() { _showForgotPassword = false; _errorMessage = null; _successMessage = null; }),
            child: Text('Back to Login', style: GoogleFonts.poppins(color: AppColors.sunsetBright)),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Icon(Icons.school, size: 80, color: AppColors.sunsetBright),
          const SizedBox(height: 24),
          Text(
            _isLogin ? 'Welcome Back' : 'Create Instructor Account',
            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _isLogin ? 'Sign in to manage your driving school' : 'Join Lesson Tracker Pro as an instructor',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (!_isLogin) ...[
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your full name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone), border: OutlineInputBorder(), hintText: '07123 456789'),
              keyboardType: TextInputType.phone,
              validator: _validatePhone,
            ),
            const SizedBox(height: 16),
          ],
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email), border: OutlineInputBorder()),
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Please enter your email';
              if (!v.contains('@')) return 'Please enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            obscureText: _obscurePassword,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter a password';
              if (v.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
          ),
          const SizedBox(height: 16),
          if (!_isLogin) ...[
            TextFormField(
              controller: _confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              obscureText: _obscureConfirm,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please confirm your password';
                if (v != _passwordController.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],
          if (_isLogin) ...[
            Row(
              children: [
                SizedBox(
                  height: 24, width: 24,
                  child: Checkbox(
                    value: _saveLogin,
                    onChanged: (v) => setState(() => _saveLogin = v ?? false),
                    activeColor: AppColors.sunsetBright,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _saveLogin = !_saveLogin),
                  child: Text('Save login on this device', style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600])),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (_isLogin && _hasSavedCredentials && _biometricAvailable) ...[
            SizedBox(
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _authenticateWithBiometric,
                icon: const Icon(Icons.fingerprint),
                label: Text('Sign in with biometric', style: GoogleFonts.poppins(color: AppColors.sunsetBright)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.sunsetBright.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                const Icon(Icons.error, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 14))),
              ]),
            ),
            const SizedBox(height: 16),
          ],
          if (_successMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(_successMessage!, style: const TextStyle(color: Colors.green, fontSize: 14))),
              ]),
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: _isLoading ? null : () => _handleSubmit(),
              style: FilledButton.styleFrom(backgroundColor: AppColors.sunsetBright, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                  : Text(_isLogin ? 'Login' : 'Sign Up', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          if (_isLogin) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() { _showForgotPassword = true; _errorMessage = null; _successMessage = null; }),
              child: Text('Forgot password?', style: GoogleFonts.poppins(color: AppColors.sunsetBright, fontSize: 13)),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_isLogin ? "Don't have an account? " : 'Already have an account? ', style: GoogleFonts.poppins(color: Colors.grey[600])),
              TextButton(
                onPressed: () => setState(() { _isLogin = !_isLogin; _errorMessage = null; _successMessage = null; }),
                child: Text(_isLogin ? 'Sign Up' : 'Login', style: GoogleFonts.poppins(color: AppColors.sunsetBright, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
