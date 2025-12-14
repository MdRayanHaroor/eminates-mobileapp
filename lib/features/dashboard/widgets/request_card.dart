import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:investorapp_eminates/models/investor_request.dart';
import 'package:investorapp_eminates/features/onboarding/providers/onboarding_provider.dart';

class RequestCard extends ConsumerWidget {
  final InvestorRequest request;
  const RequestCard({super.key, required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = _getStatusColor(request.status);
    final isConfirmed = request.status.toLowerCase() == 'investment confirmed';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey[100]!),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (request.status == 'Draft') {
              ref.read(onboardingFormProvider.notifier).setRequest(request);
              ref.read(onboardingStepProvider.notifier).state = 0;
              context.push('/onboarding');
            } else {
               context.push('/request/${request.id}');
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Colorful accent strip
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 6,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Expanded(
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text(
                                 request.effectivePlanName,
                                 style: GoogleFonts.outfit(
                                   color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                                   fontWeight: FontWeight.w600,
                                   fontSize: 14,
                                 ),
                               ),
                               const SizedBox(height: 4),
                               Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                   Text(
                                      '₹',
                                      style: TextStyle(
                                         color: color,
                                         fontSize: 20,
                                         fontWeight: FontWeight.bold,
                                      ),
                                   ),
                                   const SizedBox(width: 4),
                                   Text(
                                      request.parsedAmount.toStringAsFixed(0),
                                      style: GoogleFonts.outfit(
                                         color: theme.textTheme.titleLarge?.color, 
                                         fontSize: 28,
                                         fontWeight: FontWeight.bold,
                                      ),
                                   ),
                                ],
                               ),
                             ],
                           ),
                         ),
                         _buildStatusChip(request.status),
                      ],
                     ),
                     const SizedBox(height: 16),
                     const Divider(height: 1),
                     const SizedBox(height: 12),
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(
                               'Date',
                               style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                             ),
                             Text(
                               DateFormat.yMMMd().format(request.createdAt ?? DateTime.now()),
                               style: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 13),
                             ),
                           ],
                         ),
                         // Add Tenue if available
                         if (request.selectedTenure != null)
                         Column(
                           crossAxisAlignment: CrossAxisAlignment.end,
                           children: [
                             Text(
                               'Tenure',
                               style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey),
                             ),
                             Text(
                               '${request.selectedTenure} Months',
                               style: GoogleFonts.outfit(fontWeight: FontWeight.w500, fontSize: 13),
                             ),
                           ],
                         ),
                       ],
                     ),
                     if (isConfirmed) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => context.push('/payout-history/${request.id}'),
                            icon: const Icon(Icons.payments_outlined, size: 18),
                            label: const Text('View Payouts'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color.withOpacity(0.1),
                              foregroundColor: color,
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                     ],
                     if (request.status.toLowerCase() == 'rejected' && request.rejectionReason != null) ...[
                        const SizedBox(height: 12),
                         Container(
                           width: double.infinity,
                           padding: const EdgeInsets.all(12),
                           decoration: BoxDecoration(
                             color: Colors.red.shade50,
                             borderRadius: BorderRadius.circular(8),
                             border: Border.all(color: Colors.red.shade100),
                           ),
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text(
                                 'Reason for Rejection:',
                                 style: GoogleFonts.outfit(
                                   color: Colors.red.shade800,
                                   fontWeight: FontWeight.bold,
                                   fontSize: 12,
                                 ),
                               ),
                               const SizedBox(height: 4),
                               Text(
                                 request.rejectionReason!,
                                 style: GoogleFonts.outfit(
                                   color: Colors.red.shade700,
                                   fontSize: 12,
                                 ),
                                 maxLines: 2,
                                 overflow: TextOverflow.ellipsis,
                               ),
                             ],
                           ),
                         ),
                     ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: GoogleFonts.outfit(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return Colors.blue;
      case 'rejected': return Colors.red;
      case 'utr submitted': return Colors.purple;
      case 'investment confirmed': return const Color(0xFF00C853); // Bright Green
      case 'pending': return Colors.orange;
      default: return Colors.grey;
    }
  }
}
