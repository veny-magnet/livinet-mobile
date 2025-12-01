import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/fcm_service.dart';
import 'core/config/environment.dart';
import 'core/config/app_config.dart';
import 'core/services/token_refresh_service.dart';
import 'core/services/app_logger.dart';
import 'core/monitoring/monitoring_service.dart';
import 'core/services/session_manager.dart';
import 'core/widgets/user_interaction_tracker.dart';

// Skip SSL verification ONLY for banner image loading from honeycomb
class _BannerHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        if (host.contains('honeycomb.mybati.co.id')) {
          return true;
        }
        return false;
      };
  }
}

void main() async {
  // Apply SSL override hanya untuk honeycomb banner domain
  HttpOverrides.global = _BannerHttpOverrides();

  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Load environment variables from .env file
      await dotenv.load(fileName: ".env");

      // Initialize environment configuration
      await AppEnvironment.instance.init();

      // Initialize logger
      AppLogger.instance.initialize();
      AppLogger.instance.info('App starting...');
      AppLogger.instance.info('OpenAI API configured from .env');

      // Initialize Firebase
      await Firebase.initializeApp();
      AppLogger.instance.info('Firebase initialized');

      // Initialize Firebase Crashlytics
      if (AppConfig.instance.isCrashlyticsEnabled) {
        FlutterError.onError =
            FirebaseCrashlytics.instance.recordFlutterFatalError;
        AppLogger.instance.info('Crashlytics enabled');
      }

      // Initialize FCM service (legacy - consider deprecating)
      await FcmService.initialize();
      AppLogger.instance.info('FCM service initialized');

      // Initialize token refresh service
      await TokenRefreshService.instance.initialize();
      AppLogger.instance.info('Token refresh service initialized');

      // Initialize monitoring service (Sentry + Analytics)
      final sentryDsn = AppConfig.instance.sentryDsn;
      if (sentryDsn.isNotEmpty) {
        await MonitoringService.instance.initialize(
          sentryDsn: sentryDsn,
          environment: AppConfig.instance.environment,
        );
        AppLogger.instance.info('Monitoring service initialized');
      } else {
        AppLogger.instance.info('Monitoring service skipped (no Sentry DSN)');
      }

      AppLogger.instance.info('App initialization complete');
      runApp(const MyApp());
    },
    (error, stack) {
      // Catch errors outside of Flutter framework
      AppLogger.instance.fatal('Uncaught error', error, stack);
    },
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final SessionManager _sessionManager = SessionManager.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sessionManager.cleanup();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Cache sync removed - no longer needed
    if (state == AppLifecycleState.resumed) {
      // Check session validity when app resumes
      _checkSessionOnResume();
    }
  }

  Future<void> _checkSessionOnResume() async {
    final isValid = await _sessionManager.isSessionValid();
    if (!isValid) {
      _sessionManager.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sessionManager.setContext(context);
    });

    return UserInteractionTracker(
      child: MaterialApp.router(
        title: 'Livinet',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
