import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:investorapp_eminates/features/agents/widgets/add_payout_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:investorapp_eminates/core/utils/error_utils.dart'; // Assuming exist or use simple helper

// Provider to fetch agent details and related data
final agentDetailProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, agentId) async {
  final supabase = Supabase.instance.client;

  // 1. Fetch Agent Info
  final agentData = await supabase.from('users').select().eq('id', agentId).single();

  // 2. Fetch Referrals (Users)
  final referralsData = await supabase
      .from('users')
      .select('id, full_name, email, created_at')
      .eq('referred_by', agentId)
      .order('created_at', ascending: false);
  
  final referrals = List<Map<String, dynamic>>.from(referralsData);
  final referralIds = referrals.map((u) => u['id']).toList();

  // 3. Fetch Investments for these referrals (to calc commission)
  List<Map<String, dynamic>> investments = [];
  if (referralIds.isNotEmpty) {
    final invData = await supabase
        .from('investor_requests')
        .select('*')
        .filter('user_id', 'in', referralIds)
        .eq('status', 'Investment Confirmed'); // Only confirmed investments count?
    investments = List<Map<String, dynamic>>.from(invData);
  }

  // 4. Fetch Payouts (Commission)
  // Logic: Payouts where type='Commission' AND request_id belongs to one of the investments
  // Note: We need request_ids from the investments
  List<Map<String, dynamic>> payouts = [];
  if (referralIds.isNotEmpty) { // Just reuse referralIds logic if needed, but investments is better
     // Actually, we need to find payouts linked to ANY request of these users?
     // Or only confirmed ones? Let's check all requests for safety.
     final allRequests = await supabase.from('investor_requests').select('id').filter('user_id', 'in', referralIds);
     final allRequestIds = (allRequests as List).map((r) => r['id']).toList();

     if (allRequestIds.isNotEmpty) {
        final payoutsData = await supabase
          .from('payouts')
          .select('*')
          .eq('type', 'Commission')
          .filter('request_id', 'in', allRequestIds)
          .order('payment_date', ascending: false);
        payouts = List<Map<String, dynamic>>.from(payoutsData);
     }
  }

  return {
    'agent': agentData,
    'referrals': referrals,
    'investments': investments,
    'payouts': payouts,
  };
});

class AgentDetailScreen extends ConsumerStatefulWidget {
  final String agentId;
  const AgentDetailScreen({super.key, required this.agentId});

  @override
  ConsumerState<AgentDetailScreen> createState() => _AgentDetailScreenState();
}

class _AgentDetailScreenState extends ConsumerState<AgentDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncData = ref.watch(agentDetailProvider(widget.agentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agent Details'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview & Referrals'),
            Tab(text: 'Commission Payouts'),
          ],
        ),
      ),
      body: asyncData.when(
        data: (data) {
          final agent = data['agent'];
          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(data),
              _buildPayoutsTab(data),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildOverviewTab(Map<String, dynamic> data) {
    final agent = data['agent'];
    final referrals = data['referrals'] as List;
    final investments = data['investments'] as List;
    final commissionPct = (agent['commission_percentage'] as num?)?.toDouble() ?? 0.0;

    // Calculate Totals
    double totalInvested = 0;
    for (var inv in investments) {
       final raw = inv['investment_amount'].toString().replaceAll(RegExp(r'[^\d]'), '');
       totalInvested += double.tryParse(raw) ?? 0.0;
    }
    // Calculate Total Payouts (Actual Earnings)
    final payouts = data['payouts'] as List;
    double totalPayouts = 0;
    for (var p in payouts) {
       totalPayouts += (p['amount'] as num).toDouble();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Agent Card
          Card(
            child: ListTile(
              title: Text(agent['full_name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: Text(agent['email'] ?? ''),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Chip(label: Text('$commissionPct% Comm.')),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _showEditAgentDialog(context, agent['id'], agent['full_name'], commissionPct),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Stats Row
          Row(
            children: [
              Expanded(child: _statCard('Total Referrals', referrals.length.toString(), Icons.people)),
              const SizedBox(width: 8),
              Expanded(child: _statCard('Total Invested', '₹${NumberFormat.compact().format(totalInvested)}', Icons.monetization_on_outlined)),
              const SizedBox(width: 8),
              Expanded(child: _statCard('Total Paid', '₹${NumberFormat.compact().format(totalPayouts)}', Icons.wallet)),
            ],
          ),
          const SizedBox(height: 24),

          // Referrals List
          const Text('Referrals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (referrals.isEmpty) 
            const Text('No referrals yet.', style: TextStyle(color: Colors.grey))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: referrals.length,
              itemBuilder: (context, index) {
                final user = referrals[index];
                final userInvestments = investments.where((i) => i['user_id'] == user['id']).toList();
                
                // Sort by date desc
                userInvestments.sort((a, b) => (b['created_at'] ?? '').compareTo(a['created_at'] ?? ''));

                double uInvested = 0;
                for(var i in userInvestments) {
                   // Only count confirmed for total
                   if (i['status'] == 'Investment Confirmed') {
                      final r = i['investment_amount'].toString().replaceAll(RegExp(r'[^\d]'), '');
                      uInvested += double.tryParse(r) ?? 0;
                   }
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ExpansionTile(
                    leading: CircleAvatar(child: Text(user['full_name'][0].toUpperCase())),
                    title: Text(user['full_name']),
                    subtitle: Text('Invested: ₹${NumberFormat.currency(locale: 'en_IN', symbol: '').format(uInvested)}'),
                    children: userInvestments.isEmpty 
                      ? [
                          const ListTile(
                            title: Text('No investment plans yet', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
                          )
                        ]
                      : userInvestments.map((i) {
                         final isConfirmed = i['status'] == 'Investment Confirmed';
                         return ListTile(
                            dense: true,
                            leading: isConfirmed 
                                ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                                : const Icon(Icons.access_time, color: Colors.grey, size: 20),
                            title: Text(i['plan_name'] ?? 'Plan'),
                            subtitle: Text('${i['investment_amount']} • ${i['status']}'), // Show status text
                            trailing: Text(DateFormat.yMMMd().format(DateTime.parse(i['created_at']))),
                         );
                      }).toList(),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPayoutsTab(Map<String, dynamic> data) {
    final payouts = data['payouts'] as List;
    final agent = data['agent'];
    final investments = data['investments'] as List;
    final referrals = data['referrals'] as List; // Need existing Referrals list
    
    final commissionPct = (agent['commission_percentage'] as num?)?.toDouble() ?? 0.0;

    return Scaffold( 
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Payout'),
        onPressed: () async {
          if (investments.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No active investments to pay commission for.')));
            return;
          }

          // Transform investments to include User Name for the dialog
          final enrichedInvestments = investments.map((inv) {
             final user = referrals.firstWhere((r) => r['id'] == inv['user_id'], orElse: () => {'full_name': 'Unknown'});
             return {
               ...inv,
               'user_name': user['full_name'],
             };
          }).toList();

          await showDialog(
            context: context,
            builder: (_) => AddPayoutDialog(
              agentId: widget.agentId, 
              investments: enrichedInvestments,
              commissionPercentage: commissionPct, // Pass percentage
            ),
          );
          ref.refresh(agentDetailProvider(widget.agentId));
        },
      ),
      body: payouts.isEmpty 
        ? const Center(child: Text('No commission payouts yet.'))
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: payouts.length,
            separatorBuilder: (_,__) => const Divider(),
            itemBuilder: (context, index) {
              final p = payouts[index];

              // Try to find related investment name
              final inv = investments.firstWhere((i) => i['id'] == p['request_id'], orElse: () => <String, dynamic>{});
              final planName = inv['plan_name'] ?? 'Unknown Plan';

              return ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.attach_money, color: Colors.white)),
                title: Text('₹${p['amount']}'),
                // subtitle: Text('Paid on ...'),
                subtitle: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.grey),
                    children: [
                       TextSpan(text: 'Paid on ${DateFormat.yMMMd().format(DateTime.parse(p['payment_date']))}\n'),
                       TextSpan(text: '$planName', style: const TextStyle(fontWeight: FontWeight.bold)), // Show plan name
                    ],
                  ),
                ),
                isThreeLine: true,
                trailing: p['transaction_utr'] != null 
                    ? Chip(label: Text(p['transaction_utr']), backgroundColor: Colors.green[50]) 
                    : const Chip(label: Text('Cash/Other')),
              );
            },
          ),
    );
  }

  Widget _statCard(String title, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100], // Dark grey for dark mode
      shape: RoundedRectangleBorder(
        side: isDark ? BorderSide(color: Colors.grey[800]!) : BorderSide.none,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             Icon(icon, size: 20, color: isDark ? Colors.blue[300] : Colors.blueGrey),
             const SizedBox(height: 4),
             Text(
               value, 
               style: TextStyle(
                 fontWeight: FontWeight.bold, 
                 fontSize: 16,
                 color: isDark ? Colors.white : Colors.black87,
               )
             ),
             Text(
               title, 
               style: TextStyle(
                 fontSize: 10, 
                 color: isDark ? Colors.grey[400] : Colors.grey[600]
               ), 
               textAlign: TextAlign.center
             ),
           ],
        ),
      ),
    );
  }

  Future<void> _showEditAgentDialog(BuildContext context, String agentId, String? currentName, double currentComm) async {
    final nameCtrl = TextEditingController(text: currentName);
    final commCtrl = TextEditingController(text: currentComm.toString());
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Agent'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Agent Name', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: commCtrl,
                  decoration: const InputDecoration(labelText: 'Commission %', border: OutlineInputBorder(), suffixText: '%'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final d = double.tryParse(v ?? '');
                    if (d == null) return 'Invalid number';
                    if (d < 0 || d > 100) return '0-100 only';
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: isLoading ? null : () async {
                if (!formKey.currentState!.validate()) return;
                setDialogState(() => isLoading = true);
                
                try {
                  await Supabase.instance.client.from('users').update({
                    'full_name': nameCtrl.text,
                    'commission_percentage': double.parse(commCtrl.text),
                  }).eq('id', agentId);
                  
                  if (mounted) {
                    Navigator.pop(dialogContext);
                    ref.refresh(agentDetailProvider(widget.agentId));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agent updated')));
                  }
                } catch (e) {
                   if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                } finally {
                   setDialogState(() => isLoading = false);
                }
              },
              child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white)) : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

