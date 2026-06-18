import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/error_handler.dart';
import '../admin/admin_shell.dart';

class AdminAuthScreen extends StatefulWidget {
  const AdminAuthScreen({super.key});

  @override
  State<AdminAuthScreen> createState() => _AdminAuthScreenState();
}

class _AdminAuthScreenState extends State<AdminAuthScreen> {
  bool _showForgotPassword = false;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _forgotEmailController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _saveLogin = false;
  String? _errorMessage;
  String? _successMessage;
  final _secureStorage = const FlutterSecureStorage();
  bool _hasSavedCredentials = false;

  @override
  void initState() {
    super.initState();
    _checkSavedCredentials();
  }

  Future<void> _checkSavedCredentials() async {
    try {
      final email = await _secureStorage.read(key: 'admin_email');
      final password = await _secureStorage.read(key: 'admin_password');
      if (email != null && password != null && email.isNotEmpty && password.isNotEmpty) {
        setState(() {
          _emailController.text = email;
          _passwordController.text = password;
          _hasSavedCredentials = true;
          _saveLogin = true;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _forgotEmailController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; _errorMessage = null; _successMessage = null; });

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
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

      if (profileResponse['role'] != 'admin') {
        await Supabase.instance.client.auth.signOut();
        throw const AppAuthException('wrong_role', 'This account is not registered as an admin.');
      }

      if (_saveLogin) {
        await _secureStorage.write(key: 'admin_email', value: _emailController.text.trim());
        await _secureStorage.write(key: 'admin_password', value: _passwordController.text);
      } else {
        await _secureStorage.delete(key: 'admin_email');
        await _secureStorage.delete(key: 'admin_password');
      }

      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminShell()));
      }
    } on AppAuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = AppAuthException.fromSupabase(e).message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        _successMessage = 'If an account exists with $email, a password reset link has been sent.';
        _showForgotPassword = false;
      });
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
        title: Text(_showForgotPassword ? 'Reset Password' : 'Admin Login'),
        backgroundColor: AppColors.navy,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _showForgotPassword ? _buildForgotPasswordForm() : _buildLoginForm(),
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
          Icon(Icons.lock_reset, size: 80, color: AppColors.navy),
          const SizedBox(height: 24),
          Text('Reset Password', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Enter your email to receive a password reset link.', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          _buildMessage(),
          TextFormField(
            controller: _forgotEmailController,
            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email), border: OutlineInputBorder()),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: _isLoading ? null : _handleForgotPassword,
              style: FilledButton.styleFrom(backgroundColor: AppColors.navy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                  : Text('Send Reset Link', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => setState(() { _showForgotPassword = false; _errorMessage = null; _successMessage = null; }),
            child: Text('Back to Login', style: GoogleFonts.poppins(color: AppColors.navy)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Icon(Icons.admin_panel_settings, size: 80, color: AppColors.navy),
          const SizedBox(height: 24),
          Text('Admin Login', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Sign in to manage the platform', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]), textAlign: TextAlign.center),
          const SizedBox(height: 32),
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
              return null;
            },
          ),
          const SizedBox(height: 16),
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
          _buildMessage(),
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: _isLoading ? null : _login,
              style: FilledButton.styleFrom(backgroundColor: AppColors.navy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                  : Text('Login', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() { _showForgotPassword = true; _errorMessage = null; _successMessage = null; }),
            child: Text('Forgot password?', style: GoogleFonts.poppins(color: AppColors.navy, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage() {
    if (_errorMessage != null) {
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
    if (_successMessage != null) {
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
    return const SizedBox.shrink();
  }
}
