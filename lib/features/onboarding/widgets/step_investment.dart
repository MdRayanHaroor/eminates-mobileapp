import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:investorapp_eminates/features/onboarding/models/investment_plan.dart';
import 'package:investorapp_eminates/features/onboarding/providers/onboarding_provider.dart';
import 'package:investorapp_eminates/features/plans/providers/plans_provider.dart';

class StepInvestment extends ConsumerStatefulWidget {
  const StepInvestment({super.key});

  @override
  ConsumerState<StepInvestment> createState() => _StepInvestmentState();
}



class _StepInvestmentState extends ConsumerState<StepInvestment> {
  double _currentSliderValue = 100000;
  String? _selectedPlanName;
  final _customAmountController = TextEditingController();
  
  // Cache the plans to avoid flicker if they don't change often, or just use provider state
  // List<InvestmentPlan> _plans = []; // No longer needed as state, derive from provider

  
  // Plans are now fetched from provider


  final FocusNode _amountFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final state = ref.read(onboardingFormProvider);
    final currentAmount = state.investmentAmount;
    
    if (state.planName != null) {
       _selectedPlanName = state.planName;
    }

    if (currentAmount != null && currentAmount.isNotEmpty) {
      final regex = RegExp(r'₹([\d,]+)');
      final match = regex.firstMatch(currentAmount);
      if (match != null) {
        final cleanAmount = match.group(1)?.replaceAll(',', '') ?? '';
        _customAmountController.text = cleanAmount;
      } else {
         // handle plain
         _customAmountController.text = currentAmount.replaceAll(',', '');
      }
    }

    _amountFocusNode.addListener(_onFocusChange);
    _customAmountController.addListener(_onAmountChanged);
  }

  void _onFocusChange() {
    // Logic optional now, or fetch plan from provider state if needed
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
    if (_selectedPlanName != null && _customAmountController.text.isNotEmpty) {
       final cleanAmount = _customAmountController.text.replaceAll(',', '');
       ref.read(onboardingFormProvider.notifier).updateInvestmentDetails(
          investmentAmount: cleanAmount, 
          planName: _selectedPlanName,
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
    // Pass fromOnboarding: true so PlanDetails just pops back with result (although popping is less relied upon now that we update provider)
    await context.push('/plan-details', extra: {'plan': plan, 'fromOnboarding': true});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Section A: Investment Package', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text('Select a plan and enter the amount you wish to invest.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
        const SizedBox(height: 16),
        
        // Amount Input & Slider Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Investment Amount', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              TextFormField(
                controller: _customAmountController,
                focusNode: _amountFocusNode,
                decoration: const InputDecoration(
                  labelText: 'Enter Amount (Min ₹1,00,000)',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                  helperText: 'Enter amount or use slider below',
                ),
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  // Update slider position when text changes
                  final amount = double.tryParse(val.replaceAll(',', '')) ?? 0;
                  setState(() {
                    if (amount >= 100000 && amount <= 1000000) {
                      _currentSliderValue = amount;
                    } else if (amount > 1000000) {
                      _currentSliderValue = 1000000; // Max out slider
                    } else if (amount < 100000) {
                      _currentSliderValue = 100000; // Min slider
                    }
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter amount';
                  final val = double.tryParse(value.replaceAll(',', ''));
                  if (val == null) return 'Invalid amount';
                  if (val < 100000) return 'Min investment is ₹1,00,000';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('1L', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  Text('10L+', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Theme.of(context).primaryColor,
                  inactiveTrackColor: Colors.grey[300],
                  thumbColor: Theme.of(context).primaryColor,
                  overlayColor: Theme.of(context).primaryColor.withOpacity(0.2),
                  trackHeight: 4.0,
                ),
                child: Slider(
                  value: _currentSliderValue,
                  min: 100000,
                  max: 1100000, // Extended range for 10L+
                  divisions: 100, // increments of ~10k
                  label: _currentSliderValue >= 1100000 ? '10L+' : '₹${(_currentSliderValue/1000).toStringAsFixed(0)}k',
                  onChanged: (double value) {
                    setState(() {
                      _currentSliderValue = value;
                      String formatted;
                      if (value >= 1100000) {
                         formatted = '1100000'; // Show actual max value
                      } else {
                         formatted = value.toInt().toString();
                      }
                      _customAmountController.text = formatted;
                      _onAmountChanged(); // trigger provider update
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),

        // Plans List
        Text('Available Plans', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        
        // Dynamic Plans Fetch
        ref.watch(plansProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error loading plans: $err')),
          data: (plansList) {
            // Sort Logic: Prioritize plans matching the amount
            final amount = double.tryParse(_customAmountController.text.replaceAll(',', '')) ?? 0;
            final sortedPlans = List<InvestmentPlan>.from(plansList);
            
            if (amount > 0) {
              sortedPlans.sort((a, b) {
                // Check if plan matches range
                bool aMatches = (a.minAmount ?? 0) <= amount && (a.maxAmount == null || a.maxAmount! >= amount);
                bool bMatches = (b.minAmount ?? 0) <= amount && (b.maxAmount == null || b.maxAmount! >= amount);
                
                if (aMatches && !bMatches) return -1;
                if (!aMatches && bMatches) return 1;
                return 0; // Maintain original order 
              });
            }

            // Auto-select the first plan if amount changes effectively
            // We use a microtask to avoid build-phase state updates, ensuring the UI reflects the "recommendation"
            if (sortedPlans.isNotEmpty && _selectedPlanName != sortedPlans.first.name) {
               // Verify if this is desirable? User asked for "first shown plan selected by default"
               // To prevent overriding user manual click during no-sort-change, we might want to be careful.
               // But strictly fulfilling the request:
               Future.microtask(() {
                 if (mounted && _selectedPlanName != sortedPlans.first.name) {
                    setState(() {
                      _selectedPlanName = sortedPlans.first.name;
                      // Also update provider? No, onPlanSelected does that, we just update local state.
                      // But we should sync provider if needed.
                      ref.read(onboardingFormProvider.notifier).updateInvestmentDetails(planName: _selectedPlanName);
                    });
                 }
               });
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedPlans.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final plan = sortedPlans[index];
                final isSelected = _selectedPlanName == plan.name;
                final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                
                return InkWell(
                  onTap: () => _onPlanSelected(plan), // Pass plan object directly
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
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 8),
                        _buildDetailRow(context, 'Tenure', plan.tenure),
                        _buildDetailRow(context, 'Monthly', '${plan.monthlyProfitPercentage}%'),
                        _buildDetailRow(context, 'Quarterly', '${plan.quarterlyProfitPercentage}%'),
                        _buildDetailRow(context, 'Half-Yearly', '${plan.halfYearlyProfitPercentage}%'),
                        
                        if (isSelected) ...[
                          const SizedBox(height: 16),
                          // Dynamic Calculation based on entered amount
                          Builder(
                            builder: (context) {
                              final amt = double.tryParse(_customAmountController.text.replaceAll(',', '')) ?? 0;
                              if (amt > 0) {
                                final monthly = (amt * plan.monthlyProfitPercentage / 100).toStringAsFixed(0);
                                final quarterly = (amt * plan.quarterlyProfitPercentage / 100).toStringAsFixed(0);
                                final halfYearly = (amt * plan.halfYearlyProfitPercentage / 100).toStringAsFixed(0);
                                
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    children: [
                                      Text('Estimated Returns for ₹$amt', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          Column(children: [Text('Monthly'), Text('₹$monthly', style: const TextStyle(fontWeight: FontWeight.bold))]),
                                          Column(children: [Text('Quarterly'), Text('₹$quarterly', style: const TextStyle(fontWeight: FontWeight.bold))]),
                                          Column(children: [Text('Half-Yearly'), Text('₹$halfYearly', style: const TextStyle(fontWeight: FontWeight.bold))]),
                                        ],
                                      )
                                    ],
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            }
                          ),
                          const SizedBox(height: 16),
                          
                          // Tenure Selection
                          DropdownButtonFormField<int>(
                            decoration: const InputDecoration(labelText: 'Select Tenure (Mandatory)', border: OutlineInputBorder()),
                            value: ref.read(onboardingFormProvider).selectedTenure, 
                            items: plan.tenureBonuses.keys.map((years) {
                                 final bonus = plan.tenureBonuses[years];
                                 return DropdownMenuItem<int>(
                                   value: years,
                                   child: Text('$years Years (Maturity Bonus: $bonus%)'),
                                 );
                            }).toList(),
                            onChanged: (val) {
                               if (val != null) {
                                 ref.read(onboardingFormProvider.notifier).updateInvestmentDetails(
                                   selectedTenure: val,
                                   maturityBonusPercentage: plan.tenureBonuses[val],
                                 );
                                 setState((){}); 
                               }
                            },
                            validator: (v) => v == null ? 'Please select a tenure' : null,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
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
