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
      amountWithSymbol: 'Up to ₹3,00,000',
      tenure: '3 years',
      payout: 'Quarterly',
      roi: 'Approx 24% annual',
      roiPercentage: 24.0,
      tenureYears: 3.0,
      payoutFrequencyMonths: 3,
      minAmount: 100000,
      maxAmount: 300000,
    ),
    const InvestmentPlan(
      name: 'Gold Plan',
      amountWithSymbol: 'Up to ₹5,00,000',
      tenure: '6 years',
      payout: 'Half-yearly',
      roi: '~30%',
      roiPercentage: 30.0,
      tenureYears: 6.0,
      payoutFrequencyMonths: 6,
      minAmount: 300001,
      maxAmount: 500000,
    ),
    const InvestmentPlan(
      name: 'Platinum Plan',
      amountWithSymbol: 'Up to ₹10,00,000',
      tenure: '6 years',
      payout: 'Yearly',
      roi: '~36%',
      roiPercentage: 36.0,
      tenureYears: 6.0,
      payoutFrequencyMonths: 12,
      minAmount: 500001,
      maxAmount: 1000000,
    ),
    const InvestmentPlan(
      name: 'Elite Plan',
      amountWithSymbol: 'Above ₹10,00,000',
      tenure: '5–7 years',
      payout: 'Yearly/Agreement',
      roi: 'Custom',
      description: 'For HNI investors',
      isCustom: true,
      minAmount: 1000001,
      roiPercentage: 36.0, 
      tenureYears: 5.0,
      payoutFrequencyMonths: 12,
    ),
  ];

  final FocusNode _amountFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingFormProvider);
    final currentAmount = state.investmentAmount;
    
    // Default selection if none
    if (_selectedPlanName == null) {
       _selectedPlanName = _plans[0].name;
    }

    if (currentAmount != null && currentAmount.isNotEmpty) {
      // First, try to extract numeric amount
      final regex = RegExp(r'₹([\d,]+)');
      final match = regex.firstMatch(currentAmount);
      if (match != null) {
        // If we have an amount, set it in controller
        final cleanAmount = match.group(1)?.replaceAll(',', '') ?? '';
        _customAmountController.text = cleanAmount;
        
        // Match plan by logic if needed, but user wants NO smart switching
        // So we just rely on name match if present
        _matchPlanByName(currentAmount);
      } else {
        _matchPlanByName(currentAmount);
      }
    }

    _amountFocusNode.addListener(_onFocusChange);
    _customAmountController.addListener(_onAmountChanged);
  }

  void _onFocusChange() {
    if (_amountFocusNode.hasFocus) {
       final currentPlan = _plans.firstWhere((p) => p.name == _selectedPlanName);
       if (_customAmountController.text.isEmpty && currentPlan.minAmount != null) {
          _customAmountController.text = currentPlan.minAmount!.toInt().toString();
       }
    }
  }

  void _matchPlanByName(String text) {
     for (final plan in _plans) {
        if (text.contains(plan.name.split(' ')[0])) {
           _selectedPlanName = plan.name;
           break;
        }
     }
  }

  @override
  void dispose() {
    _amountFocusNode.removeListener(_onFocusChange);
    _amountFocusNode.dispose();
    _customAmountController.removeListener(_onAmountChanged);
    _customAmountController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    // Just update provider, NO switching
    if (_selectedPlanName != null && _customAmountController.text.isNotEmpty) {
       ref.read(onboardingFormProvider.notifier).updateInvestmentDetails(
          investmentAmount: '₹${_customAmountController.text} – $_selectedPlanName',
       );
    }
  }

  void _onPlanSelected(InvestmentPlan plan) {
    setState(() {
      _selectedPlanName = plan.name;
    });
    // Trigger update to set path correct
    if (_customAmountController.text.isNotEmpty) {
       _onAmountChanged();
    }
  }

  Future<void> _viewPlanDetails(InvestmentPlan plan) async {
    final result = await context.push('/plan-details', extra: plan);
    // Logic can remain for selection from details if required
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Section G: Investment Package', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text('Select a plan and enter the amount you wish to invest.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
        const SizedBox(height: 16),
        
        // Always show Amount Input at top (or arguably inside the selected card, but top is cleaner for "drive by amount")
        // User requested: "focus on the appropriate plan with amount already entered" implies input exists.
        // "in investor plans screen in the plans cards show amount... submit should ... focus"
        // Let's put the input field prominently at the top? 
        // Or keep it inside the selected card as before, but ensure it's ALWAYS visible for the selected card?
        // Let's keep it inside the selected card for context.

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
                        Text(
                          plan.amountWithSymbol,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
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
                    
                    if (isSelected) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _customAmountController,
                        focusNode: _amountFocusNode,
                        decoration: InputDecoration(
                          labelText: plan.name == 'Elite Plan' 
                              ? 'Investment Amount above ₹${plan.minAmount?.toInt() ?? 0}'
                              : (index > 0 
                                  ? 'Investment Amount above ₹${_plans[index-1].maxAmount?.toInt() ?? 0}'
                                  : 'Investment Amount (Min ₹${plan.minAmount?.toInt() ?? 0})'),
                          prefixText: '₹ ',
                          border: const OutlineInputBorder(),
                          // helperText: 'Min: ₹${plan.minAmount?.toInt()} - Max: ₹${plan.maxAmount?.toInt() ?? "Unlimited"}',
                        ),
                        keyboardType: TextInputType.number,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Enter amount';
                          final val = double.tryParse(value.replaceAll(',', ''));
                          if (val == null) return 'Invalid amount';
                          
                          if (plan.minAmount != null && val < plan.minAmount!) {
                             return 'For ${plan.name} min and max amount is ₹${plan.minAmount!.toInt()} - ₹${plan.maxAmount?.toInt() ?? "Above"}';
                          }
                          if (plan.maxAmount != null && val > plan.maxAmount!) {
                             return 'For ${plan.name} min and max amount is ₹${plan.minAmount!.toInt()} - ₹${plan.maxAmount!.toInt()}';
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
