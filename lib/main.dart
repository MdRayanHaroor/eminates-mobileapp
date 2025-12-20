import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:investorapp_eminates/core/app_router.dart';
import 'package:investorapp_eminates/core/constants/supabase_constants.dart';
import 'package:investorapp_eminates/core/theme/app_theme.dart';
import 'package:investorapp_eminates/services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:investorapp_eminates/core/providers/theme_provider.dart';
import 'package:investorapp_eminates/features/auth/providers/auth_provider.dart';
import 'package:investorapp_eminates/core/providers/connectivity_provider.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();

  await Supabase.initialize(
    url: SupabaseConstants.supabaseUrl,
    anonKey: SupabaseConstants.supabaseAnonKey,
  );
  
  // Initialize Notification Service
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // Listen for password recovery event
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        ref.read(goRouterProvider).go('/change-password');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final goRouter = ref.watch(goRouterProvider);
    
    final themeMode = ref.watch(themeModeProvider);

    // Listen to internet status
    ref.listen(internetStatusProvider, (prev, next) {
      if (next.value == InternetConnectionStatus.disconnected) {
        // Navigate to splash first, but DO NOT sign out
        ref.read(goRouterProvider).go('/splash', extra: 'Internet connection lost. Please check your settings.');
      }
    });
    
    return MaterialApp.router(
      title: 'Eminates Holdings',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
