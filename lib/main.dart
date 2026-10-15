import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:algohary_project/l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/presentation/pages/splash_screen.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:algohary_project/core/network/firebase_config.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'core/bloc/location_bloc/location_bloc.dart';
import 'core/bloc/location_bloc/location_event.dart';
import 'core/bloc/settings_cubit/settings_cubit.dart';
import 'core/bloc/settings_cubit/settings_state.dart';
import 'features/subscriptions/data/repositories/subscription_repository.dart';
import 'features/subscriptions/presentation/bloc/subscription_bloc.dart';

import 'firebase_options.dart';

import 'dart:async';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('Caught Flutter Error: ${details.exception}');
    };

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      // Configure Firestore Named Database 'algohary' settings
      final firestore = FirebaseConfig.firestore;
      
      if (!kIsWeb) {
        firestore.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
        debugPrint('✅ Firebase Firestore [algohary] persistence enabled.');
      }
    } catch (e, stack) {
      debugPrint('❌ Firebase init error: $e');
      debugPrint('$stack');
    }

    runApp(
      DevicePreview(
        enabled: kIsWeb,
        builder: (context) => const MyApp(),
      ),
    );
  }, (error, stack) {
    debugPrint('Uncaught Zone Error: $error');
    debugPrint('$stack');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          lazy: false,
          create: (_) => AuthBloc(
            authRepository: AuthRepository(),
          )..add(CheckAuthStatus()),
        ),
        BlocProvider(
          create: (_) => LocationBloc()..add(LoadSavedLocation()),
        ),
        BlocProvider(create: (_) => SettingsCubit()),
        BlocProvider(
          create: (_) => SubscriptionBloc(
            repository: SubscriptionRepository(),
          ),
        ),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settingsState) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Al Gohary',
            locale: settingsState.locale,
            builder: DevicePreview.appBuilder,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('ar'),
            ],
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settingsState.themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
