import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:investorapp_eminates/features/onboarding/providers/onboarding_provider.dart';

class StepInvestment extends ConsumerStatefulWidget {
  const StepInvestment({super.key});

  @override
  ConsumerState<StepInvestment> createState() => _StepInvestmentState();
}

class _StepInvestmentState extends ConsumerState<StepInvestment> {
  String? _selectedPackage;
  final _otherAmountController = TextEditingController();
  bool _isOther = false;

  final List<String> _packages = [
    '₹1,50,000 – Silver',
    '₹3,00,000 – Gold',
    '₹5,00,000 – Premium',
    '₹10,00,000 – Elite',
  ];

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingFormProvider);
    final currentAmount = state.investmentAmount;
    
    if (currentAmount != null) {
      if (_packages.contains(currentAmount)) {
        _selectedPackage = currentAmount;
        _isOther = false;
      } else {
        _selectedPackage = 'Other';
        _isOther = true;
        _otherAmountController.text = currentAmount;
      }
    }

    _otherAmountController.addListener(() {
      if (_isOther) {
        ref.read(onboardingFormProvider.notifier).updateInvestmentDetails(
          investmentAmount: _otherAmountController.text,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Section G: Investment Package Selection', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        ..._packages.map((package) => RadioListTile<String>(
          title: Text(package),
          value: package,
          groupValue: _selectedPackage,
          onChanged: (val) {
            setState(() {
              _selectedPackage = val;
              _isOther = false;
            });
            ref.read(onboardingFormProvider.notifier).updateInvestmentDetails(investmentAmount: val);
          },
        )),
        RadioListTile<String>(
          title: const Text('Other Amount'),
          value: 'Other',
          groupValue: _selectedPackage,
          onChanged: (val) {
            setState(() {
              _selectedPackage = val;
              _isOther = true;
            });
            // Don't update yet, wait for text input
          },
        ),
        if (_isOther)
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
            child: TextFormField(
              controller: _otherAmountController,
              decoration: const InputDecoration(
                labelText: 'Enter Amount',
                prefixText: '₹ ',
              ),
              keyboardType: TextInputType.number,
            ),
          ),
      ],
    );
  }
}
