import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:investorapp_eminates/features/auth/providers/auth_provider.dart';
import 'package:investorapp_eminates/features/dashboard/agent_dashboard_screen.dart';
import 'package:investorapp_eminates/features/dashboard/admin_dashboard_screen.dart';
import 'package:investorapp_eminates/features/dashboard/providers/dashboard_provider.dart';
import 'package:investorapp_eminates/features/dashboard/providers/notification_provider.dart';
import 'package:investorapp_eminates/features/onboarding/providers/onboarding_provider.dart';
import 'package:investorapp_eminates/models/investor_request.dart';
import 'package:investorapp_eminates/repositories/investor_repository.dart';

final userRoleProvider = FutureProvider<String?>((ref) async {
  // Watch the current user so this provider rebuilds on logout/login
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  
  final supabase = Supabase.instance.client;

  // DEBUGGING: Print user ID
  debugPrint('Fetching role for user: ${user.id}');

  try {
    final response = await supabase
      .from('users')
      .select('*') // Select ALL columns to see what's available
      .eq('id', user.id)
      .single();
      
    debugPrint('FULL USER ROW: $response');
    debugPrint('Role value: ${response['role']}');
    
    return response['role'] as String?;
  } catch (e) {
    debugPrint('ERROR fetching role: $e');
    throw e; // Let UI show error
  }
});

final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  if (user == null) return null;
  // Fail accurately too
  return await supabase.from('users').select('*').eq('id', user.id).single();
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roleAsync = ref.watch(userRoleProvider);
    final user = ref.watch(currentUserProvider);
    final requestsAsync = ref.watch(userRequestsProvider);

    return roleAsync.when(
      data: (role) {
        final actualRole = role ?? 'user';
        debugPrint('Dashboard detected role: $actualRole');

        if (actualRole == 'agent') {
          return const AgentDashboardScreen();
        }

        if (actualRole == 'admin') {
           return const AdminDashboardScreen();
        }

        // Default: User Dashboard
        return Scaffold(
          drawer: null, 
          appBar: _buildAppBar(context, ref, actualRole),
          body: _buildUserDashboard(context, ref, user?.email, requestsAsync),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
          floatingActionButton: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'plans_fab',
                  onPressed: () => context.push('/plans'),
                  icon: const Icon(Icons.explore),
                  label: const Text('Plans'),
                ),
                FloatingActionButton.extended(
                  heroTag: 'new_request_fab',
                  onPressed: () {
                    ref.read(onboardingFormProvider.notifier).resetState();
                    ref.read(onboardingStepProvider.notifier).state = 0;
                    context.push('/onboarding');
                  },
                  label: const Text('New Investment'),
                  icon: const Icon(Icons.add),
                  backgroundColor: Colors.blue,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error loading dashboard: $err'))),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref, String role) {
     return AppBar(
        title: const Text('Dashboard'),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final unreadCountAsync = ref.watch(unreadNotificationCountProvider);
              final count = unreadCountAsync.valueOrNull ?? 0;

              return IconButton(
                icon: Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  child: const Icon(Icons.notifications),
                ),
                onPressed: () => context.push('/notifications'),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () async {
                        Navigator.pop(context); // Close dialog
                        await ref.read(authRepositoryProvider).signOut();
                        if (context.mounted) context.go('/login');
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      );
  }


  Widget _buildUserDashboard(
    BuildContext context,
    WidgetRef ref,
    String? email,
    AsyncValue<List<InvestorRequest>> requestsAsync,
  ) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome,',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                email ?? 'User',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
               // Check Referral Status
              userProfileAsync.when(
                data: (profile) {
                   debugPrint('Dashboard UI Profile Check: $profile');
                   if (profile != null) {
                      debugPrint("ReferredBy: ${profile['referred_by']}");
                      debugPrint("Role: ${profile['role']}");
                   }
                   
                   if (profile != null && profile['referred_by'] == null && profile['role'] == 'user') {
                     return Padding(
                       padding: const EdgeInsets.only(top: 8.0),
                       child: TextButton.icon(
                         onPressed: () => context.push('/enter-referral').then((_) => ref.refresh(userProfileProvider)),
                         icon: const Icon(Icons.confirmation_number),
                         label: const Text('Enter Referral Code'),
                         style: TextButton.styleFrom(backgroundColor: Colors.blue.withOpacity(0.1)),
                       ),
                     );
                   }
                   return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (err, stack) {
                   debugPrint('UserProfileProvider UI Error: $err');
                   return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),

        Expanded(
          child: requestsAsync.when(
            data: (requests) {
              if (requests.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(userRequestsProvider),
                  child: ListView(
                    children: [
                      const SizedBox(height: 100),
                      Center(
                        child: Column(
                          children: [
                            const Icon(Icons.folder_open, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text(
                              'No requests found',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            const Text('Start by creating a new investment request.'),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              // LIST OF REQUESTS
              return RefreshIndicator(
                onRefresh: () async => ref.refresh(userRequestsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () {
                          if (request.status == 'Draft') {
                            ref.read(onboardingFormProvider.notifier).setRequest(request);
                            context.push('/onboarding');
                          } else if (request.status == 'Investment Confirmed') {
                            context.push('/investment-dashboard', extra: request);
                          } else {
                            context.push('/request/${request.id}');
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header: ID and Status
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    request.investorId ?? 'Pending ID',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey[600]),
                                  ),
                                  _buildStatusChip(request.status),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // Plan Name (Large)
                              Text(
                                request.planName,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              
                              // Amount and Date
                              Row(
                                children: [
                                  Text(
                                    '₹${request.parsedAmount.toStringAsFixed(0)}',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text('•', style: TextStyle(color: Colors.grey)),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat.yMMMd().format(request.createdAt ?? DateTime.now()),
                                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 8),

                              // Actions Bar
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (request.status == 'Draft')
                                    TextButton.icon(
                                      onPressed: () async {
                                         // Delete logic (abridged for brevity, same as before)
                                         final confirm = await showDialog<bool>(
                                           context: context,
                                           builder: (c) => AlertDialog(
                                              title: const Text('Delete?'),
                                              content: const Text('Delete this draft?'),
                                              actions: [
                                                TextButton(onPressed: ()=>Navigator.pop(c,false), child: const Text('Cancel')),
                                                TextButton(onPressed: ()=>Navigator.pop(c,true), style: TextButton.styleFrom(foregroundColor: Colors.red), child: const Text('Delete')),
                                              ]
                                           ),
                                         );
                                         if(confirm == true) {
                                            await ref.read(investorRepositoryProvider).deleteRequest(request.id!);
                                            ref.refresh(userRequestsProvider);
                                         }
                                      },
                                      icon: const Icon(Icons.delete, size: 18),
                                      label: const Text('Delete'),
                                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                                    ),

                                  if (request.status == 'Approved')
                                    FilledButton(
                                      onPressed: () => context.push('/submit-utr/${request.id}'),
                                      child: const Text('Pay Now'),
                                    ),

                                  if (request.status == 'Investment Confirmed') ...[
                                      OutlinedButton(
                                        onPressed: () => context.push('/payout-history/${request.id}'),
                                        child: const Text('Payouts'),
                                      ),
                                      const SizedBox(width: 8),
                                      FilledButton.icon(
                                        onPressed: () => context.push('/investment-dashboard', extra: request),
                                        label: const Text('View Dashboard'),
                                        icon: const Icon(Icons.dashboard_customize, size: 18),
                                      ),
                                  ],
                                  
                                  if (request.status != 'Approved' && request.status != 'Investment Confirmed' && request.status != 'Draft')
                                    OutlinedButton(
                                      onPressed: () => context.push('/request/${request.id}'),
                                      child: const Text('View Details'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },

            loading: () =>
                const Center(child: CircularProgressIndicator()),

            error: (err, stack) =>
                Center(child: Text('Error: $err')),
          ),
        ),
      ],
    );
  }


  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'approved':
        color = Colors.blue; // Action required
        break;
      case 'rejected':
        color = Colors.red;
        break;
      case 'utr submitted':
        color = Colors.purple;
        break;
      case 'investment confirmed':
        color = Colors.green;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}
