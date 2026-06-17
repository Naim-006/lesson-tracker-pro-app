import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/error_handler.dart';
import '../pupil_portal/pupil_shell.dart';

class PupilAuthScreen extends StatefulWidget {
  const PupilAuthScreen({super.key});

  @override
  State<PupilAuthScreen> createState() => _PupilAuthScreenState();
}

class _PupilAuthScreenState extends State<PupilAuthScreen> {
  bool _isLogin = true;
  bool _showForgotPassword = false;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _forgotEmailController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _emailNotConfirmed = false;
  DateTime? _lastResendTime;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _forgotEmailController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_showForgotPassword) {
      await _handleForgotPassword();
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; _errorMessage = null; _successMessage = null; _emailNotConfirmed = false; });

    try {
      if (_isLogin) { await _login(); } else { await _signup(); }
    } on AppAuthException catch (e) {
      setState(() => _errorMessage = e.message);
      if (e.code == 'email_unconfirmed') _emailNotConfirmed = true;
    } catch (e) {
      final err = AppAuthException.fromSupabase(e);
      setState(() => _errorMessage = err.message);
      if (err.code == 'email_unconfirmed') _emailNotConfirmed = true;
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
      throw const AppAuthException('email_unconfirmed', 'Please verify your email address before logging in.');
    }

    final profileResponse = await Supabase.instance.client
        .from('profiles')
        .select('role, email_verified')
        .eq('id', response.user!.id)
        .single();

    if (profileResponse['role'] != 'pupil') {
      await Supabase.instance.client.auth.signOut();
      throw const AppAuthException('wrong_role', 'This account is not registered as a pupil.');
    }

    if (profileResponse['email_verified'] != true) {
      await Supabase.instance.client.auth.signOut();
      throw const AppAuthException('email_unconfirmed', 'Please verify your email before logging in.');
    }

    try {
      final existingPupil = await Supabase.instance.client
          .from('pupils')
          .select('id')
          .eq('id', response.user!.id)
          .maybeSingle();
      if (existingPupil == null) {
        final invitation = await Supabase.instance.client
            .from('pupil_invitations')
            .select('instructor_id, first_name, last_name, phone, postcode')
            .eq('email', response.user!.email ?? '')
            .maybeSingle();
        if (invitation != null) {
          await Supabase.instance.client.from('pupils').insert({
            'id': response.user!.id,
            'instructor_id': invitation['instructor_id'],
            'email': response.user!.email ?? '',
            'first_name': invitation['first_name'] ?? '',
            'last_name': invitation['last_name'] ?? '',
            'phone': invitation['phone'] ?? '',
            'postcode': invitation['postcode'],
            'status': 'current',
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      }
    } catch (_) {}

    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PupilShell()));
    }
  }

  Future<void> _signup() async {
    final email = _emailController.text.trim().toLowerCase();

    final exists = await checkEmailExists(email);
    if (exists) {
      throw const AppAuthException('email_exists', 'An account with this email already exists. Try logging in instead.');
    }

    Map<String, dynamic> invitation;
    try {
      final result = await Supabase.instance.client
          .from('pupil_invitations')
          .select('id, instructor_id, first_name, last_name, phone, postcode')
          .eq('email', email)
          .or('status.eq.pending,status.eq.approved')
          .maybeSingle();

      if (result == null) {
        throw const AppAuthException('no_invitation', 'This email is not invited. Please contact your driving instructor to get an invitation link.');
      }
      invitation = result;
    } catch (e) {
      if (e is AppAuthException) rethrow;
      throw const AppAuthException('verification_failed', 'Could not verify your invitation. Please try again later.');
    }

    final response = await Supabase.instance.client.auth.signUp(
      email: email,
      password: _passwordController.text,
      data: {
        'full_name': _fullNameController.text.trim(),
        'role': 'pupil',
      },
    );

    if (response.user != null) {
      try {
        await Supabase.instance.client.from('pupils').insert({
          'id': response.user!.id,
          'instructor_id': invitation['instructor_id'],
          'email': email,
          'first_name': invitation['first_name'] ?? _fullNameController.text.trim().split(' ').first,
          'last_name': invitation['last_name'] ?? '',
          'phone': invitation['phone'] ?? '',
          'postcode': invitation['postcode'],
          'status': 'current',
          'created_at': DateTime.now().toIso8601String(),
        });

        await Supabase.instance.client
            .from('pupil_invitations')
            .update({ 'status': 'accepted', 'accepted_at': DateTime.now().toIso8601String() })
            .eq('id', invitation['id']);
      } catch (_) {}

      if (mounted) {
        setState(() {
          _isLogin = true;
          _successMessage = 'Account created! A verification email has been sent to $email. Please check your inbox.';
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
    } catch (e) {
      setState(() => _errorMessage = AppAuthException.fromSupabase(e).message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendVerification() async {
    if (_lastResendTime != null && DateTime.now().difference(_lastResendTime!).inSeconds < 60) {
      final remaining = 60 - DateTime.now().difference(_lastResendTime!).inSeconds;
      setState(() => _errorMessage = 'Please wait $remaining seconds before requesting another email.');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; _successMessage = null; });

    try {
      await Supabase.instance.client.auth.resend(type: OtpType.signup, email: _emailController.text.trim());
      _lastResendTime = DateTime.now();
      if (mounted) {
        setState(() { _successMessage = 'A new verification email has been sent to ${_emailController.text}. Check your inbox.'; });
      }
    } catch (e) {
      setState(() => _errorMessage = AppAuthException.fromSupabase(e).message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_showForgotPassword ? 'Reset Password' : (_isLogin ? 'Pupil Login' : 'Pupil Signup')),
        backgroundColor: Colors.blue,
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
          Icon(Icons.lock_reset, size: 80, color: Colors.blue),
          const SizedBox(height: 24),
          Text('Reset Your Password', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Enter your email to receive a password reset link.', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          _buildErrorMessage(),
          _buildSuccessMessage(),
          TextFormField(
            controller: _forgotEmailController,
            decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email), border: OutlineInputBorder()),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: _isLoading ? null : _handleForgotPassword,
              style: FilledButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                  : Text('Send Reset Link', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => setState(() { _showForgotPassword = false; _errorMessage = null; _successMessage = null; }),
            child: Text('Back to Login', style: GoogleFonts.poppins(color: Colors.blue)),
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
          Icon(Icons.person, size: 80, color: Colors.blue),
          const SizedBox(height: 24),
          Text(_isLogin ? 'Welcome Back' : 'Create Pupil Account', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(_isLogin ? 'Sign in to track your driving lessons' : 'Join Lesson Tracker Pro as a pupil',
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          if (!_isLogin) ...[
            TextFormField(
              controller: _fullNameController,
              decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person), border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your full name' : null,
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
              labelText: 'Password', prefixIcon: const Icon(Icons.lock), border: const OutlineInputBorder(),
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
                labelText: 'Confirm Password', prefixIcon: const Icon(Icons.lock_outline), border: const OutlineInputBorder(),
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
          _buildErrorMessage(),
          _buildSuccessMessage(),
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: _isLoading ? null : _handleSubmit,
              style: FilledButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                  : Text(_isLogin ? 'Login' : 'Sign Up', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          if (_isLogin) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() { _showForgotPassword = true; _errorMessage = null; _successMessage = null; }),
              child: Text('Forgot password?', style: GoogleFonts.poppins(color: Colors.blue, fontSize: 13)),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_isLogin ? "Don't have an account? " : 'Already have an account? ', style: GoogleFonts.poppins(color: Colors.grey[600])),
              TextButton(
                onPressed: () => setState(() { _isLogin = !_isLogin; _errorMessage = null; _successMessage = null; _emailNotConfirmed = false; }),
                child: Text(_isLogin ? 'Sign Up' : 'Login', style: GoogleFonts.poppins(color: Colors.blue, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    if (_errorMessage == null) return const SizedBox.shrink();
    return Column(children: [
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
    ]);
  }

  Widget _buildSuccessMessage() {
    if (_successMessage == null) return const SizedBox.shrink();
    return Column(children: [
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
    ]);
  }
}
