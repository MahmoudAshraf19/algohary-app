import 'package:flutter/material.dart';
import '../widgets/algohary_bottom_nav_bar.dart';

// Placeholder imports for the 5 tabs
import 'tabs/home_tab.dart';
import 'tabs/bookings_tab.dart';
import 'tabs/messages_tab.dart';
import 'tabs/profile_tab.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/pages/login_screen.dart';

import 'package:algohary_project/features/location/presentation/widgets/location_bottom_sheet.dart';
import 'package:algohary_project/core/bloc/location_bloc/location_bloc.dart';
import 'package:algohary_project/core/bloc/location_bloc/location_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkAndShowLocationPrompt();
  }

  Future<void> _checkAndShowLocationPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    final hasShown = prefs.getBool('has_shown_location_prompt') ?? false;

    if (!hasShown) {
      if (!mounted) return;
      final locationState = context.read<LocationBloc>().state;
      if (locationState is LocationInitial) {
        // Wait for the build to finish before showing bottom sheet
        WidgetsBinding.instance.addPostFrameCallback((_) {
          LocationBottomSheet.show(context);
        });
        await prefs.setBool('has_shown_location_prompt', true);
      }
    }
  }

  final List<Widget> _screens = [
    const HomeTab(),
    const BookingsTab(),
    const MessagesTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthInitial) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: AlgoharyBottomNavBar(
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
