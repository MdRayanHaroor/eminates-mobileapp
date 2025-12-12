import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:investorapp_eminates/models/investor_request.dart';
import 'package:investorapp_eminates/services/storage_service.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:photo_view/photo_view.dart';
import 'dart:io';

class InvestmentDocumentsScreen extends ConsumerWidget {
  final InvestorRequest request;

  const InvestmentDocumentsScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Investment Documents')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Plan Details'),
            _buildInfoCard([
              _buildRow('Plan Name', request.effectivePlanName),
              _buildRow('Amount', '₹${request.parsedAmount.toStringAsFixed(0)}'),
              _buildRow('Status', request.status),
              _buildRow('Date Joined', DateFormat.yMMMd().format(request.createdAt ?? DateTime.now())),
            ]),
            const SizedBox(height: 24),

            _buildSectionHeader('Investor Details'),
            _buildInfoCard([
              _buildRow('Name', request.fullName ?? 'N/A'),
              _buildRow('Email', request.emailAddress ?? 'N/A'),
              _buildRow('Phone', request.primaryMobile ?? 'N/A'),
              _buildRow('Address', '${request.addressCity ?? ''}, ${request.addressState ?? ''}'),
              _buildRow('Nominee', request.nomineeName ?? 'N/A'),
            ]),
            const SizedBox(height: 24),

            _buildSectionHeader('Submitted Documents'),
            const SizedBox(height: 8),
            _buildDocumentTile(context, ref, 'Aadhaar Card', Icons.credit_card, request.aadhaarCardUrl),
            _buildDocumentTile(context, ref, 'PAN Card', Icons.badge, request.panCardUrl),
             if (request.selfieUrl != null)
              _buildDocumentTile(context, ref, 'Photo', Icons.person, request.selfieUrl),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildDocumentTile(BuildContext context, WidgetRef ref, String title, IconData icon, String? path) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withOpacity(0.1),
          child: Icon(icon, color: Colors.blue),
        ),
        title: Text(title),
        subtitle: Text(path != null ? 'Tap to view' : 'Not uploaded'),
        trailing: const Icon(Icons.open_in_new, size: 18, color: Colors.grey),
        onTap: () async {
          if (path != null) {
            try {
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator()),
              );

              // 1. Get Signed URL
              final url = await ref.read(storageServiceProvider).getSignedUrl(path);

              if (context.mounted) {
                Navigator.pop(context); // Dismiss loading
                _openDocumentViewer(context, title, url, path);
              }
            } catch (e) {
              if (context.mounted) {
                Navigator.pop(context); // Dismiss loading
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error loading document: $e')),
                );
              }
            }
          } else {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Document not uploaded')),
             );
          }
        },
      ),
    );
  }

  void _openDocumentViewer(BuildContext context, String title, String url, String originalPath) async {
    final isPdf = originalPath.toLowerCase().endsWith('.pdf');

    if (isPdf) {
      try {
        final response = await http.get(Uri.parse(url));
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/temp_doc.pdf');
        await file.writeAsBytes(response.bodyBytes);

        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(title: Text(title)),
                body: PDFView(filePath: file.path),
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
    } else {
      // Image Viewer
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white),
              title: Text(title, style: const TextStyle(color: Colors.white)),
            ),
            body: PhotoView(
              imageProvider: NetworkImage(url),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 2,
              heroAttributes: PhotoViewHeroAttributes(tag: title),
              errorBuilder: (context, error, stackTrace) =>
                  const Center(child: Text('Failed to load image', style: TextStyle(color: Colors.white))),
            ),
          ),
        ),
      );
    }
  }
}
