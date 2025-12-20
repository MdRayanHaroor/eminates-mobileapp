import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';

class SupportDialog extends StatelessWidget {
  const SupportDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Support & FAQ', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFaqItem(
                'How do I make an investment?',
                'Navigate to the "Plans" tab, select a plan, and follow the instructions to submit your investment request.',
              ),
              _buildFaqItem(
                'How long does verification take?',
                'Verification usually takes 24-48 hours after you submit your UTR details.',
              ),
              _buildFaqItem(
                'Can I withdraw my investment early?',
                'Withdrawal policies depend on the lock-in period of your selected plan. Please check the plan details.',
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Text('Still have questions?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Contact our admin team directly via email.'),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        FilledButton.icon(
          onPressed: () => _launchEmail(context),
          icon: const Icon(Icons.email),
          label: const Text('Contact Admin'),
        ),
      ],
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return ExpansionTile(
      title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(answer, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ),
      ],
    );
  }

  Future<void> _launchEmail(BuildContext context) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'eminatesholdings@gmail.com',
      query: _encodeQueryParameters(<String, String>{
        'subject': 'Support Request: Eminates App',
      }),
    );

    try {
      // mode: LaunchMode.externalApplication is highly recommended for mailto
      await launchUrl(
        emailLaunchUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Error launching email: $e');
      // Optional: Show a SnackBar to the user if it fails and copy the email address to clipboard
      await Clipboard.setData(ClipboardData(text: 'eminatesholdings@gmail.com'));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to launch email, email address copied to clipboard')),
      );
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }
}
