import 'package:flutter/material.dart';
import 'package:algohary_project/l10n/app_localizations.dart';
import '../../../onboarding/presentation/pages/onboarding_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../dashboard/presentation/pages/dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait for splash animation (3 seconds)
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    var state = context.read<AuthBloc>().state;
    if (state is AuthLoading) {
      state = await context.read<AuthBloc>().stream.firstWhere(
        (s) => s is AuthSuccess || s is AuthInitial || s is AuthFailure,
      );
    }

    if (!mounted) return;
    if (state is AuthSuccess) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: [
              const Spacer(),
            // Logo and Title Section
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/icons/ic_splash.png',
                  width: 150,
                  height: 150,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.appTitle, // This will show "Al Gohary"
                  style: textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.primary, 
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    l10n.splashSubtitle,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.primary.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Bottom loading line (mimicking the gradient line in the mockup)
            Padding(
              padding: const EdgeInsets.only(bottom: 60.0),
              child: SizedBox(
                width: 50,
                height: 4,
                child: LinearProgressIndicator(
                  backgroundColor: colorScheme.secondary.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.secondary),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
