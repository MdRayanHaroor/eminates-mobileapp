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
