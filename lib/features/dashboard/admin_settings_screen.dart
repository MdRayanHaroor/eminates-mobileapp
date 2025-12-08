import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:investorapp_eminates/features/dashboard/providers/dashboard_provider.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bankNameCtrl = TextEditingController();
  final _holderCtrl = TextEditingController();
  final _accNumCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final details = await ref.read(investorRepositoryProvider).getAppSetting('bank_details');
      if (details != null) {
        _bankNameCtrl.text = details['bank_name'] ?? '';
        _holderCtrl.text = details['account_holder'] ?? '';
        _accNumCtrl.text = details['account_number'] ?? '';
        _ifscCtrl.text = details['ifsc_code'] ?? '';
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final newDetails = {
        'bank_name': _bankNameCtrl.text.trim(),
        'account_holder': _holderCtrl.text.trim(),
        'account_number': _accNumCtrl.text.trim(),
        'ifsc_code': _ifscCtrl.text.trim(),
      };

      await ref.read(investorRepositoryProvider).saveAppSetting('bank_details', newDetails);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bank details updated successfully')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _bankNameCtrl.dispose();
    _holderCtrl.dispose();
    _accNumCtrl.dispose();
    _ifscCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Settings')),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bank Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bankNameCtrl,
                      decoration: const InputDecoration(labelText: 'Bank Name', border: OutlineInputBorder()),
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _holderCtrl,
                      decoration: const InputDecoration(labelText: 'Account Holder Name', border: OutlineInputBorder()),
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _accNumCtrl,
                      decoration: const InputDecoration(labelText: 'Account Number', border: OutlineInputBorder()),
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ifscCtrl,
                      decoration: const InputDecoration(labelText: 'IFSC Code', border: OutlineInputBorder()),
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _saveSettings,
                        child: const Text('Save Settings'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
