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

  Future<void> updateRequestStatus(String id, String status, {String? reason, Map<String, dynamic>? adminBankDetails}) async {
    final Map<String, dynamic> data = {'status': status};
    if (reason != null) {
      data['rejection_reason'] = reason;
    }
    if (adminBankDetails != null) {
      data['admin_bank_details'] = adminBankDetails;
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

  Future<List<Map<String, dynamic>>> getAppSettings(String key) async {
    try {
      final response = await _supabase
          .from('app_settings')
          .select() // Select all fields (id, key, value, description, is_active)
          .eq('key', key)
          .eq('is_active', true) // Only active ones? Maybe all for admin screen.
          .order('created_at', ascending: false);
      
      // We return the full row maps
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }
  
  // For Admin to see ALL (including inactive)
  Future<List<Map<String, dynamic>>> getAllAppSettings(String key) async {
    final response = await _supabase
        .from('app_settings')
        .select()
        .eq('key', key)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> deleteAppSetting(String id) async {
    await _supabase.from('app_settings').delete().eq('id', id);
  }

  Future<void> updateInvestmentPlan(InvestmentPlan plan) async {
    // Only update editable fields - using toJson() is safer as it includes all new schema fields
    // We remove 'id' from the map to avoid updating primary key (though Supabase ignores it usually)
    final data = plan.toJson();
    data.remove('id');
    await _supabase.from('investment_plans').update(data).eq('id', plan.id!);
  }

  Future<void> saveAppSetting({
    String? id,
    required String key,
    required Map<String, dynamic> value,
    String? description,
    bool isActive = true,
  }) async {
    final data = {
      'key': key,
      'value': value,
      'description': description,
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    if (id != null) {
      // Update
      await _supabase.from('app_settings').update(data).eq('id', id);
    } else {
      // Insert
      await _supabase.from('app_settings').insert(data);
    }
  }

  // --- User Management Methods ---

  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getUserDetails(String userId) async {
    final response = await _supabase
        .from('users')
        .select()
        .eq('id', userId)
        .single();
    return response;
  }

  Future<List<Map<String, dynamic>>> getReferrals(String referrerId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('referred_by', referrerId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }
}
