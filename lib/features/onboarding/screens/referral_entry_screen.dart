import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:investorapp_eminates/features/auth/providers/auth_provider.dart';

class ReferralEntryScreen extends ConsumerStatefulWidget {
  const ReferralEntryScreen({super.key});

  @override
  ConsumerState<ReferralEntryScreen> createState() => _ReferralEntryScreenState();
}

class _ReferralEntryScreenState extends ConsumerState<ReferralEntryScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _submitCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser!.id;
      final code = _codeController.text.trim();

      // Use RPC for atomic and secure redemption
      await supabase.rpc('redeem_referral_code', params: {
        'code_input': code
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Referral code applied successfully!')),
        );
        ref.refresh(currentUserProvider); // Refresh user to update UI possibly
        context.pop();
      }

    } on PostgrestException catch (e) {
      if (mounted) {
        String message = e.message;
        if (message.toLowerCase().contains('expired')) {
          message = 'This referral code has expired.';
        } else if (message.toLowerCase().contains('invalid') || message.toLowerCase().contains('not found')) {
          message = 'Invalid referral code. Please check and try again.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred. Please try again.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter Referral Code')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.confirmation_number_outlined, size: 64, color: Colors.blue),
              const SizedBox(height: 24),
              const Text(
                'Got a code?',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter the 4-digit code shared by your agent.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _codeController,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                maxLength: 4,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  counterText: '',
                  border: OutlineInputBorder(),
                  hintText: '0000',
                ),
                validator: (v) => (v == null || v.length != 4) ? 'Enter 4 digits' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submitCode,
                  style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
                  child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Text('Apply Code'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
