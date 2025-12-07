import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:investorapp_eminates/features/auth/providers/auth_provider.dart';
import 'package:investorapp_eminates/features/dashboard/admin_dashboard_screen.dart';
import 'package:investorapp_eminates/features/dashboard/providers/dashboard_provider.dart';
import 'package:investorapp_eminates/features/onboarding/providers/onboarding_provider.dart';
import 'package:investorapp_eminates/models/investor_request.dart';
import 'package:intl/intl.dart';
import 'package:investorapp_eminates/core/utils/error_utils.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ... build method remains same
    final user = ref.watch(currentUserProvider);
    final requestsAsync = ref.watch(userRequestsProvider);
    final isAdminAsync = ref.watch(isAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
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
      ),
      body: isAdminAsync.when(
        data: (isAdmin) {
          if (isAdmin) {
            return const AdminDashboardScreen();
          }
          return _buildUserDashboard(context, ref, user?.email, requestsAsync);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref.read(onboardingFormProvider.notifier).resetState();
          ref.read(onboardingStepProvider.notifier).state = 0; // Reset to first step
          context.push('/onboarding');
        },
        label: const Text('New Investment'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildUserDashboard(
    BuildContext context,
    WidgetRef ref,
    String? email,
    AsyncValue<List<InvestorRequest>> requestsAsync,
  ) {
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
                          mainAxisAlignment: MainAxisAlignment.center,
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
              return RefreshIndicator(
                onRefresh: () async => ref.refresh(userRequestsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        title: Text(request.investorId ?? 'Pending ID'),
                        subtitle: Text(
                          'Submitted on ${DateFormat.yMMMd().format(request.createdAt ?? DateTime.now())}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildStatusChip(request.status),
                            if (request.status == 'Draft') ...[
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Draft?'),
                                      content: const Text('Are you sure you want to delete this draft?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirm == true) {
                                    try {
                                      await ref.read(investorRepositoryProvider).deleteRequest(request.id!);
                                      ref.refresh(userRequestsProvider);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Draft deleted successfully')),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(ErrorUtils.getFriendlyErrorMessage(e)),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                              ),
                            ],
                          ],
                        ),
                        onTap: () {
                          if (request.status == 'Draft') {
                            ref.read(onboardingFormProvider.notifier).setRequest(request);
                            context.push('/onboarding');
                          } else {
                            context.push('/request/${request.id}');
                          }
                        },
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'approved':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
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
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
