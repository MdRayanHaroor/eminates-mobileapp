import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:investorapp_eminates/core/utils/error_utils.dart';
import 'package:investorapp_eminates/features/dashboard/providers/dashboard_provider.dart';
import 'package:investorapp_eminates/repositories/investor_repository.dart';

class SubmitUtrScreen extends ConsumerStatefulWidget {
  final String requestId;

  const SubmitUtrScreen({super.key, required this.requestId});

  @override
  ConsumerState<SubmitUtrScreen> createState() => _SubmitUtrScreenState();
}

class _SubmitUtrScreenState extends ConsumerState<SubmitUtrScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  Map<String, dynamic> _bankDetails = {
    "bank_name": "Loading...",
    "account_holder": "",
    "account_number": "",
    "ifsc_code": ""
  };

  @override
  void initState() {
    super.initState();
    _loadBankDetails();
  }

  Future<void> _loadBankDetails() async {
    final details = await ref.read(investorRepositoryProvider).getAppSetting('bank_details');
    if (details != null && mounted) {
      setState(() => _bankDetails = details);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(investorRepositoryProvider).submitUtr(
            widget.requestId,
            _controller.text.trim(),
          );
      
      // Refresh requests to update dashboard
      ref.invalidate(userRequestsProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment details submitted successfully!')),
        );
        context.pop(); // Go back to dashboard
      }
    } catch (e) {
      debugPrint('Error submitting UTR: $e'); // Log full error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'), // Show full error in SnackBar for user visibility during debug
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Payment Details')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 48), // 48 is padding
              child: IntrinsicHeight(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Payment Verification',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Please enter the UTR (Unique Transaction Reference) number found on your bank transaction receipt. This helps us verify your investment.',
                        style: TextStyle(color: Colors.grey, height: 1.5),
                      ),
                      const SizedBox(height: 24),
                      // Bank Details Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.05),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.account_balance, color: Colors.blue, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Bank Details for Payment',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            _buildDetailRow('Bank Name', _bankDetails['bank_name'] ?? 'N/A'),
                            const SizedBox(height: 8),
                            _buildDetailRow('Account Holder', _bankDetails['account_holder'] ?? 'N/A'),
                            const SizedBox(height: 8),
                            _buildDetailRow('Account Number', _bankDetails['account_number'] ?? 'N/A'),
                            const SizedBox(height: 8),
                            _buildDetailRow('IFSC Code', _bankDetails['ifsc_code'] ?? 'N/A'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          labelText: 'UTR / Transaction ID',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.receipt_long),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the UTR number';
                          }
                          if (value.trim().length < 6) {
                            return 'Invalid UTR format';
                          }
                          return null;
                        },
                      ),
                      const Spacer(),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _submit,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Submit Details'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
        SelectableText(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }
}
