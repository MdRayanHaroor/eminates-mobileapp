import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final agentReferralsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser!.id;

  // 1. Get My Commission %
  final me = await supabase.from('users').select('commission_percentage').eq('id', userId).single();
  final myComm = (me['commission_percentage'] as num?)?.toDouble() ?? 0.0;

  // 2. Get Referred Users
  final usersData = await supabase
      .from('users')
      .select('id, full_name, email, created_at')
      .eq('referred_by', userId)
      .order('created_at', ascending: false);
  
  final users = List<Map<String, dynamic>>.from(usersData);
  final userIds = users.map((u) => u['id']).toList();

  // 3. Get Investments
  List<Map<String, dynamic>> investments = [];
  if (userIds.isNotEmpty) {
     final invData = await supabase
         .from('investor_requests')
         .select('*')
         .filter('user_id', 'in', userIds)
         .eq('status', 'Investment Confirmed');
     investments = List<Map<String, dynamic>>.from(invData);
  }

  return {
    'commissionPct': myComm,
    'users': users,
    'investments': investments,
  };
});

class AgentReferralsScreen extends ConsumerWidget {
  const AgentReferralsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(agentReferralsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Referrals')),
      body: asyncData.when(
        data: (data) {
          final users = data['users'] as List;
          final investments = data['investments'] as List;
          final commPct = data['commissionPct'] as double;
          
          if (users.isEmpty) return const Center(child: Text('No referrals yet.'));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final userInvestments = investments.where((i) => i['user_id'] == user['id']).toList();

              // Calculate total for this user
              double userTotalInvested = 0;
              for (var i in userInvestments) {
                 final raw = i['investment_amount'].toString().replaceAll(RegExp(r'[^\d.]'), '');
                 userTotalInvested += double.tryParse(raw) ?? 0;
              }
              final userTotalComm = userTotalInvested * (commPct / 100);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  leading: CircleAvatar(child: Text((user['full_name'] ?? 'U')[0].toUpperCase())),
                  title: Text(user['full_name'] ?? 'Unknown'),
                  subtitle: Text('Total Commission Earned: ₹${NumberFormat.compact().format(userTotalComm)}'),
                  children: [
                    if (userInvestments.isEmpty)
                      const ListTile(title: Text('No active investments', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)))
                    else
                      ...userInvestments.map((inv) {
                         final raw = inv['investment_amount'].toString().replaceAll(RegExp(r'[^\d.]'), '');
                         final amount = double.tryParse(raw) ?? 0;
                         final comm = amount * (commPct / 100);
                         
                         return ListTile(
                           dense: true,
                           contentPadding: const EdgeInsets.only(left: 32, right: 16),
                           title: Text(inv['plan_name'] ?? 'Unknown Plan'),
                           subtitle: Text('Invested: ₹$amount'),
                           trailing: Column(
                             mainAxisAlignment: MainAxisAlignment.center,
                             crossAxisAlignment: CrossAxisAlignment.end,
                             children: [
                               Text('Comm: ₹${comm.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                               Text('${commPct}%', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                             ],
                           ),
                         );
                      }),
                  ],
                ),
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
