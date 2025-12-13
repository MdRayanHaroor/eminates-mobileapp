import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:investorapp_eminates/features/dashboard/providers/dashboard_provider.dart';
import 'package:investorapp_eminates/models/investor_request.dart';
import 'package:investorapp_eminates/repositories/investor_repository.dart';

class AdminUserDetailsScreen extends ConsumerStatefulWidget {
  final String userId;
  final Map<String, dynamic>? userExtra; // Optional pre-passed data

  const AdminUserDetailsScreen({super.key, required this.userId, this.userExtra});

  @override
  ConsumerState<AdminUserDetailsScreen> createState() => _AdminUserDetailsScreenState();
}

class _AdminUserDetailsScreenState extends ConsumerState<AdminUserDetailsScreen> with SingleTickerProviderStateMixin {
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
    final userDetailsAsync = ref.watch(userDetailsProvider(widget.userId));
    final userRequestsAsync = ref.watch(userRequestsByIdProvider(widget.userId));

    return Scaffold(
      appBar: AppBar(title: const Text('User Details')),
      body: userDetailsAsync.when(
        data: (user) {
          final String fullName = user['full_name'] ?? 'N/A';
          final email = user['email'] ?? 'N/A';
          final phone = user['phone'] ?? 'N/A';
          final joinedDate = user['created_at'] != null 
              ? DateFormat.yMMMd().format(DateTime.parse(user['created_at'])) 
              : 'Unknown';
          final role = user['role'] ?? 'user';
          
          final isAgent = role == 'agent';
          final isAdmin = role == 'admin';
          final referredByUuid = user['referred_by']; 

          return Column(
            children: [
              // 1. Profile Header
              Container(
                padding: const EdgeInsets.all(24),
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        fullName.characters.first.toUpperCase(),
                        style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(fullName, style: Theme.of(context).textTheme.headlineSmall),
                          Text(email, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                          const SizedBox(height: 4),
                          Container(
                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                             decoration: BoxDecoration(
                               color: role == 'admin' ? Colors.red.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                               borderRadius: BorderRadius.circular(4),
                             ),
                             child: Text(role.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: role == 'admin' ? Colors.red : Colors.blue)),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),

              // 2. Tabs
              TabBar(
                controller: _tabController,
                tabs: [
                  const Tab(text: 'Overview'),
                  Tab(text: isAgent ? 'Referrals' : 'Investments'),
                ],
              ),

              // 3. Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Overview Tab
                    ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildInfoTile(Icons.phone, 'Phone', phone),
                        _buildInfoTile(Icons.calendar_today, 'Joined', joinedDate),

                        // dont show referred by if user is agent or admin
                        if (!isAgent && !isAdmin)
                        // Async Referrer Lookup
                        if (referredByUuid != null && (referredByUuid as String).isNotEmpty)
                           _buildReferrerTile(ref, referredByUuid)
                        else
                           _buildInfoTile(Icons.person_add, 'Referred By', 'None'),

                        const SizedBox(height: 24),
                        const Text('Bank Account Being Used', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                         
                        // Fetch latest request to show user's bank details for payouts
                        userRequestsAsync.when(
                          data: (requests) {
                             if (requests.isEmpty) {
                               return const Card(
                                 child: Padding(
                                   padding: EdgeInsets.all(16.0),
                                   child: Text('No bank account being used (No requests).', style: TextStyle(color: Colors.grey)),
                                 ),
                               );
                             }
                             // Use the latest request
                             final latestReq = requests.first;
                             if (latestReq.accountNumber == null) {
                                return const Card(
                                 child: Padding(
                                   padding: EdgeInsets.all(16.0),
                                   child: Text('Bank account being used details missing in latest request.', style: TextStyle(color: Colors.grey)),
                                 ),
                               );
                             }
                             
                             return Card(
                               child: Padding(
                                 padding: const EdgeInsets.all(16.0),
                                 child: Column(
                                   children: [
                                     _buildBankRow('Bank', latestReq.bankName),
                                     _buildBankRow('Account No', latestReq.accountNumber),
                                     _buildBankRow('IFSC', latestReq.ifscCode),
                                     _buildBankRow('Holder', latestReq.accountHolderName),
                                   ],
                                 ),
                               ),
                             );
                          },
                          loading: () => const Center(child: Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator())),
                          error: (e, s) => const Text('Error loading bank details'),
                        ),
                      ],
                    ),

                    // Second Tab: Referrals (Agent) OR Investments (User)
                    isAgent 
                    ? _buildReferralsTab(ref, user['id']) // Passing UUID not Code
                    : _buildInvestmentsTab(userRequestsAsync),

                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) {
           return Center(child: Text('Error loading user: $err'));
        },
      ),
    );
  }

  Widget _buildReferrerTile(WidgetRef ref, String referredByUuid) {
    final referrerAsync = ref.watch(userDetailsProvider(referredByUuid));
    return referrerAsync.when(
      data: (referrer) {
         final name = referrer['full_name'] ?? 'Unknown';
         final email = referrer['email'] ?? '';
         final phone = referrer['phone'] ?? '';
         return ListTile(
            leading: const Icon(Icons.person_add, color: Colors.blue),
            title: const Text('Referred By', style: TextStyle(fontSize: 12, color: Colors.grey)),
            subtitle: Text('$name\n$email | $phone', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.blue),
            onTap: () {
               // Open Agent Details
               context.push('/admin/users/${referrer['id']}', extra: referrer);
            },
         );
      },
      loading: () => const ListTile(leading: Icon(Icons.person_add), title: Text('Referred By'), subtitle: Text('Loading...')),
      error: (e, s) => _buildInfoTile(Icons.person_add, 'Referred By', 'Unknown ID'),
    );
  }

  Widget _buildInvestmentsTab(AsyncValue<List<InvestorRequest>> requestsAsync) {
    return requestsAsync.when(
      data: (requests) {
        if (requests.isEmpty) return const Center(child: Text('No investments made yet.'));
        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(req.effectivePlanName),
                subtitle: Text('Amount: ₹${req.investmentAmount ?? '0'}\nStatus: ${req.status}'),
                isThreeLine: true,
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {
                  context.push('/request/${req.id}'); 
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error loading requests: $err')),
    );
  }

  Widget _buildReferralsTab(WidgetRef ref, String? agentId) {
    if (agentId == null || agentId.isEmpty) {
      return const Center(child: Text('Invalid Agent ID.'));
    }
    
    // We reuse the provider using the ID
    final referralsAsync = ref.watch(agentReferralsListProvider(agentId));
    
    return referralsAsync.when(
      data: (users) {
        if (users.isEmpty) return const Center(child: Text('No referrals found for this agent.'));
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final name = user['full_name'] ?? 'Unknown';
            final email = user['email'] ?? 'No Email';
            final phone = user['phone'] ?? 'No Phone';
            
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                   child: Text((name as String).characters.first.toUpperCase()),
                ),
                title: Text(name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(email),
                    Text(phone),
                  ],
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {
                   // Navigate to THEIR details
                   context.push('/admin/users/${user['id']}', extra: user);
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey),
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildBankRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// Providers
final userDetailsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  return ref.read(investorRepositoryProvider).getUserDetails(userId);
});

final userRequestsByIdProvider = FutureProvider.family<List<InvestorRequest>, String>((ref, userId) async {
  return ref.read(investorRepositoryProvider).getUserRequests(userId);
});

final agentReferralsListProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, id) async {
  return ref.read(investorRepositoryProvider).getReferrals(id);
});
