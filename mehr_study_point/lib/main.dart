import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://lrviyoxxxhratkyltcao.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxydml5b3h4eGhyYXRreWx0Y2FvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc4NTI3NTUsImV4cCI6MjA4MzQyODc1NX0.pOe4jL3JH32Axx2j6tT4GWgEcGZSjC-B3vLztin3M-U',
  );

  runApp(const ProviderScope(
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mehr Study Point',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Mehr Study Point'),
        ),
      ),
    );
  }
}

// Supabase client instance
final supabase = Supabase.instance.client;
