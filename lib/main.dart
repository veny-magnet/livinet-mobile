import 'dart:async';
import 'package:flutter/material.dart';
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
import 'core/services/push_notification_service.dart';

void main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize environment configuration
      await AppEnvironment.instance.init();

      // Initialize logger
      AppLogger.instance.initialize();
      AppLogger.instance.info('App starting...');

      // Initialize Firebase
      await Firebase.initializeApp();
      AppLogger.instance.info('Firebase initialized');

      // Initialize Firebase Crashlytics
      if (AppConfig.instance.isCrashlyticsEnabled) {
        FlutterError.onError =
            FirebaseCrashlytics.instance.recordFlutterFatalError;
        AppLogger.instance.info('Crashlytics enabled');
      }

      // Initialize Push Notification Service
      await PushNotificationService.instance.initialize();
      AppLogger.instance.info('Push Notification service initialized');

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Livinet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
    );
  }
}
