import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:investorapp_eminates/features/auth/screens/login_screen.dart';
import 'package:investorapp_eminates/features/auth/screens/signup_screen.dart';
import 'package:investorapp_eminates/features/dashboard/dashboard_screen.dart';
import 'package:investorapp_eminates/features/onboarding/screens/onboarding_screen.dart';
import 'package:investorapp_eminates/features/request_details/request_details_screen.dart';
import 'package:investorapp_eminates/features/onboarding/screens/plan_details_screen.dart';
import 'package:investorapp_eminates/features/onboarding/models/investment_plan.dart';
import 'package:investorapp_eminates/features/investment/screens/submit_utr_screen.dart';
import 'package:investorapp_eminates/features/investment/screens/investment_dashboard_screen.dart';
import 'package:investorapp_eminates/features/investment/screens/payout_history_screen.dart';
import 'package:investorapp_eminates/features/investment/screens/investment_documents_screen.dart';
import 'package:investorapp_eminates/features/plans/plans_screen.dart';
import 'package:investorapp_eminates/features/plans/edit_plan_screen.dart';
import 'package:investorapp_eminates/features/admin/screens/admin_settings_screen.dart';
import 'package:investorapp_eminates/features/admin/screens/admin_users_screen.dart';
import 'package:investorapp_eminates/features/admin/screens/admin_user_detail_screen.dart';
import 'package:investorapp_eminates/features/dashboard/notifications_screen.dart';
import 'package:investorapp_eminates/models/investor_request.dart';
import 'package:investorapp_eminates/features/agents/agents_screen.dart';
import 'package:investorapp_eminates/features/agents/create_agent_screen.dart';
import 'package:investorapp_eminates/features/agents/screens/agent_referrals_screen.dart';
import 'package:investorapp_eminates/features/agents/screens/agent_payouts_screen.dart';
import 'package:investorapp_eminates/features/agents/agent_detail_screen.dart';
import 'package:investorapp_eminates/features/onboarding/screens/referral_entry_screen.dart';
import 'package:investorapp_eminates/features/onboarding/screens/intro_walkthrough_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Placeholder classes removed to use imported implementations

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:investorapp_eminates/core/utils/go_router_refresh_stream.dart';

import 'package:investorapp_eminates/features/auth/screens/change_password_screen.dart';
import 'package:investorapp_eminates/features/auth/screens/update_password_screen.dart';
import 'package:investorapp_eminates/features/auth/screens/phone_entry_screen.dart';
import 'package:investorapp_eminates/core/services/phone_verification_service.dart';

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
        path: '/walkthrough',
        builder: (context, state) => const IntroWalkthroughScreen(),
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
        path: '/update-password',
        builder: (context, state) => const UpdatePasswordScreen(),
      ),
      GoRoute(
        path: '/plan-details',
        builder: (context, state) {
          final extra = state.extra;
          InvestmentPlan plan;
          bool fromOnboarding = false;

          if (extra is InvestmentPlan) {
            plan = extra;
          } else if (extra is Map) {
            plan = extra['plan'] as InvestmentPlan;
            fromOnboarding = extra['fromOnboarding'] as bool? ?? false;
          } else {
             // Fallback or error
             throw Exception('Invalid args for plan details');
          }
          
          return PlanDetailsScreen(plan: plan, fromOnboarding: fromOnboarding);
        },
      ),
      GoRoute(
        path: '/submit-utr/:id',
        builder: (context, state) {
           final id = state.pathParameters['id']!;
           return SubmitUtrScreen(requestId: id);
        },
      ),
      GoRoute(
        path: '/investment-dashboard',
        builder: (context, state) {
          final request = state.extra as InvestorRequest;
          return InvestmentDashboardScreen(request: request);
        },
      ),
      GoRoute(
        path: '/payout-history/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return PayoutHistoryScreen(requestId: id);
        },
      ),
      GoRoute(
        path: '/investment-documents',
        builder: (context, state) {
           final request = state.extra as InvestorRequest;
           return InvestmentDocumentsScreen(request: request);
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/plans',
        builder: (context, state) => const PlansScreen(),
      ),
      GoRoute(
        path: '/enter-referral',
        builder: (context, state) => const ReferralEntryScreen(),
      ),
      GoRoute(
        path: '/edit-plan',
        builder: (context, state) {
          final plan = state.extra as InvestmentPlan;
          return EditPlanScreen(plan: plan);
        },
      ),
      GoRoute(
        path: '/agents',
        builder: (context, state) => const AgentsScreen(),
      ),
      GoRoute(
        path: '/create-agent',
        builder: (context, state) => const CreateAgentScreen(),
      ),
      GoRoute(
        path: '/agent-detail/:id',
        builder: (context, state) {
           final id = state.pathParameters['id']!;
           return AgentDetailScreen(agentId: id);
        },
      ),
      GoRoute(
        path: '/agent-referrals',
        builder: (context, state) => const AgentReferralsScreen(),
      ),
      GoRoute(
        path: '/agent-payouts',
        builder: (context, state) => const AgentPayoutsScreen(),
      ),
      GoRoute(
        path: '/admin-settings',
        builder: (context, state) => const AdminSettingsScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const AdminUsersScreen(),
      ),
      GoRoute(
        path: '/admin/users/:id',
        builder: (context, state) {
           final id = state.pathParameters['id']!;
           final extra = state.extra as Map<String, dynamic>?;
           return AdminUserDetailsScreen(userId: id, userExtra: extra);
        },
      ),
      GoRoute(
        path: '/enter-phone',
        builder: (context, state) => const PhoneEntryScreen(),
      ),

    ],
    redirect: (context, state) async {
      final session = supabase.auth.currentSession;
      final loggingIn = state.uri.toString() == '/login' || state.uri.toString() == '/signup';
      final changingPassword = state.uri.toString() == '/change-password';
      final enteringPhone = state.uri.toString() == '/enter-phone';

      // 1. Handle Deep Links (prevent GoException)
      if (state.uri.scheme == 'io.supabase.app' || state.uri.scheme == 'io.supabase.investorapp') {
        // Allow Supabase SDK to handle the auth exchange
        // Redirect to login (if no session) or dashboard (if session found)
        return session != null ? '/dashboard' : '/login';
      }

      // 2. Normal Routing
      if (session == null) {
        if (!loggingIn && !changingPassword) return '/login';
        return null; // Allow access to login/signup
      }

      // Session exists
      if (changingPassword) return null;

      // Check phone verification
      final isVerified = await PhoneVerificationService.isVerified(supabase, session.user.id);

      if (enteringPhone) {
        // If already verified, doesn't need to be here
        if (isVerified) return '/dashboard';
        // If not verified, allow to stay here
        return null;
      }

      // Not on phone entry screen
      if (!isVerified) {
        // Must go to phone entry
        return '/enter-phone';
      }

      // Verified and not entering phone
      if (loggingIn) return '/dashboard';

      return null;
    },
  );
});
