import 'package:investorapp_eminates/models/investor_request.dart';
import 'package:investorapp_eminates/models/payout.dart';
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

  Future<void> updateRequestStatus(String id, String status) async {
    await _supabase
        .from('investor_requests')
        .update({'status': status})
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
}
