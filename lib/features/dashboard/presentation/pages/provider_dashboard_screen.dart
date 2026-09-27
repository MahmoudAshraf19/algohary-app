import 'package:flutter/material.dart';
import 'package:algohary_project/l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/pages/login_screen.dart';
import '../../../notifications/data/services/notification_service.dart';

import '../widgets/provider_bottom_nav_bar.dart';

// Provider Tabs
import 'tabs/provider/provider_home_tab.dart';
import 'tabs/provider/provider_orders_tab.dart';
import 'tabs/provider/provider_messages_tab.dart';
import 'tabs/provider/provider_settings_tab.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ProviderHomeTab(),
    const ProviderOrdersTab(),
    const ProviderMessagesTab(),
    const ProviderSettingsTab(),
  ];

  @override
  void initState() {
    super.initState();
    // Show welcome back message after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AuthBloc>().state;
      if (state is AuthSuccess && mounted) {
        final l10n = AppLocalizations.of(context);
        if (l10n != null) {
          NotificationService().showWelcomeNotification(
            l10n.appTitle, // Title: Al Gohary
            l10n.welcomeBackProvider, // Body: Welcome back...
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthInitial) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen(isProvider: true)),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: ProviderBottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}
