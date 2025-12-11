import 'package:investorapp_eminates/models/investor_request.dart';
import 'package:investorapp_eminates/models/payout.dart';
import 'package:investorapp_eminates/features/onboarding/models/investment_plan.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InvestorRepository {
  final SupabaseClient _supabase;

  InvestorRepository(this._supabase);

  Future<List<InvestorRequest>> getUserRequests(String userId) async {
    final response = await _supabase
        .from('investor_requests')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((e) => InvestorRequest.fromJson(e)).toList();
  }

  Future<List<InvestorRequest>> getAllRequests() async {
    final response = await _supabase
        .from('investor_requests')
        .select()
        .neq('status', 'Draft') // Exclude drafts from admin view
        .order('created_at', ascending: false);

    return (response as List).map((e) => InvestorRequest.fromJson(e)).toList();
  }

  Future<InvestorRequest> getRequestById(String id) async {
    final response = await _supabase
        .from('investor_requests')
        .select()
        .eq('id', id)
        .single();

    return InvestorRequest.fromJson(response);
  }

  Future<void> createRequest(InvestorRequest request) async {
    await _supabase.from('investor_requests').insert(request.toJson());
  }

  Future<void> updateRequestStatus(String id, String status, {String? reason}) async {
    final data = {'status': status};
    if (reason != null) {
      data['rejection_reason'] = reason;
    }
    
    await _supabase
        .from('investor_requests')
        .update(data)
        .eq('id', id);
  }

  Future<void> updateRequest(InvestorRequest request) async {
    await _supabase
        .from('investor_requests')
        .update(request.toJson())
        .eq('id', request.id!);
  }

  Future<void> deleteRequest(String id) async {
    // 1. Fetch the request to get file paths
    final request = await getRequestById(id);

    // 2. Collect non-null file paths
    final pathsToDelete = <String>[];
    if (request.panCardUrl != null) pathsToDelete.add(request.panCardUrl!);
    if (request.aadhaarCardUrl != null) pathsToDelete.add(request.aadhaarCardUrl!);
    if (request.selfieUrl != null) pathsToDelete.add(request.selfieUrl!);

    // 3. Delete files from storage if any
    if (pathsToDelete.isNotEmpty) {
      // Note: Supabase delete takes a list of paths
      await _supabase.storage.from('kyc_docs').remove(pathsToDelete);
    }

    // 4. Delete the DB record
    await _supabase
        .from('investor_requests')
        .delete()
        .eq('id', id);
  }

  // --- Post-Acceptance Methods ---

  Future<void> submitUtr(String requestId, String utr) async {
    await _supabase
        .from('investor_requests')
        .update({
          'transaction_utr': utr,
          'transaction_date': DateTime.now().toIso8601String(),
          'status': 'UTR Submitted', // Update status logic handled here or implicitly
        })
        .eq('id', requestId);
  }

  Future<List<Payout>> getPayouts(String requestId) async {
    final response = await _supabase
        .from('payouts')
        .select()
        .eq('request_id', requestId)
        .order('payment_date', ascending: false);

    return (response as List).map((e) => Payout.fromJson(e)).toList();
  }

  Future<void> addPayout(Payout payout) async {
    await _supabase.from('payouts').insert(payout.toJson());
  }

  // --- Dynamic Content Methods ---

  Future<List<dynamic>> getInvestmentPlans() async {
    final response = await _supabase
        .from('investment_plans')
        .select()
        .eq('is_active', true)
        .order('min_amount', ascending: true);
    return response as List<dynamic>;
  }

  Future<Map<String, dynamic>?> getAppSetting(String key) async {
    try {
      final response = await _supabase
          .from('app_settings')
          .select('value')
          .eq('key', key)
          .single();
      return response['value'] as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateInvestmentPlan(InvestmentPlan plan) async {
    // Only update editable fields
    await _supabase.from('investment_plans').update({
      'min_amount': plan.minAmount,
      'max_amount': plan.maxAmount, // Assuming we added this to model, or we just map min/max
      'roi_percentage': plan.roiPercentage,
      'duration_months': (plan.tenureYears * 12).toInt(),
      'features': plan.features,
      'is_active': plan.isActive,
    }).eq('id', plan.id!);
  }

  Future<void> saveAppSetting(String key, Map<String, dynamic> value) async {
    await _supabase.from('app_settings').upsert({
      'key': key,
      'value': value,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
