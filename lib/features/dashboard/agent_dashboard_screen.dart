import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:investorapp_eminates/features/auth/providers/auth_provider.dart';

// Providers for Agent Dashboard
// Update provider to fetch active codes too
final agentStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final supabase = Supabase.instance.client;
  final userId = supabase.auth.currentUser!.id;

  // 1. Get Commission %
  final userResponse = await supabase
      .from('users')
      .select('commission_percentage')
      .eq('id', userId)
      .single();
  final commissionPct = (userResponse['commission_percentage'] as num?)?.toDouble() ?? 0.0;

  // 2. Get Referred Users
  final referredUsersResponse = await supabase
      .from('users')
      .select('id, full_name, email, created_at')
      .eq('referred_by', userId);
  
  final referredUsers = List<Map<String, dynamic>>.from(referredUsersResponse);
  final totalReferred = referredUsers.length;

  // 3. Get Active Codes
  final activeCodesResponse = await supabase
      .from('referral_codes')
      .select('*')
      .eq('agent_id', userId)
      .eq('is_used', false)
      .gt('expires_at', DateTime.now().toUtc().toIso8601String())
      .order('expires_at', ascending: false);
  final activeCodes = List<Map<String, dynamic>>.from(activeCodesResponse);

  // 4. Calculate Commission
  double totalInvested = 0;
  if (referredUsers.isNotEmpty) {
     final referredIds = referredUsers.map((u) => u['id']).toList();
     final requestsResponse = await supabase
        .from('investor_requests')
        .select('investment_amount') // Correct column name (Text)
        .filter('user_id', 'in', referredIds)
        .eq('status', 'Investment Confirmed');
     
     for (var r in requestsResponse) {
       final rawAmount = r['investment_amount']?.toString() ?? '0';
       // Extract digits and commas only (e.g. "₹10,00,000" -> "10,00,000")
       // Then remove commas to parse.
       // Handle cases like "₹10,00,000 - Platinum" or just "200000"
       final numericString = rawAmount.replaceAll(RegExp(r'[^\d]'), ''); 
       if (numericString.isNotEmpty) {
           totalInvested += double.tryParse(numericString) ?? 0.0;
       }
     }
  }

  final totalCommission = totalInvested * (commissionPct / 100);

  return {
    'totalReferred': totalReferred,
    'totalCommission': totalCommission,
    'recentUsers': referredUsers,
    'activeCodes': activeCodes,
  };
});

class AgentDashboardScreen extends ConsumerStatefulWidget {
  const AgentDashboardScreen({super.key});

  @override
  ConsumerState<AgentDashboardScreen> createState() => _AgentDashboardScreenState();
}

class _AgentDashboardScreenState extends ConsumerState<AgentDashboardScreen> {
  bool _isGenerating = false;

  Future<void> _generateCode() async {
    setState(() => _isGenerating = true);
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final rng = Random();
      final code = (rng.nextInt(9000) + 1000).toString();
      final expiresAt = DateTime.now().toUtc().add(const Duration(hours: 1));

      await supabase.from('referral_codes').insert({
        'code': code,
        'agent_id': user.id,
        'expires_at': expiresAt.toIso8601String(),
        'is_used': false,
      });

      ref.refresh(agentStatsProvider); // Refresh to show new code
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code generated!')));
      
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final statsAsync = ref.watch(agentStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Agent Dashboard')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: const Text('Agent'),
              accountEmail: Text(user?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text('AG', style: TextStyle(color: Theme.of(context).primaryColor)),
              ),
            ),
             ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () => Navigator.pop(context), 
            ),
             const Divider(),
             ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                  Navigator.pop(context);
                  await ref.read(authRepositoryProvider).signOut();
                  if (context.mounted) context.go('/login');
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(agentStatsProvider),
        child: statsAsync.when(
          data: (stats) {
            final totalReferred = stats['totalReferred'] as int;
            final totalCommission = stats['totalCommission'] as double;
            final recentUsers = stats['recentUsers'] as List<Map<String, dynamic>>;
            final activeCodes = stats['activeCodes'] as List<Map<String, dynamic>>;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Stats Row
                Row(
                  children: [
                    Expanded(child: _buildStatCard('Referred', '$totalReferred Users', Icons.people)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard('Commission', '₹${totalCommission.toStringAsFixed(0)}', Icons.monetization_on)),
                  ],
                ),
                const SizedBox(height: 24),

                // 2. Code Management Section
                const Text('Manage Referral Codes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        if (_isGenerating)
                           const CircularProgressIndicator()
                        else
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _generateCode,
                              icon: const Icon(Icons.add),
                              label: const Text('Generate New Code (1 Hr Validity)'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        if (activeCodes.isEmpty)
                          const Text('No active codes. Generate one to start referring.', style: TextStyle(color: Colors.grey))
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: activeCodes.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, index) {
                              final codeData = activeCodes[index];
                              final expiresAt = DateTime.parse(codeData['expires_at']);
                              final timeLeft = expiresAt.difference(DateTime.now());
                              
                              return ListTile(
                                title: Text(
                                  codeData['code'],
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 2),
                                ),
                                subtitle: Text('Expires in ${timeLeft.inMinutes} mins'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.copy),
                                  onPressed: () {
                                     Clipboard.setData(ClipboardData(text: codeData['code']));
                                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied!')));
                                  },
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 3. Recent Referrals
                const Text('Recent Referrals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (recentUsers.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: Text('No referrals yet.', style: TextStyle(color: Colors.grey))),
                    ),
                  )
                else
                  ...recentUsers.map((u) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(child: Text((u['full_name'] ?? 'U')[0].toUpperCase())),
                      title: Text(u['full_name'] ?? 'Unknown User'),
                      subtitle: Text(u['email'] ?? ''),
                      trailing: Text(
                        u['created_at'].toString().split('T')[0],
                         style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  )),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.blueGrey),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

