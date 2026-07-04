import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import 'features/auth/presentation/auth_notifier.dart';
import 'features/auth/domain/auth_state.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/pin_lock_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/sync/domain/sync_service.dart';
import 'features/sync/domain/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Hive for local persistent token/credentials caching
  await Hive.initFlutter();

  runApp(
    const ProviderScope(
      child: BhojanApp(),
    ),
  );
}

class BhojanApp extends ConsumerWidget {
  const BhojanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to real-time authentication status changes
    final authState = ref.watch(authProvider);
    
    // Instantiate background sync queue listeners
    ref.watch(syncServiceProvider);
    
    // Instantiate notifications service listeners
    ref.watch(notificationServiceProvider).initialize();

    return MaterialApp(
      title: 'BhojanOS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC8102E),
          primary: const Color(0xFFC8102E),
          secondary: const Color(0xFF003893),
        ),
        textTheme: GoogleFonts.outfitTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: _getRootScreen(authState.status),
    );
  }

  /// Maps the authentication state status directly to the root screens
  Widget _getRootScreen(AuthStatus status) {
    switch (status) {
      case AuthStatus.authenticated:
        return const DashboardScreen();
      case AuthStatus.pinLocked:
        return const PinLockScreen();
      case AuthStatus.authenticating:
      case AuthStatus.unauthenticated:
      case AuthStatus.error:
      default:
        return const LoginScreen();
    }
  }
}
