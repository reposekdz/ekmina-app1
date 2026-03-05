import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/rwanda_location.dart';
import 'core/services/notification_service.dart';
import 'core/services/fcm_service.dart';
import 'core/services/analytics_service.dart';
import 'core/services/secure_storage_service.dart';
import 'core/providers/language_provider.dart';
import 'presentation/routes/app_router.dart';
import 'core/localization/rw_localizations.dart';

final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 2,
    errorMethodCount: 8,
    lineLength: 120,
    colors: true,
    printEmojis: true,
    printTime: true,
  ),
);

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  logger.i('Background message received');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    await Hive.initFlutter();
    logger.i('💡 Hive initialized successfully');

    await RwandaLocation.initialize();
    logger.i('💡 Rwanda Location data loaded');

    try {
      // For Web, ensure you have initialized Firebase properly or handle it
      // If you're getting "FirebaseOptions cannot be null", it's usually because
      // DefaultFirebaseOptions.currentPlatform is not passed.
      // In this setup, we'll try to initialize but keep going if it fails.
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      logger.i('💡 Firebase initialized');
    } catch (e) {
      logger.w('⚠️ Firebase skipped or failed: $e');
    }

    try {
      await NotificationService().initialize();
      await FCMService.initialize(
        onMessageTap: (data) => _handleNotificationNavigation(data),
      );
      logger.i('💡 Services initialized');
    } catch (e) {
      logger.w('⚠️ Some services could not start: $e');
    }

    runApp(const ProviderScope(child: EKiminaApp()));
  } catch (e, stackTrace) {
    logger.e('❌ Critical initialization error', error: e, stackTrace: stackTrace);
    runApp(const ProviderScope(child: ErrorApp()));
  }
}

class EKiminaApp extends ConsumerWidget {
  const EKiminaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = AppRouter.router(ref);
    final language = ref.watch(languageProvider);

    return MaterialApp.router(
      title: 'E-Kimina Rwanda',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      locale: Locale(language),
      supportedLocales: const [
        Locale('rw', ''),
        Locale('en', ''),
        Locale('fr', ''),
      ],
      localizationsDelegates: const [
        RwMaterialLocalizationsDelegate(),
        RwCupertinoLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Ikosa ritunguranye', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => SystemNavigator.pop(),
                  child: const Text('Funga'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _handleNotificationNavigation(Map<String, dynamic> data) {
  logger.i('Notification tapped: $data');
}
