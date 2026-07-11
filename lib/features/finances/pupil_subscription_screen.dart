import 'dart:async'; // <-- added for StreamSubscription

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_colors.dart';

class PupilSubscriptionScreen extends StatefulWidget {
  const PupilSubscriptionScreen({super.key});

  @override
  State<PupilSubscriptionScreen> createState() => _PupilSubscriptionScreenState();
}

class _PupilSubscriptionScreenState extends State<PupilSubscriptionScreen> {
  // Static map to remember verified users during the current app session
  static final Map<String, bool> _verifiedUsers = {};

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEnabled = false;
  bool _agreedToTerms = false;
  bool _isEditing = false;

  Map<String, dynamic> _methods = <String, dynamic>{};

  static const _allMethods = [
    'bank_transfer', 'paypal', 'revolut', 'monzo', 'starling',
  ];

  static const _methodLabels = <String, String>{
    'bank_transfer': 'Bank Transfer',
    'paypal': 'PayPal',
    'revolut': 'Revolut',
    'monzo': 'Monzo',
    'starling': 'Starling Bank',
  };

  static const _methodIcons = <String, IconData>{
    'bank_transfer': Icons.account_balance_outlined,
    'paypal': Icons.account_balance_wallet_outlined,
    'revolut': Icons.currency_exchange_outlined,
    'monzo': Icons.credit_card_outlined,
    'starling': Icons.savings_outlined,
  };

  static const _methodSubtitles = <String, String>{
    'bank_transfer': 'Sort Code + Account Number',
    'paypal': 'Email address',
    'revolut': 'Revtag, phone, or bank details',
    'monzo': 'Sort Code + Account Number or payment link',
    'starling': 'Sort Code + Account Number',
  };

  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Clear verification cache on sign-out
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedOut) {
        _verifiedUsers.clear();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Widget _termsBullet(bool isDark, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('\u2022 ', style: TextStyle(fontSize: 11, color: AppColors.warning)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                height: 1.3,
                color: isDark ? Colors.white.withValues(alpha: 0.45) : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.description_outlined, size: 20, color: AppColors.sunsetBright),
            const SizedBox(width: 8),
            const Text('Terms & Conditions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogSection('1. Payment Information Storage',
                  'Any payment details you provide will be stored securely in our encrypted database. '
                  'We use industry-standard security measures to protect your data.'),
              _dialogSection('2. Information Sharing',
                  'Your enabled payment methods will be visible to your assigned pupils within the app. '
                  'This allows them to send lesson payments directly to you.'),
              _dialogSection('3. Your Responsibility',
                  'You are solely responsible for ensuring your payment details are accurate and up to date. '
                  'We are not liable for any payments sent to incorrect or outdated information.'),
              _dialogSection('4. Transaction Liability',
                  'All transactions between you and your pupils are handled independently outside this platform. '
                  'We do not process, guarantee, or mediate any payments.'),
              _dialogSection('5. Data Control',
                  'You can edit or delete your payment information at any time from the Pupil Payments settings screen. '
                  'Deleted data will no longer be visible to pupils.'),
              _dialogSection('6. Consent',
                  'By agreeing to these terms, you consent to the storage and display of your payment details as described above. '
                  'You may withdraw consent at any time by removing your payment information.'),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(backgroundColor: AppColors.sunsetBright),
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }

  Widget _dialogSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.4)),
        ],
      ),
    );
  }

  Future<void> _loadData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final existing = await Supabase.instance.client
          .from('instructor_payment_info')
          .select('methods')
          .eq('instructor_id', user.id)
          .maybeSingle();

      if (mounted) {
        if (existing != null && existing['methods'] != null) {
          final raw = existing['methods'] as Map;
          _methods = Map<String, dynamic>.from(raw);
          _isEnabled = true;
        } else {
          _methods = <String, dynamic>{};
          for (final m in _allMethods) {
            _methods[m] = <String, dynamic>{'enabled': false};
          }
        }
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleMethod(String key, bool enabled) {
    setState(() {
      _methods[key] ??= {};
      _methods[key]!['enabled'] = enabled;
    });
  }

  void _updateField(String method, String field, String value) {
    setState(() {
      _methods[method] ??= <String, dynamic>{};
      (_methods[method] as Map<String, dynamic>)[field] = value;
    });
  }

  bool get _hasAnyEnabled => _methods.values.any((m) => m['enabled'] == true);

  Future<bool> _verifyIdentity(String email) async {
    final otpController = TextEditingController();
    var otpSent = false;
    var isVerifying = false;
    String? error;

    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.shield_outlined, size: 22, color: AppColors.sunsetBright),
              SizedBox(width: 8),
              Expanded(child: Text('Verify Identity', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  otpSent
                      ? 'Enter the 8-digit verification code sent to $email'
                      : 'We\'ll send a verification code to $email to confirm your identity.',
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                ],
                if (otpSent) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: otpController,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    maxLength: 8,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.w700),
                    decoration: const InputDecoration(
                      counterText: '',
                      hintText: '--------',
                      hintStyle: TextStyle(letterSpacing: 8, fontSize: 24),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isVerifying ? null : () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            if (!otpSent)
              FilledButton(
                onPressed: isVerifying
                    ? null
                    : () async {
                        setDialogState(() { isVerifying = true; error = null; });
                        try {
                          await Supabase.instance.client.auth.signInWithOtp(email: email);
                          setDialogState(() { otpSent = true; isVerifying = false; });
                        } catch (e) {
                          setDialogState(() { error = 'Failed to send code. Try again.'; isVerifying = false; });
                        }
                      },
                style: FilledButton.styleFrom(backgroundColor: AppColors.sunsetBright),
                child: isVerifying
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Send Code'),
              ),
            if (otpSent)
              FilledButton(
                onPressed: isVerifying
                    ? null
                    : () async {
                        final code = otpController.text.trim();
                        if (code.length != 8) {
                          setDialogState(() => error = 'Enter a valid 8-digit code');
                          return;
                        }
                        setDialogState(() { isVerifying = true; error = null; });
                        try {
                          await Supabase.instance.client.auth.verifyOTP(
                            email: email,
                            token: code,
                            type: OtpType.email,
                          );
                          if (ctx.mounted) {
                            // Store verification in session cache
                            final user = Supabase.instance.client.auth.currentUser;
                            if (user != null) {
                              _verifiedUsers[user.id] = true;
                            }
                            Navigator.pop(ctx, true);
                          }
                        } catch (e) {
                          setDialogState(() { error = 'Invalid code. Try again.'; isVerifying = false; });
                        }
                      },
                style: FilledButton.styleFrom(backgroundColor: AppColors.sunsetBright),
                child: isVerifying
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Verify'),
              ),
          ],
        ),
      ),
    );

    otpController.dispose();
    return verified == true;
  }

  Future<void> _save() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || !_agreedToTerms || !_hasAnyEnabled) return;

    // Check session cache for verification
    if (!_verifiedUsers.containsKey(user.id) || _verifiedUsers[user.id] != true) {
      final verified = await _verifyIdentity(user.email ?? '');
      if (!verified) return;
    }

    setState(() => _isSaving = true);
    try {
      await Supabase.instance.client.from('instructor_payment_info').upsert({
        'instructor_id': user.id,
        'methods': _methods,
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        setState(() {
          _isSaving = false;
          _isEnabled = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment details saved'), backgroundColor: Color(0xFF166534), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _disable() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove all payment info?'),
        content: const Text('All saved payment methods will be permanently deleted. Pupils will no longer see how to pay you.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: AppColors.error), child: const Text('Remove all')),
        ],
      ),
    );
    if (confirmed != true) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('instructor_payment_info').delete().eq('instructor_id', user.id);
      if (mounted) {
        for (final m in _allMethods) {
          _methods[m] = <String, dynamic>{'enabled': false};
        }
        setState(() { _isEnabled = false; _agreedToTerms = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment info removed'), backgroundColor: Color(0xFF166534), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (_) {}
  }

  Future<void> _saveAndExitEdit() async {
    await _save();
    if (mounted) {
      setState(() => _isEditing = false);
    }
  }

  Future<void> _removeAndExitEdit() async {
    await _disable();
    if (mounted) {
      setState(() => _isEditing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF8F6F2),
      appBar: AppBar(
        title: const Text('Pupil Payments'),
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isDark),
                  const SizedBox(height: 16),
                  if (_isEditing) _buildEditScreen(isDark)
                  else if (_isEnabled) _buildActiveState(isDark)
                  else _buildSetupState(isDark),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isEnabled
              ? [AppColors.success.withValues(alpha: 0.08), AppColors.success.withValues(alpha: 0.03)]
              : [AppColors.sunsetBright.withValues(alpha: 0.08), AppColors.sunset.withValues(alpha: 0.03)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isEnabled
              ? AppColors.success.withValues(alpha: 0.2)
              : AppColors.sunsetBright.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _isEnabled ? AppColors.success.withValues(alpha: 0.12) : AppColors.sunsetBright.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isEnabled ? Icons.check_circle : Icons.info_outline,
              color: _isEnabled ? AppColors.success : AppColors.sunsetBright,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEnabled ? 'Payment Details Active' : 'How Pupils Pay You',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87),
                ),
                const SizedBox(height: 2),
                Text(
                  _isEnabled
                      ? 'Your pupils can see these payment methods'
                      : 'Choose one or more payment methods to share with your pupils',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white.withValues(alpha: 0.45) : Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupState(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select payment methods',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87),
        ),
        const SizedBox(height: 4),
        Text(
          'Enable as many as you like — pupils will see all enabled methods.',
          style: TextStyle(fontSize: 12, color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey.shade500),
        ),
        const SizedBox(height: 14),
        ..._allMethods.map((m) => _MethodCard(
          isDark: isDark,
          icon: _methodIcons[m]!,
          label: _methodLabels[m]!,
          subtitle: _methodSubtitles[m]!,
          enabled: _methods[m]?['enabled'] == true,
          onToggle: (v) => _toggleMethod(m, v),
          fields: _buildFieldsFor(m, isDark),
        )),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBg.withValues(alpha: 0.5) : const Color(0xFFFEFCE8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkBorder.withValues(alpha: 0.3) : const Color(0xFFFDE047).withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.description_outlined, size: 16, color: AppColors.warning),
                  const SizedBox(width: 6),
                  Text(
                    'Terms & Conditions',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'By enabling payment methods, you agree that:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 6),
              _termsBullet(isDark, 'Your payment details will be stored securely in our database.'),
              _termsBullet(isDark, 'They will be visible to your pupils so they can send you lesson payments.'),
              _termsBullet(isDark, 'You can edit or remove your details at any time from this screen.'),
              _termsBullet(isDark, 'We are not responsible for transactions made between you and your pupils.'),
              _termsBullet(isDark, 'It is your responsibility to keep your payment information accurate and up to date.'),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _agreedToTerms,
                      onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                      activeColor: AppColors.sunsetBright,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: _showTermsDialog,
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.4,
                            color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.grey.shade600,
                          ),
                          children: [
                            TextSpan(text: 'I have read and agree to the '),
                            TextSpan(
                              text: 'Terms & Conditions',
                              style: TextStyle(
                                color: AppColors.sunsetBright,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: (!_agreedToTerms || !_hasAnyEnabled || _isSaving) ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.sunsetBright,
              disabledBackgroundColor: AppColors.sunsetBright.withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSaving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save & Enable', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: TextButton(
            onPressed: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Payments your way'),
                content: const Text('Skip this for now. You can set up payment details anytime from this screen.'),
                actions: [
                  FilledButton(onPressed: () => Navigator.pop(ctx), style: FilledButton.styleFrom(backgroundColor: AppColors.sunsetBright), child: const Text('Got it')),
                ],
              ),
            ),
            child: Text(
              'I\'ll handle payments my way',
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey.shade600),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildFieldsFor(String method, bool isDark) {
    switch (method) {
      case 'bank_transfer':
        return [
          _Field(label: 'Account Holder Name', hint: 'e.g. John Smith', value: _methods[method]?['holder_name'] as String? ?? '', onChanged: (v) => _updateField(method, 'holder_name', v)),
          _Field(label: 'Sort Code', hint: 'e.g. 12-34-56', value: _methods[method]?['sort_code'] as String? ?? '', onChanged: (v) => _updateField(method, 'sort_code', v)),
          _Field(label: 'Account Number', hint: 'e.g. 12345678', value: _methods[method]?['account_number'] as String? ?? '', onChanged: (v) => _updateField(method, 'account_number', v)),
          _Field(label: 'Reference', hint: 'e.g. LESSON-NAME (optional)', value: _methods[method]?['reference'] as String? ?? '', onChanged: (v) => _updateField(method, 'reference', v)),
        ];
      case 'paypal':
        return [
          _Field(label: 'PayPal Email', hint: 'e.g. john@example.com', value: _methods[method]?['email'] as String? ?? '', onChanged: (v) => _updateField(method, 'email', v)),
        ];
      case 'revolut':
        return [
          _Field(label: 'Revtag (username)', hint: 'e.g. @johnsmith', value: _methods[method]?['revtag'] as String? ?? '', onChanged: (v) => _updateField(method, 'revtag', v)),
          _Field(label: 'Phone Number', hint: 'e.g. 07123 456789', value: _methods[method]?['phone'] as String? ?? '', onChanged: (v) => _updateField(method, 'phone', v)),
          _Field(label: 'Sort Code', hint: 'e.g. 12-34-56', value: _methods[method]?['sort_code'] as String? ?? '', onChanged: (v) => _updateField(method, 'sort_code', v)),
          _Field(label: 'Account Number', hint: 'e.g. 12345678', value: _methods[method]?['account_number'] as String? ?? '', onChanged: (v) => _updateField(method, 'account_number', v)),
        ];
      case 'monzo':
        return [
          _Field(label: 'Sort Code', hint: 'e.g. 12-34-56', value: _methods[method]?['sort_code'] as String? ?? '', onChanged: (v) => _updateField(method, 'sort_code', v)),
          _Field(label: 'Account Number', hint: 'e.g. 12345678', value: _methods[method]?['account_number'] as String? ?? '', onChanged: (v) => _updateField(method, 'account_number', v)),
          _Field(label: 'Payment Link', hint: 'e.g. monzo.me/johnsmith (optional)', value: _methods[method]?['payment_link'] as String? ?? '', onChanged: (v) => _updateField(method, 'payment_link', v)),
        ];
      case 'starling':
        return [
          _Field(label: 'Sort Code', hint: 'e.g. 12-34-56', value: _methods[method]?['sort_code'] as String? ?? '', onChanged: (v) => _updateField(method, 'sort_code', v)),
          _Field(label: 'Account Number', hint: 'e.g. 12345678', value: _methods[method]?['account_number'] as String? ?? '', onChanged: (v) => _updateField(method, 'account_number', v)),
        ];
      default:
        return [];
    }
  }

  Widget _buildActiveState(bool isDark) {
    final enabledMethods = _allMethods.where((m) => _methods[m]?['enabled'] == true).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${enabledMethods.length} method${enabledMethods.length == 1 ? '' : 's'} enabled',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...enabledMethods.map((m) => _buildMethodPreview(m, isDark)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final user = Supabase.instance.client.auth.currentUser;
                    if (user == null) return;
                    // Check session cache
                    bool alreadyVerified = _verifiedUsers.containsKey(user.id) && _verifiedUsers[user.id] == true;
                    if (alreadyVerified) {
                      if (mounted) {
                        setState(() {
                          _isEditing = true;
                          _agreedToTerms = true;
                        });
                      }
                    } else {
                      final verified = await _verifyIdentity(user.email ?? '');
                      if (verified && mounted) {
                        setState(() {
                          _isEditing = true;
                          _agreedToTerms = true;
                        });
                      }
                    }
                  },
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit Payment Info'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.sunsetBright,
                    side: const BorderSide(color: AppColors.sunsetBright),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditScreen(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Edit Payment Methods',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87),
        ),
        const SizedBox(height: 4),
        Text(
          'Update your payment information',
          style: TextStyle(fontSize: 12, color: isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey.shade500),
        ),
        const SizedBox(height: 14),
        ..._allMethods.map((m) => _MethodCard(
          isDark: isDark,
          icon: _methodIcons[m]!,
          label: _methodLabels[m]!,
          subtitle: _methodSubtitles[m]!,
          enabled: _methods[m]?['enabled'] == true,
          onToggle: (v) => _toggleMethod(m, v),
          fields: _buildFieldsFor(m, isDark),
        )),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: (!_agreedToTerms || !_hasAnyEnabled || _isSaving) ? null : _saveAndExitEdit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.sunsetBright,
              disabledBackgroundColor: AppColors.sunsetBright.withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSaving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _removeAndExitEdit,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Remove All Payment Methods', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ),
        ),
      ],
    );
  }

  Widget _buildMethodPreview(String method, bool isDark) {
    final data = (_methods[method] is Map) ? Map<String, dynamic>.from(_methods[method] as Map) : <String, dynamic>{};
    final details = _buildPreviewFields(method, data);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBg : const Color(0xFFF8F6F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkBorder.withValues(alpha: 0.5) : AppColors.lightBorder.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_methodIcons[method], size: 16, color: AppColors.sunsetBright),
              const SizedBox(width: 6),
              Text(
                _methodLabels[method]!,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? Colors.white : Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...details.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              '${e.key}: ${e.value}',
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white.withValues(alpha: 0.55) : Colors.grey.shade600),
            ),
          )),
        ],
      ),
    );
  }

  Map<String, String> _buildPreviewFields(String method, Map<String, dynamic> data) {
    switch (method) {
      case 'bank_transfer':
        return {
          if (data['holder_name'] != null && (data['holder_name'] as String).isNotEmpty) 'Name': data['holder_name'] as String,
          if (data['sort_code'] != null && (data['sort_code'] as String).isNotEmpty) 'Sort Code': data['sort_code'] as String,
          if (data['account_number'] != null && (data['account_number'] as String).isNotEmpty) 'Account': data['account_number'] as String,
          if (data['reference'] != null && (data['reference'] as String).isNotEmpty) 'Reference': data['reference'] as String,
        };
      case 'paypal':
        return {
          if (data['email'] != null && (data['email'] as String).isNotEmpty) 'PayPal': data['email'] as String,
        };
      case 'revolut':
        return {
          if (data['revtag'] != null && (data['revtag'] as String).isNotEmpty) 'Revtag': data['revtag'] as String,
          if (data['phone'] != null && (data['phone'] as String).isNotEmpty) 'Phone': data['phone'] as String,
          if (data['sort_code'] != null && (data['sort_code'] as String).isNotEmpty) 'Sort Code': data['sort_code'] as String,
          if (data['account_number'] != null && (data['account_number'] as String).isNotEmpty) 'Account': data['account_number'] as String,
        };
      case 'monzo':
        return {
          if (data['sort_code'] != null && (data['sort_code'] as String).isNotEmpty) 'Sort Code': data['sort_code'] as String,
          if (data['account_number'] != null && (data['account_number'] as String).isNotEmpty) 'Account': data['account_number'] as String,
          if (data['payment_link'] != null && (data['payment_link'] as String).isNotEmpty) 'Link': data['payment_link'] as String,
        };
      case 'starling':
        return {
          if (data['sort_code'] != null && (data['sort_code'] as String).isNotEmpty) 'Sort Code': data['sort_code'] as String,
          if (data['account_number'] != null && (data['account_number'] as String).isNotEmpty) 'Account': data['account_number'] as String,
        };
      default:
        return {};
    }
  }
}

class _MethodCard extends StatefulWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final String subtitle;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final List<Widget> fields;

  const _MethodCard({
    required this.isDark,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.enabled,
    required this.onToggle,
    required this.fields,
  });

  @override
  State<_MethodCard> createState() => _MethodCardState();
}

class _MethodCardState extends State<_MethodCard> {
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.enabled
            ? AppColors.sunsetBright.withValues(alpha: 0.06)
            : (widget.isDark ? AppColors.darkCard : Colors.white),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.enabled
              ? AppColors.sunsetBright.withValues(alpha: 0.3)
              : (widget.isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => widget.onToggle(!widget.enabled),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.enabled ? AppColors.sunsetBright.withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.enabled ? AppColors.sunsetBright : (widget.isDark ? Colors.white.withValues(alpha: 0.4) : Colors.grey.shade400),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: widget.enabled
                              ? AppColors.sunsetBright
                              : (widget.isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black87),
                        ),
                      ),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: widget.isDark ? Colors.white.withValues(alpha: 0.35) : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: widget.enabled,
                  onChanged: widget.onToggle,
                  activeTrackColor: AppColors.sunsetBright.withValues(alpha: 0.5),
                  activeThumbColor: AppColors.sunsetBright,
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(children: widget.fields),
            ),
            crossFadeState: widget.enabled ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatefulWidget {
  final String label;
  final String hint;
  final String value;
  final ValueChanged<String> onChanged;

  const _Field({
    required this.label,
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_Field> createState() => _FieldState();
}

class _FieldState extends State<_Field> {
  late TextEditingController _controller;
  bool _selfChanging = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _controller.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(_Field oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_selfChanging && widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    _selfChanging = true;
    widget.onChanged(_controller.text);
    _selfChanging = false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white.withValues(alpha: 0.5) : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white.withValues(alpha: 0.25) : Colors.grey.shade400,
              ),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: isDark ? AppColors.darkBorder.withValues(alpha: 0.4) : Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87),
          ),
        ],
      ),
    );
  }
}