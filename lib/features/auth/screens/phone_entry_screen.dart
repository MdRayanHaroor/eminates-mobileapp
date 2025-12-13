import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:investorapp_eminates/features/auth/providers/auth_provider.dart';
import 'package:investorapp_eminates/core/services/phone_verification_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PhoneEntryScreen extends ConsumerStatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final phone = _phoneController.text.trim();
      await ref.read(authRepositoryProvider).updatePhoneNumber(phone);
      
      final user = ref.read(currentUserProvider);
      if (user != null) {
        PhoneVerificationService.setVerified(user.id);
      }

      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating phone number: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    // Try to get name from user metadata, fallback to email nick if possible
    final fullName = user?.userMetadata?['full_name'] as String? ?? 
                     user?.userMetadata?['name'] as String? ?? 
                     user?.email?.split('@').first ?? 'User';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authRepositoryProvider).signOut();
              if (mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Welcome Icon
                const Icon(
                  Icons.waving_hand_rounded,
                  size: 64,
                  color: Colors.amber,
                ).animate()
                 .scale(duration: 600.ms, curve: Curves.elasticOut)
                 .then()
                 .shake(duration: 1000.ms),
                
                const SizedBox(height: 24),
                
                // Welcome Text
                Text(
                  'Welcome, $fullName!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.3, end: 0),
                
                const SizedBox(height: 8),
                
                // Thank You Text
                Text(
                  'Thank you for joining Eminates Holdings.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

                const SizedBox(height: 48),

                // Instruction
                const Text(
                  'To finalize your account setup, please enter your mobile number below.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
                
                const SizedBox(height: 24),
                
                // Phone Input
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '+91 XXXXX XXXXX',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (value.length < 10) {
                       return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 600.ms, duration: 500.ms).slideX(begin: -0.1, end: 0),
                
                const SizedBox(height: 32),
                
                // Submit Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24, 
                            width: 24, 
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text('Complete Setup', style: TextStyle(fontSize: 16)),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded),
                            ],
                          ),
                  ),
                ).animate().fadeIn(delay: 800.ms, duration: 500.ms).scale(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
