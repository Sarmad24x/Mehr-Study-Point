
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/hive_service.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'widgets/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services in parallel for better startup performance
  await Future.wait([
    Hive.initFlutter(),
    _initializeFirebase(),
  ]);

  // Initialize Hive Service
  final hiveService = HiveService();
  await hiveService.init();

  runApp(const ProviderScope(
    child: MyApp(),
  ));
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp();
    debugPrint("Firebase initialized successfully");
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }
}

final showSplashProvider = StateProvider<bool>((ref) => true);

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final showSplash = ref.watch(showSplashProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mehr Study Point',
      themeMode: themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: showSplash
          ? SplashScreen(
              onPressed: () => ref.read(showSplashProvider.notifier).state = false,
            )
          : const AuthGate(),
    );
  }
}
