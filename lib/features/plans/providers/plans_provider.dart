import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:investorapp_eminates/features/onboarding/models/investment_plan.dart';

final plansProvider = FutureProvider<List<InvestmentPlan>>((ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('investment_plans')
      .select('*')
      .eq('is_active', true)
      .order('min_amount', ascending: true);
      
  final data = List<Map<String, dynamic>>.from(response);
  return data.map((json) => InvestmentPlan.fromJson(json)).toList();
});
