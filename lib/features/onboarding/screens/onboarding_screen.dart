import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:investorapp_eminates/features/onboarding/providers/onboarding_provider.dart';
import 'package:investorapp_eminates/features/onboarding/widgets/step_declaration.dart';
import 'package:investorapp_eminates/features/onboarding/widgets/step_financials.dart';
import 'package:investorapp_eminates/features/onboarding/widgets/step_investment.dart';
import 'package:investorapp_eminates/features/onboarding/widgets/step_kyc.dart';
import 'package:investorapp_eminates/features/onboarding/widgets/step_personal_contact.dart';
import 'package:investorapp_eminates/features/request_details/request_details_screen.dart';
import 'package:investorapp_eminates/core/utils/error_utils.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _isSubmitting = false;

  bool _validateCurrentStep(BuildContext context, WidgetRef ref, int step) {
    // ... validation logic remains same
    final state = ref.read(onboardingFormProvider);
    
    switch (step) {
      case 0: // Personal & Contact
        if ((state.fullName ?? '').isEmpty) return _showError(context, 'Full Name is required');
        if ((state.fatherName ?? '').isEmpty) return _showError(context, 'Father Name is required');
        if ((state.motherName ?? '').isEmpty) return _showError(context, 'Mother Name is required');
        if (state.dob == null) return _showError(context, 'Date of Birth is required');
        if ((state.nationality ?? '').isEmpty) return _showError(context, 'Nationality is required');
        if ((state.nativePlace ?? '').isEmpty) return _showError(context, 'Native Place is required');
        if ((state.education ?? '').isEmpty) return _showError(context, 'Education is required');
        if ((state.occupation ?? '').isEmpty) return _showError(context, 'Occupation is required');
        if ((state.monthlyIncome ?? '').isEmpty) return _showError(context, 'Monthly Income is required');
        if ((state.gender ?? '').isEmpty) return _showError(context, 'Gender is required');
        if ((state.maritalStatus ?? '').isEmpty) return _showError(context, 'Marital Status is required');
        
        if ((state.addressDoorNo ?? '').isEmpty) return _showError(context, 'Door No is required');
        if ((state.addressStreet ?? '').isEmpty) return _showError(context, 'Street is required');
        if ((state.addressCity ?? '').isEmpty) return _showError(context, 'City is required');
        if ((state.addressDistrict ?? '').isEmpty) return _showError(context, 'District is required');
        if ((state.addressState ?? '').isEmpty) return _showError(context, 'State is required');
        if ((state.addressPincode ?? '').isEmpty) return _showError(context, 'Pincode is required');
        
        if ((state.primaryMobile ?? '').isEmpty) return _showError(context, 'Primary Mobile is required');
        if (!RegExp(r'^[0-9]{10}$').hasMatch(state.primaryMobile ?? '')) return _showError(context, 'Invalid Primary Mobile (10 digits)');

        if ((state.whatsappNumber ?? '').isEmpty) return _showError(context, 'WhatsApp Number is required');
        if (!RegExp(r'^[0-9]{10}$').hasMatch(state.whatsappNumber ?? '')) return _showError(context, 'Invalid WhatsApp Number (10 digits)');

        if ((state.emailAddress ?? '').isEmpty) return _showError(context, 'Email is required');
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(state.emailAddress ?? '')) return _showError(context, 'Invalid Email Address');
        
        return true;

      case 1: // KYC
        if ((state.panNumber ?? '').isEmpty) return _showError(context, 'PAN Number is required');
        if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(state.panNumber ?? '')) return _showError(context, 'Invalid PAN Number');

        if ((state.aadhaarNumber ?? '').isEmpty) return _showError(context, 'Aadhaar Number is required');
        if (!RegExp(r'^[0-9]{12}$').hasMatch(state.aadhaarNumber ?? '')) return _showError(context, 'Invalid Aadhaar (12 digits)');
        
        return true;

      case 2: // Financials
        if ((state.bankName ?? '').isEmpty) return _showError(context, 'Bank Name is required');
        if ((state.accountHolderName ?? '').isEmpty) return _showError(context, 'Account Holder Name is required');
        if ((state.accountNumber ?? '').isEmpty) return _showError(context, 'Account Number is required');
        if ((state.ifscCode ?? '').isEmpty) return _showError(context, 'IFSC Code is required');
        if ((state.branchNameLocation ?? '').isEmpty) return _showError(context, 'Branch Name is required');
        
        if ((state.nomineeName ?? '').isEmpty) return _showError(context, 'Nominee Name is required');
        if ((state.nomineeRelationship ?? '').isEmpty) return _showError(context, 'Nominee Relationship is required');
        if (state.nomineeDob == null) return _showError(context, 'Nominee DOB is required');
        if ((state.nomineeContact ?? '').isEmpty) return _showError(context, 'Nominee Contact is required');
        if ((state.nomineeAddress ?? '').isEmpty) return _showError(context, 'Nominee Address is required');
        return true;

      case 3: // Investment
        if ((state.investmentAmount ?? '').isEmpty) return _showError(context, 'Investment Amount is required');
        return true;

      case 4: // Declaration
        if ((state.declarationPlace ?? '').isEmpty) return _showError(context, 'Place is required');
        if (!state.isConfirmed) return _showError(context, 'You must agree to the declaration');
        return true;
        
      default:
        return true;
    }
  }

  bool _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = ref.watch(onboardingStepProvider);

    // List of steps
    final steps = [
      const StepPersonalContact(),
      const StepKyc(),
      const StepFinancials(),
      const StepInvestment(),
      const StepDeclaration(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Investment Request'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            // Confirm exit
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Exit Form?'),
                content: const Text('Your progress will be lost.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      context.pop(); // Exit screen
                    },
                    child: const Text('Exit'),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: _isSubmitting
                ? null
                : () async {
                    setState(() => _isSubmitting = true);
                    try {
                      // Capture ID before submit
                      final currentRequestId = ref.read(onboardingFormProvider).id;
                      
                      await ref.read(onboardingFormProvider.notifier).saveAsDraft(ref);
                      
                      // Invalidate details provider if it was an update
                      if (currentRequestId != null && currentRequestId.isNotEmpty) {
                         ref.invalidate(investorRequestDetailsProvider(currentRequestId));
                      }

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Draft saved successfully!')),
                        );
                        context.go('/dashboard');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ErrorUtils.getFriendlyErrorMessage(e)),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isSubmitting = false);
                    }
                  },
            child: const Text('Save Draft'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Custom Stepper Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(steps.length, (index) {
                final isActive = index == currentStep;
                final isCompleted = index < currentStep;

                return Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive || isCompleted
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    if (index < steps.length - 1)
                      Container(
                        width: 40,
                        height: 2,
                        color: isCompleted
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                      ),
                  ],
                );
              }),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: steps[currentStep],
            ),
          ),
          // Navigation Buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (currentStep > 0)
                  OutlinedButton(
                    onPressed: _isSubmitting ? null : () {
                      ref.read(onboardingStepProvider.notifier).state--;
                    },
                    child: const Text('Back'),
                  )
                else
                  const SizedBox.shrink(),
                FilledButton(
                  onPressed: _isSubmitting ? null : () async {
                    if (currentStep < steps.length - 1) {
                      // Allow proceeding without validation
                      ref.read(onboardingStepProvider.notifier).state++;
                    } else {
                      // Validate ALL steps before submission
                      bool isValid = true;
                      for (int i = 0; i < steps.length; i++) {
                        if (!_validateCurrentStep(context, ref, i)) {
                          isValid = false;
                          ref.read(onboardingStepProvider.notifier).state = i; // Go to the invalid step
                          break;
                        }
                      }

                      if (!isValid) return;

                      // Submit
                      setState(() => _isSubmitting = true);
                      try {
                        // Capture ID before submit (it might be cleared or changed, though unlikely)
                        final currentRequestId = ref.read(onboardingFormProvider).id;
                        
                        await ref.read(onboardingFormProvider.notifier).submitForm(ref);
                        
                        // Invalidate details provider if it was an update
                        if (currentRequestId != null && currentRequestId.isNotEmpty) {
                          // We need to import request_details_screen.dart for this provider
                          // But we can't easily import it here if it's not exported.
                          // Wait, requestDetailsProvider is global in request_details_screen.dart.
                          // We just need to add the import.
                          ref.invalidate(investorRequestDetailsProvider(currentRequestId));
                        }

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Request submitted successfully!')),
                          );
                          context.go('/dashboard');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(ErrorUtils.getFriendlyErrorMessage(e)),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _isSubmitting = false);
                      }
                    }
                  },
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(currentStep == steps.length - 1 ? 'Submit' : 'Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
