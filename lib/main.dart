import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/providers/theme_provider.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/logger.dart';
import 'features/shell/app_shell.dart';
import 'features/auth/onboarding_screen.dart';
import 'features/pupil_portal/pupil_shell_v2.dart';
import 'features/admin/admin_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://ssnbzixjzwiovelgezwd.supabase.co',
    publishableKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNzbmJ6aXhqendpb3ZlbGdlendkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEyNTg1NDcsImV4cCI6MjA5NjgzNDU0N30.oQf7czBpeoBjcZ2_IqNDGidQ9hBjo3O2n8pLxGcWOQE',
  );
  
  // Set up global error handling
  FlutterError.onError = (details) {
    Logger.error('Flutter error', error: details.exception, stackTrace: details.stack);
  };
  
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Platform error handling can be added here if needed
  });
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  Logger.info('App starting');
  runApp(const ProviderScope(child: LessonTrackerProApp()));
}

class LessonTrackerProApp extends ConsumerWidget {
  const LessonTrackerProApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Lesson Tracker Pro',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _isLoading = true;
  bool _onboardingCompleted = false;

  @override
  void initState() {
    super.initState();
    _checkAuthAndOnboarding();
  }

  Future<void> _checkAuthAndOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      _onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
      
      // Check if user is logged in
      final currentUser = Supabase.instance.client.auth.currentUser;
      
      setState(() {
        _isLoading = false;
      });

      if (currentUser != null && _onboardingCompleted) {
        // User is logged in and onboarding completed, navigate to appropriate portal
        _navigateToPortal(currentUser);
      } else if (!_onboardingCompleted) {
        // Show onboarding
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      } else {
        // Show onboarding (user not logged in but onboarding completed)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    } catch (e) {
      Logger.error('Error checking auth', error: e);
      setState(() {
        _isLoading = false;
      });
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  void _navigateToPortal(dynamic currentUser) async {
    // Fetch user profile to determine role
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('role')
          .eq('id', currentUser.id)
          .single();

      if (!mounted) return;
      final role = response['role'] as String?;

      if (role == 'admin') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminShell()),
        );
      } else if (role == 'instructor') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AppShell()),
        );
      } else if (role == 'pupil') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PupilShell()),
        );
      } else {
        // Default to onboarding if role not found
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
      }
    } catch (e) {
      Logger.error('Error fetching user role', error: e);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : const SizedBox.shrink(),
    );
  }
}
