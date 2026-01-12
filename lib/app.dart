import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/auth_provider.dart';
import 'screens/sign_in_screen.dart';
import 'screens/home_screen.dart';

class SmplTrackerApp extends ConsumerWidget {
  const SmplTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'smpl tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A1A2E),
          brightness: Brightness.light,
        ),
      ),
      home: authState.when(
        data: (user) {
          if (user == null) {
            return const SignInScreen();
          }
          return const HomeScreen();
        },
        loading: () => const Scaffold(
          backgroundColor: Color(0xFFF7F8FA),
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, stack) => Scaffold(
          backgroundColor: const Color(0xFFF7F8FA),
          body: Center(
            child: Text('Error: $error'),
          ),
        ),
      ),
    );
  }
}
