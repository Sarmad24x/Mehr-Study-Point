import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/hive_service.dart';
import 'screens/auth/login_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/service_providers.dart';
import 'providers/theme_provider.dart';
import 'widgets/main_navigation.dart';
import 'screens/splash_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();

  try {
    // Initialize Firebase
    await Firebase.initializeApp();
    debugPrint("Firebase initialized successfully");
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  // Initialize Hive Service
  final hiveService = HiveService();
  await hiveService.init();

  runApp(const ProviderScope(
    child: MyApp(),
  ));
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
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          primary: Colors.blue.shade800,
          background: Colors.grey[50],
        ),
        scaffoldBackgroundColor: Colors.grey[50],
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      home: showSplash 
          ? SplashScreen(onPressed: () => ref.read(showSplashProvider.notifier).state = false)
          : const AuthChecker(),
    );
  }
}

class AuthChecker extends ConsumerWidget {
  const AuthChecker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          return const ProfileLoader();
        }
        return const LoginScreen();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, stack) => Scaffold(
        body: Center(child: Text('Auth Error: $e')),
      ),
    );
  }
}

class ProfileLoader extends ConsumerWidget {
  const ProfileLoader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider);

    return userProfile.when(
      data: (profile) {
        if (profile == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profile Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('User logged in but profile not found in Firestore.'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => ref.read(authServiceProvider).signOut(),
                    child: const Text('Sign Out'),
                  ),
                ],
              ),
            ),
          );
        }
        return const MainNavigation();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Profile Loading Error: $e')),
      ),
    );
  }
}
