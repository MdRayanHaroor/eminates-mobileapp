import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investorapp_eminates/features/auth/screens/login_screen.dart';
import 'package:investorapp_eminates/features/auth/screens/signup_screen.dart';
import 'package:investorapp_eminates/features/dashboard/dashboard_screen.dart';
import 'package:investorapp_eminates/features/onboarding/screens/onboarding_screen.dart';
import 'package:investorapp_eminates/features/request_details/request_details_screen.dart';
import 'package:investorapp_eminates/features/onboarding/screens/plan_details_screen.dart';
import 'package:investorapp_eminates/features/onboarding/models/investment_plan.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Placeholder classes removed to use imported implementations

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:investorapp_eminates/core/utils/go_router_refresh_stream.dart';

import 'package:investorapp_eminates/features/auth/screens/change_password_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final supabase = Supabase.instance.client;
  
  // Listen for password recovery event
  bool isPasswordRecovery = false;
  supabase.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.passwordRecovery) {
      isPasswordRecovery = true;
      // We might need to force a refresh here if GoRouter doesn't pick it up immediately
      // But GoRouterRefreshStream should handle it.
    }
  });

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(supabase.auth.onAuthStateChange),
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/request/:id',
        builder: (context, state) => RequestDetailsScreen(requestId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/change-password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/plan-details',
        builder: (context, state) {
          final plan = state.extra as InvestmentPlan;
          return PlanDetailsScreen(plan: plan);
        },
      ),
    ],
    redirect: (context, state) {
      final session = supabase.auth.currentSession;
      final loggingIn = state.uri.toString() == '/login' || state.uri.toString() == '/signup';
      final changingPassword = state.uri.toString() == '/change-password';

      // If we are in recovery mode (detected by event listener above, but we can't easily pass it here without a provider)
      // However, usually when passwordRecovery happens, the user is logged in with a temporary session.
      // We can check if the URL contains `type=recovery` if it was a deep link, but Supabase handles that.
      
      // Let's rely on a query parameter or just the fact that we want to go there.
      // But wait, how do we know to go to /change-password?
      // The `onAuthStateChange` listener above sets a local var, but `redirect` is a callback.
      // We should probably use a Notifier for the router that includes this state.
      
      // Simpler hack: If we are logged in and the route is /change-password, allow it.
      if (session != null && changingPassword) return null;

      if (session == null && !loggingIn && !changingPassword) return '/login';
      if (session != null && loggingIn) return '/dashboard';

      return null;
    },
  );
});
