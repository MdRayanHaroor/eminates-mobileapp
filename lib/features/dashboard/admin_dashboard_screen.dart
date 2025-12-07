import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:investorapp_eminates/features/dashboard/providers/dashboard_provider.dart';
import 'package:investorapp_eminates/models/investor_request.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allRequestsAsync = ref.watch(allRequestsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Admin Dashboard',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        Expanded(
          child: allRequestsAsync.when(
            data: (requests) {
              if (requests.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(allRequestsProvider),
                  child: ListView(
                    children: const [
                      SizedBox(height: 200),
                      Center(child: Text('No requests found')),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => ref.refresh(allRequestsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () => context.push('/request/${request.id}'),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                              Text(
                                request.fullName ?? 'Unknown Name',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                request.planName,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '₹${request.parsedAmount.toStringAsFixed(0)}',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _formatDate(request.createdAt),
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                ],
                              ),
                              if (request.status == 'UTR Submitted') ...[
                                 const SizedBox(height: 8),
                                 Container(
                                   padding: const EdgeInsets.all(8),
                                   decoration: BoxDecoration(
                                     color: Colors.orange.withOpacity(0.1),
                                     borderRadius: BorderRadius.circular(6),
                                     border: Border.all(color: Colors.orange.shade300),
                                   ),
                                   child: Row(
                                     children: [
                                       Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange[800]),
                                       const SizedBox(width: 8),
                                       Expanded(
                                         child: Text(
                                           'Verify payment received and confirm investment',
                                           style: TextStyle(fontSize: 12, color: Colors.orange[900]),
                                         ),
                                       ),
                                     ],
                                   ),
                                 ),
                              ],
                            ],
                          ),
                        ),
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
        color = Colors.blue; 
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

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat.yMMMd().format(date);
  }
}
