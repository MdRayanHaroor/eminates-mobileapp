import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final agentPayoutsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser!.id;

  // 1. Get Referred Users
  final referredUsers = await supabase.from('users').select('id, full_name').eq('referred_by', userId);
  final referralIds = (referredUsers as List).map((u) => u['id']).toList();

  if (referralIds.isEmpty) return [];

  // 2. Get Requests for these users
  final requests = await supabase.from('investor_requests').select('id, plan_name, user_id').filter('user_id', 'in', referralIds);
  final requestIds = (requests as List).map((r) => r['id']).toList();

  if (requestIds.isEmpty) return [];

  // 3. Get Commission Payouts
  final payoutsData = await supabase
      .from('payouts')
      .select('*')
      .eq('type', 'Commission')
      .filter('request_id', 'in', requestIds)
      .order('payment_date', ascending: false);

  // Enrich with plan/user info
  final enriched = (payoutsData as List<dynamic>).map((p) {
     final req = requests.firstWhere(
       (r) => r['id'] == p['request_id'], 
       orElse: () => <String, dynamic>{}, // Explicit type
     );
     final user = referredUsers.firstWhere(
       (u) => u['id'] == req['user_id'], 
       orElse: () => <String, dynamic>{'full_name': 'Unknown'}, // Explicit type
     );
     return <String, dynamic>{
       ...p,
       'plan_name': req['plan_name'] ?? 'Unknown Plan',
       'user_name': user['full_name'],
     };
  }).toList();
  
  return List<Map<String, dynamic>>.from(enriched);
});

class AgentPayoutsScreen extends ConsumerWidget {
  const AgentPayoutsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payoutsAsync = ref.watch(agentPayoutsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Commission Payouts')),
      body: payoutsAsync.when(
        data: (payouts) {
          if (payouts.isEmpty) return const Center(child: Text('No payouts found'));
          
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: payouts.length,
            separatorBuilder: (_,__) => const Divider(),
            itemBuilder: (context, index) {
              final p = payouts[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green[100], 
                  child: const Icon(Icons.attach_money, color: Colors.green)
                ),
                title: Text('₹${p['amount']}'),
                subtitle: Text('From: ${p['user_name']} (${p['plan_name']})\nPaid: ${DateFormat.yMMMd().format(DateTime.parse(p['payment_date']))}'),
                isThreeLine: true,
                trailing: p['transaction_utr'] != null 
                    ? Chip(label: Text(p['transaction_utr']), backgroundColor: Colors.green[50])
                    : null,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
