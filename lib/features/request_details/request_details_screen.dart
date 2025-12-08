import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:investorapp_eminates/features/auth/providers/auth_provider.dart';
import 'package:investorapp_eminates/features/dashboard/providers/dashboard_provider.dart';
import 'package:investorapp_eminates/features/onboarding/providers/onboarding_provider.dart';
import 'package:investorapp_eminates/models/investor_request.dart';
import 'package:investorapp_eminates/services/storage_service.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class RequestDetailsScreen extends ConsumerWidget {
  final String requestId;

  const RequestDetailsScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestAsync = ref.watch(investorRequestDetailsProvider(requestId));
    final isAdminAsync = ref.watch(isAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Details'),
      ),
      body: requestAsync.when(
        data: (request) {
          return isAdminAsync.when(
            data: (isAdmin) => _buildContent(context, ref, request, isAdmin),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, InvestorRequest request, bool isAdmin) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, ref, request, isAdmin),
          const SizedBox(height: 24),
          if (isAdmin && (request.status == 'Pending' || request.status == 'UTR Submitted' || request.status == 'Investment Confirmed' || (request.status == 'Approved' && request.transactionUtr != null)))
             _buildAdminActions(context, ref, request),
          const SizedBox(height: 24),
          
          // Payment Information Section (New)
          if (request.transactionUtr != null || request.status == 'Investment Confirmed')
            _buildSection(context, 'Payment Information', [
              _buildDetailRow('Status', request.status),
              _buildDetailRow('UTR / Transaction ID', request.transactionUtr ?? 'N/A'),
              _buildDetailRow('Payment Date', _formatDate(request.transactionDate)),
            ]),

          _buildSection(context, 'Personal Information', [
            _buildDetailRow('Full Name', request.fullName),
            // ... existing fields remains same
            _buildDetailRow('Father\'s Name', request.fatherName),
            _buildDetailRow('Mother\'s Name', request.motherName),
            _buildDetailRow('DOB', _formatDate(request.dob)),
            _buildDetailRow('Nationality', request.nationality),
            _buildDetailRow('Native Place', request.nativePlace),
            _buildDetailRow('Education', request.education),
            _buildDetailRow('Occupation', request.occupation),
            _buildDetailRow('Monthly Income', request.monthlyIncome),
            _buildDetailRow('Gender', request.gender),
            _buildDetailRow('Marital Status', request.maritalStatus),
          ]),
          // ... rest of sections
          _buildSection(context, 'Residential Address', [
            _buildDetailRow('Door/Flat No', request.addressDoorNo),
            _buildDetailRow('Street/Area', request.addressStreet),
            _buildDetailRow('City', request.addressCity),
            _buildDetailRow('District', request.addressDistrict),
            _buildDetailRow('State', request.addressState),
            _buildDetailRow('Pincode', request.addressPincode),
            _buildDetailRow('Landmark', request.addressLandmark),
          ]),
          _buildSection(context, 'Contact Details', [
            _buildDetailRow('Primary Mobile', request.primaryMobile),
            _buildDetailRow('Alternate Mobile', request.alternateMobile),
            _buildDetailRow('WhatsApp', request.whatsappNumber),
            _buildDetailRow('Email', request.emailAddress),
          ]),
          _buildSection(context, 'KYC Details', [
            _buildDetailRow('PAN', request.panNumber),
            _buildImageRow(context, ref, 'PAN Card', request.panCardUrl),
            _buildDetailRow('Aadhaar', request.aadhaarNumber),
            _buildImageRow(context, ref, 'Aadhaar Card', request.aadhaarCardUrl),
            _buildDetailRow('Voter ID', request.voterId),
            _buildDetailRow('Passport', request.passportNumber),
            _buildImageRow(context, ref, 'Selfie', request.selfieUrl),
          ]),
          _buildSection(context, 'Bank Details', [
            _buildDetailRow('Bank Name', request.bankName),
            _buildDetailRow('Account Holder', request.accountHolderName),
            _buildDetailRow('Account Number', request.accountNumber),
            _buildDetailRow('IFSC Code', request.ifscCode),
            _buildDetailRow('Branch', request.branchNameLocation),
          ]),
          _buildSection(context, 'Nominee Details', [
            _buildDetailRow('Name', request.nomineeName),
            _buildDetailRow('Relationship', request.nomineeRelationship),
            _buildDetailRow('DOB', _formatDate(request.nomineeDob)),
            _buildDetailRow('Contact', request.nomineeContact),
            _buildDetailRow('Address', request.nomineeAddress),
          ]),
          _buildSection(context, 'Investment', [
            _buildDetailRow('Amount/Package', request.investmentAmount),
          ]),
          _buildSection(context, 'Declaration', [
            _buildDetailRow('Place', request.declarationPlace),
            _buildDetailRow('Date', _formatDate(request.declarationDate)),
            _buildDetailRow('Confirmed', request.isConfirmed ? 'Yes' : 'No'),
          ]),
        ],
      ),
    );
  }

  // ... (Header Widget remains same, skipping for brevity in replacement if not modified, but I need to modify AdminActions)

  // Wait, I need to update _buildAdminActions separately or include it.
  // Let's rely on the replace tool's context. I replaced _buildContent which calls _buildAdminActions.
  // But _buildAdminActions is defined further down. I should have replaced the whole admin actions widget too.
  // I will make a SECOND chunk for _buildAdminActions to add the Confirm button.
  
  // Actually, I can do it in one go if I include it, but the file is large.
  // I'll do _buildContent first, then _buildAdminActions in another call or same call different chunk.
  
  // Let's replace _buildAdminActions specifically.


  Widget _buildHeader(BuildContext context, WidgetRef ref, InvestorRequest request, bool isAdmin) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.investorId ?? 'Pending ID',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text('Submitted: ${_formatDate(request.createdAt)}'),
                  ],
                ),
                _buildStatusChip(request.status),
              ],
            ),
            if (!isAdmin && request.status.toLowerCase() == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        // Load request into onboarding provider
                        ref.read(onboardingFormProvider.notifier).setRequest(request);
                        // Navigate to onboarding
                        context.push('/onboarding');
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Request?'),
                            content: const Text('Are you sure you want to delete this request? This action cannot be undone.'),
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
                                const SnackBar(content: Text('Request deleted successfully')),
                              );
                              context.pop(); // Go back to dashboard
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        }
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdminActions(BuildContext context, WidgetRef ref, InvestorRequest request) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Admin Actions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                if (request.status == 'Pending') ...[
                  FilledButton.icon(
                    onPressed: () => _updateStatus(context, ref, request.id!, 'Approved'),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.green),
                  ),
                  FilledButton.icon(
                    onPressed: () => _updateStatus(context, ref, request.id!, 'Rejected'),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ],
                if (request.status == 'UTR Submitted' || (request.status == 'Approved' && request.transactionUtr != null))
                  FilledButton.icon(
                    onPressed: () => _updateStatus(context, ref, request.id!, 'Investment Confirmed'),
                    icon: const Icon(Icons.verified_user),
                    label: const Text('Confirm Investment'),
                    style: FilledButton.styleFrom(backgroundColor: Colors.purple),
                  ),
                if (request.status == 'Investment Confirmed')
                   FilledButton.icon(
                    onPressed: () => context.push('/payout-history/${request.id}'),
                    icon: const Icon(Icons.history),
                    label: const Text('Payouts'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, WidgetRef ref, String id, String status) async {
    try {
      await ref.read(investorRepositoryProvider).updateRequestStatus(id, status);
      ref.invalidate(investorRequestDetailsProvider(id));
      ref.invalidate(allRequestsProvider); // Refresh admin list
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request $status')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ...children,
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildImageRow(BuildContext context, WidgetRef ref, String label, String? path) {
    if (path == null || path.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          FutureBuilder<String>(
            future: ref.read(storageServiceProvider).getSignedUrl(path),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return Text('Error loading file', style: TextStyle(color: Colors.red.shade300));
              }
              if (snapshot.hasData) {
                final url = snapshot.data!;
                final isPdf = path.toLowerCase().endsWith('.pdf');

                if (isPdf) {
                  return InkWell(
                    onTap: () async {
                      try {
                        final response = await http.get(Uri.parse(url));
                        final dir = await getTemporaryDirectory();
                        final file = File('${dir.path}/temp.pdf');
                        await file.writeAsBytes(response.bodyBytes);

                        if (context.mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Scaffold(
                                appBar: AppBar(title: Text(label)),
                                body: PDFView(
                                  filePath: file.path,
                                ),
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                         if (context.mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(
                             SnackBar(content: Text('Could not load PDF: $e')),
                           );
                         }
                      }
                    },
                    child: Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.picture_as_pdf, size: 40, color: Colors.red),
                          SizedBox(height: 8),
                          Text('Tap to View PDF'),
                        ],
                      ),
                    ),
                  );
                }

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Scaffold(
                          backgroundColor: Colors.black,
                          appBar: AppBar(
                            backgroundColor: Colors.black,
                            iconTheme: const IconThemeData(color: Colors.white),
                          ),
                          body: PhotoView(
                            imageProvider: NetworkImage(url),
                            minScale: PhotoViewComputedScale.contained,
                            maxScale: PhotoViewComputedScale.covered * 2,
                          ),
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      url,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Text('Failed to load image'),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
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

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat.yMMMd().format(date);
  }
}

// Provider for single request details
final investorRequestDetailsProvider = FutureProvider.autoDispose.family<InvestorRequest, String>((ref, id) async {
  return ref.watch(investorRepositoryProvider).getRequestById(id);
});

// Import storage service
// We need to add imports at the top, but this tool call is for replacement of the bottom part.
// I'll add the import via a separate tool call to avoid messing up the whole file context.

