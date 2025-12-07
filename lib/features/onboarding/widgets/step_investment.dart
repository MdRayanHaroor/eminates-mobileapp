import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:investorapp_eminates/features/onboarding/models/investment_plan.dart';
import 'package:investorapp_eminates/features/onboarding/providers/onboarding_provider.dart';

class StepInvestment extends ConsumerStatefulWidget {
  const StepInvestment({super.key});

  @override
  ConsumerState<StepInvestment> createState() => _StepInvestmentState();
}

class _StepInvestmentState extends ConsumerState<StepInvestment> {
  String? _selectedPlanName;
  final _customAmountController = TextEditingController();
  
  final List<InvestmentPlan> _plans = [
    const InvestmentPlan(
      name: 'Silver Plan',
      amountWithSymbol: '₹3,00,000',
      tenure: '3 years',
      payout: 'Quarterly',
      roi: 'Approx 24% annual',
      roiPercentage: 24.0,
      tenureYears: 3.0,
      payoutFrequencyMonths: 3,
    ),
    const InvestmentPlan(
      name: 'Gold Plan',
      amountWithSymbol: '₹5,00,000',
      tenure: '6 years',
      payout: 'Half-yearly',
      roi: '~30%',
      roiPercentage: 30.0,
      tenureYears: 6.0,
      payoutFrequencyMonths: 6,
    ),
    const InvestmentPlan(
      name: 'Platinum Plan',
      amountWithSymbol: '₹10,00,000',
      tenure: '6 years',
      payout: 'Yearly',
      roi: '~36%',
      roiPercentage: 36.0,
      tenureYears: 6.0,
      payoutFrequencyMonths: 12,
    ),
    const InvestmentPlan(
      name: 'Elite Plan',
      amountWithSymbol: 'Custom',
      tenure: '5–7 years',
      payout: 'Yearly/Agreement',
      roi: 'Custom',
      description: 'For HNI investors',
      isCustom: true,
      minAmount: 2500000,
      roiPercentage: 36.0, // Base for calculation example
      tenureYears: 5.0, // Base for calculation example
      payoutFrequencyMonths: 12,
    ),
  ];

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingFormProvider);
    final currentAmount = state.investmentAmount;
    
    if (currentAmount != null && currentAmount.isNotEmpty) {
      // Try to match existing string to a plan
      bool matched = false;
      for (final plan in _plans) {
        if (!plan.isCustom && currentAmount.contains(plan.name.split(' ')[0])) { // Simple heuristic match "Silver", "Gold"
           _selectedPlanName = plan.name;
           matched = true;
           break;
        }
      }
      
      if (!matched) {
        // Assume Elite/Custom if it doesn't match standard plans but has value
        // Or check if it contains "Elite"
        _selectedPlanName = 'Elite Plan';
        // Extract numeric part if possible
        final regex = RegExp(r'₹([\d,]+)');
        final match = regex.firstMatch(currentAmount);
        if (match != null) {
          _customAmountController.text = match.group(1)?.replaceAll(',', '') ?? '';
        }
      }
    }
    
    _customAmountController.addListener(_onCustomAmountChanged);
  }

  @override
  void dispose() {
    _customAmountController.removeListener(_onCustomAmountChanged);
    _customAmountController.dispose();
    super.dispose();
  }

  void _onCustomAmountChanged() {
    if (_selectedPlanName == 'Elite Plan') {
      final amount = _customAmountController.text;
      if (amount.isNotEmpty) {
        ref.read(onboardingFormProvider.notifier).updateInvestmentDetails(
          investmentAmount: '₹$amount – Elite Plan',
        );
      }
    }
  }

  void _onPlanSelected(InvestmentPlan plan) {
    setState(() {
      _selectedPlanName = plan.name;
    });
    
    if (!plan.isCustom) {
      ref.read(onboardingFormProvider.notifier).updateInvestmentDetails(
        investmentAmount: '${plan.amountWithSymbol} – ${plan.name}',
      );
      _customAmountController.clear();
    } else {
      if (_customAmountController.text.isNotEmpty) {
         ref.read(onboardingFormProvider.notifier).updateInvestmentDetails(
          investmentAmount: '₹${_customAmountController.text} – ${plan.name}',
        );
      }
    }
  }

  Future<void> _viewPlanDetails(InvestmentPlan plan) async {
    final result = await context.push('/plan-details', extra: plan);
    if (result != null && result is String) {
      // User selected this plan from details page
      setState(() {
        _selectedPlanName = plan.name;
        if (plan.isCustom) {
           // Extract amount from result "₹2500000 – Elite Plan"
           final regex = RegExp(r'₹([\d,]+)');
           final match = regex.firstMatch(result);
           if (match != null) {
             _customAmountController.text = match.group(1)?.replaceAll(',', '') ?? '';
           }
        } else {
          _customAmountController.clear();
        }
      });
      ref.read(onboardingFormProvider.notifier).updateInvestmentDetails(investmentAmount: result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Section G: Investment Package', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text('Select the plan that suits you best.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
        const SizedBox(height: 16),
        
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _plans.length,
          separatorBuilder: (ctx, i) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final plan = _plans[index];
            final isSelected = _selectedPlanName == plan.name;
            final isDarkMode = Theme.of(context).brightness == Brightness.dark;
            
            return InkWell(
              onTap: () => _onPlanSelected(plan),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? Theme.of(context).primaryColor : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  // Use theme card color or surface color for background
                  color: isSelected 
                      ? Theme.of(context).primaryColor.withOpacity(0.05) 
                      : (isDarkMode ? Theme.of(context).cardColor : Colors.white),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plan.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              if (plan.description != null)
                                Text(
                                  plan.description!,
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                        if (!plan.isCustom)
                        Text(
                          plan.amountWithSymbol,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    _buildDetailRow(context, 'Tenure', plan.tenure),
                    _buildDetailRow(context, 'Payout', plan.payout),
                    _buildDetailRow(context, 'ROI', plan.roi),
                    
                    if (plan.isCustom && isSelected) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _customAmountController,
                        decoration: const InputDecoration(
                          labelText: 'Investment Amount (Min ₹25,00,000)',
                          prefixText: '₹ ',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Enter amount';
                          final val = double.tryParse(value.replaceAll(',', ''));
                          if (val == null) return 'Invalid amount';
                          if (val < plan.minAmount!) {
                            return 'Min amount is ₹${plan.minAmount!.toStringAsFixed(0)}';
                          }
                          return null;
                        },
                      ),
                    ],
                    
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _viewPlanDetails(plan),
                        icon: const Icon(Icons.info_outline, size: 16),
                        label: const Text('View Details & Profit Calculation'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.shade300),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber[800], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Note: The chosen plan and amount must be paid exactly as specified once your request is approved. Please choose wisely as changes cannot be made later.',
                  style: TextStyle(color: Colors.amber[900], fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600])),
          Text(value, style: TextStyle(fontWeight: FontWeight.w500, color: isDarkMode ? Colors.white70 : Colors.black87)),
        ],
      ),
    );
  }
}
