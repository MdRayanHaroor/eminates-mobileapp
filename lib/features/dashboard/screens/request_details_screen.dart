import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:investorapp_eminates/models/investor_request.dart';
import 'package:investorapp_eminates/features/dashboard/providers/dashboard_provider.dart';

class RequestDetailsScreen extends ConsumerWidget {
  final String requestId;

  const RequestDetailsScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We can fetch the specific request from the list or a dedicated provider
    // For now, let's look it up from the list for simplicity if available
    final requestsAsync = ref.watch(userRequestsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Investment Details'),
        centerTitle: true,
      ),
      body: requestsAsync.when(
        data: (requests) {
          final request = requests.firstWhere(
            (r) => r.id == requestId,
            orElse: () => const InvestorRequest(userId: ''), // Dummy fallback
          );

          if (request.userId.isEmpty) {
            return const Center(child: Text('Request not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, request),
                const SizedBox(height: 24),
                
                // Rejection Alert
                if (request.status.toLowerCase() == 'rejected' && request.rejectionReason != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Request Rejected',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade900,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          request.rejectionReason!,
                          style: GoogleFonts.outfit(
                            color: Colors.red.shade800,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please revise your application and submit a new request or contact support.',
                          style: GoogleFonts.outfit(
                            color: Colors.red.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                _buildSectionTitle('Plan Information'),
                const SizedBox(height: 12),
                _buildInfoCard([
                  _InfoItem('Plan', request.effectivePlanName),
                  _InfoItem('Amount', '₹${request.parsedAmount.toStringAsFixed(0)}'),
                  if (request.selectedTenure != null)
                    _InfoItem('Tenure', '${request.selectedTenure} Months'),
                ]),

                const SizedBox(height: 24),
                _buildSectionTitle('Investor Profile'),
                const SizedBox(height: 12),
                _buildInfoCard([
                  _InfoItem('Name', request.fullName ?? '-'),
                  _InfoItem('Mobile', request.primaryMobile ?? '-'),
                  _InfoItem('Email', request.emailAddress ?? '-'),
                  _InfoItem('City', request.addressCity ?? '-'),
                ]),

                const SizedBox(height: 24),
                _buildSectionTitle('Bank Details'),
                const SizedBox(height: 12),
                _buildInfoCard([
                  _InfoItem('Bank Name', request.bankName ?? '-'),
                  _InfoItem('Account No.', _mask(request.accountNumber)),
                  _InfoItem('IFSC', request.ifscCode ?? '-'),
                  _InfoItem('Holder', request.accountHolderName ?? '-'),
                ]),
                
                const SizedBox(height: 24),
                _buildSectionTitle('Nominee Details'),
                const SizedBox(height: 12),
                _buildInfoCard([
                   _InfoItem('Name', request.nomineeName ?? '-'),
                   _InfoItem('Relation', request.nomineeRelationship ?? '-'),
                ]),

                if (request.status.toLowerCase() == 'investment confirmed') ... [
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/payout-history/${request.id}'),
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text('View Payout History'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 40),
            ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, InvestorRequest request) {
    Color color = _getStatusColor(request.status);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status',
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  request.status.toUpperCase(),
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            request.effectivePlanName,
             style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
          ),
          const SizedBox(height: 4),
          Text(
             'ID: ${request.id?.substring(0, 8).toUpperCase() ?? '-'}',
             style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }
  
  Widget _buildInfoCard(List<_InfoItem> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.label,
                  style: GoogleFonts.outfit(color: Colors.grey.shade600, fontSize: 14),
                ),
                Text(
                  item.value,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
  
  String _mask(String? text) {
    if (text == null || text.length < 4) return text ?? '-';
    return '**** ' + text.substring(text.length - 4);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return Colors.blue;
      case 'rejected': return Colors.red;
      case 'utr submitted': return Colors.purple;
      case 'investment confirmed': return Colors.green;
      case 'pending': return Colors.orange;
      default: return Colors.grey;
    }
  }
}

class _InfoItem {
  final String label;
  final String value;
  _InfoItem(this.label, this.value);
}
