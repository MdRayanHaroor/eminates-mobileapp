import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:investorapp_eminates/core/utils/error_utils.dart';

class UpdatePasswordScreen extends ConsumerStatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  ConsumerState<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends ConsumerState<UpdatePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _isCurrentVisible = false;
  bool _isNewVisible = false;
  bool _isConfirmVisible = false;

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;

    try {
      // 1. Verify Current Password (by signing in again)
      // Note: This works because we are already authenticated, but we want to ensure 
      // the user knows the current password before changing it.
      // Re-authentication is a good security practice.
      final email = supabase.auth.currentUser?.email;
      if (email == null) throw 'User not found';

      await supabase.auth.signInWithPassword(
        email: email, 
        password: _currentPasswordController.text,
      );

      // 2. Update to new password
      await supabase.auth.updateUser(
        UserAttributes(password: _newPasswordController.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully!')),
        );
        // Go back to dashboard
        if (mounted) {
          try {
            context.pop();
          } catch (e) {
            // navigate to dashboard screen
            context.go('/dashboard');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorUtils.getFriendlyErrorMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Password')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _currentPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_isCurrentVisible ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _isCurrentVisible = !_isCurrentVisible),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    obscureText: !_isCurrentVisible,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _newPasswordController,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_isNewVisible ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _isNewVisible = !_isNewVisible),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    obscureText: !_isNewVisible,
                    validator: (v) {
                      if (v!.isEmpty) return 'Required';
                      if (v.length < 6) return 'Min 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_isConfirmVisible ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _isConfirmVisible = !_isConfirmVisible),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    obscureText: !_isConfirmVisible,
                    validator: (v) {
                      if (v != _newPasswordController.text) return 'Passwords do not match';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _isLoading ? null : _updatePassword,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20, width: 20, 
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                          )
                        : const Text('Update Password'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
