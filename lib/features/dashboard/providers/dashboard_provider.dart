import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:investorapp_eminates/features/auth/providers/auth_provider.dart';
import 'package:investorapp_eminates/models/investor_request.dart';
import 'package:investorapp_eminates/repositories/investor_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final investorRepositoryProvider = Provider<InvestorRepository>((ref) {
  return InvestorRepository(Supabase.instance.client);
});

final userRequestsProvider = FutureProvider<List<InvestorRequest>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(investorRepositoryProvider).getUserRequests(user.id);
});

final allRequestsProvider = FutureProvider<List<InvestorRequest>>((ref) async {
  // Only for admins
  final isAdmin = await ref.watch(isAdminProvider.future);
  if (!isAdmin) return [];
  return ref.watch(investorRepositoryProvider).getAllRequests();
});

final plansProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(investorRepositoryProvider).getInvestmentPlans();
});

final userRoleProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final supabase = Supabase.instance.client;
  try {
    final response = await supabase.from('users').select('role').eq('id', user.id).single();
    return response['role'] as String?;
  } catch (e) {
    return null;
  }
});

final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser; // Use direct auth or provider
  if (user == null) return null;
  return await supabase.from('users').select('*').eq('id', user.id).single();
});
