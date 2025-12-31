import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:investorapp_eminates/features/onboarding/models/investment_plan.dart';
import 'package:investorapp_eminates/features/onboarding/providers/onboarding_provider.dart';
import 'package:investorapp_eminates/features/plans/providers/plans_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class StepInvestment extends ConsumerStatefulWidget {
  const StepInvestment({super.key});

  @override
  ConsumerState<StepInvestment> createState() => _StepInvestmentState();
}

class _StepInvestmentState extends ConsumerState<StepInvestment> {
  double _currentSliderValue = 100000;
  String? _selectedPlanId;
  final _customAmountController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Force refresh checks
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(plansProvider);
    });
    
    final state = ref.read(onboardingFormProvider);
    
    // Initialize amount (handle commas/symbols)
    final currentAmount = state.investmentAmount;
    if (currentAmount != null && currentAmount.isNotEmpty) {
      final regex = RegExp(r'₹([\d,]+)');
      final match = regex.firstMatch(currentAmount);
      String cleanAmount = '';
      if (match != null) {
        cleanAmount = match.group(1)?.replaceAll(',', '') ?? '';
      } else {
         cleanAmount = currentAmount.replaceAll(',', '');
      }
      
      _customAmountController.text = cleanAmount;
      final amt = double.tryParse(cleanAmount) ?? 0;
      if (amt >= 100000 && amt <= 1000000) _currentSliderValue = amt;
      if (amt > 1000000) _currentSliderValue = 1000000;
      if (amt < 100000) _currentSliderValue = 100000;
    }

    // Initialize Plan (we might identify by Name or ID, usually Name in this app's legacy)
    // We'll trust the provider State identifying the plan.
    if (state.planName != null) {
       // We'll sync ID in the build method or lookup
    }

    _amountFocusNode.addListener(_onFocusChange);
    _customAmountController.addListener(_onAmountChanged);
  }

  void _onFocusChange() {}

  @override
  void dispose() {
    _amountFocusNode.dispose();
    _customAmountController.removeListener(_onAmountChanged);
    _customAmountController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    // Update provider always to keep in sync, even if empty
    final amountText = _customAmountController.text.replaceAll(',', '');
    // We update blindly to ensure state matches UI
    ref.read(onboardingFormProvider.notifier).updateInvestmentDetails(
      investmentAmount: amountText, 
    );
  }

  void _onPlanInput(InvestmentPlan plan) {
      try {
        setState(() {
          _selectedPlanId = plan.id;
        });
        
        final amountText = _customAmountController.text.replaceAll(',', '');
        
        // Use robust calculation from numeric fields
        final int months = (plan.tenureYears * 12).round();

        ref.read(onboardingFormProvider.notifier).updateInvestmentDetails(
            investmentAmount: amountText, 
            planName: plan.name,
            selectedTenure: months, 
        );
      } catch (e) {
        debugPrint('Error selecting plan: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error selecting plan: $e')),
        );
      }
  }

  @override
  Widget build(BuildContext context) {
    // Determine selected plan from provider if local state is null (initial load)
    final state = ref.watch(onboardingFormProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Investment Details', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Enter the amount you wish to invest and select a tenure plan.', 
             style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 14)),
        const SizedBox(height: 24),
        
        // Amount Input & Slider Section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
            boxShadow: [
               BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
            ]
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Investment Amount', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 16),
              TextFormField(
                controller: _customAmountController,
                focusNode: _amountFocusNode,
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Enter Amount',
                  hintText: 'Min ₹1,00,000',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  final amount = double.tryParse(val.replaceAll(',', '')) ?? 0;
                  setState(() {
                    if (amount >= 100000 && amount <= 1000000) {
                      _currentSliderValue = amount;
                    } else if (amount > 1000000) {
                      _currentSliderValue = 1000000;
                    } else if (amount < 100000) {
                      _currentSliderValue = 100000;
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
                  Text('₹1L', style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('₹10L+', style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Theme.of(context).primaryColor,
                  inactiveTrackColor: Colors.grey[200],
                  thumbColor: Theme.of(context).primaryColor,
                  overlayColor: Theme.of(context).primaryColor.withOpacity(0.2),
                  trackHeight: 6.0,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
                ),
                child: Slider(
                  value: _currentSliderValue,
                  min: 100000,
                  max: 1100000, // Extended range for 10L+
                  divisions: 100, 
                  label: _currentSliderValue >= 1100000 ? '10L+' : '₹${(_currentSliderValue/1000).toStringAsFixed(0)}k',
                  onChanged: (double value) {
                    setState(() {
                      _currentSliderValue = value;
                      String formatted;
                      if (value >= 1100000) {
                         formatted = '1100000'; 
                      } else {
                         formatted = value.toInt().toString();
                      }
                      _customAmountController.text = formatted;
                      _onAmountChanged(); 
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),

        // Plans List
        Text('Select Tenure', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        
        ref.watch(plansProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error loading plans: $err')),
          data: (plansList) {
             // Sort by tenure length if possible, using name or tenure field logic
             // Assuming seeded data is Silver(3), Gold(4), Platinum(5), Elite(10)
             // Let's sort based on minAmount just to keep consistent order or by Name
             plansList.sort((a, b) => (a.minAmount ?? 0).compareTo(b.minAmount ?? 0));

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: plansList.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final plan = plansList[index];
                // Check if this plan is selected based on Name in provider state
                final isSelected = state.planName == plan.name; 
                
                return InkWell(
                  onTap: () => _onPlanInput(plan),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Theme.of(context).primaryColor : Colors.grey.withOpacity(0.2),
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      color: isSelected 
                          ? Theme.of(context).primaryColor.withOpacity(0.04) 
                          : Colors.white,
                      boxShadow: isSelected 
                          ? [BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))] 
                          : [],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text(
                                    plan.name,
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                                 ),
                                 Text(
                                   'Tenure: ${plan.tenureYears % 1 == 0 ? plan.tenureYears.toInt() : plan.tenureYears} Years', 
                                   style: GoogleFonts.outfit(color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600, fontSize: 14)
                                 ),
                               ],
                             ),
                             if (isSelected) 
                               Icon(Icons.check_circle, color: Theme.of(context).primaryColor, size: 28)
                             else
                               Icon(Icons.circle_outlined, color: Colors.grey[400], size: 28),
                          ],
                        ),
                        
                        if (isSelected) ...[
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          // Calculation
                          Builder(
                            builder: (context) {
                               final amt = double.tryParse(_customAmountController.text.replaceAll(',', '')) ?? 0;
                               if (amt > 0) {
                                  final monthly = (amt * plan.monthlyProfitPercentage / 100).toStringAsFixed(0);
                                  final quarterly = (amt * plan.quarterlyProfitPercentage / 100).toStringAsFixed(0);
                                  
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                       _buildReturnItem('Monthly', '₹$monthly'),
                                       _buildReturnItem('Quarterly', '₹$quarterly'),
                                       _buildReturnItem('Rate', '${plan.quarterlyProfitPercentage}% Qtr'),
                                    ],
                                  );
                               }
                               return const Text('Enter amount to see returns');
                            }
                          )
                        ]
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
              Icon(Icons.info_outline, color: Colors.amber[900], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'The amount and tenure cannot be changed once the request is approved.',
                  style: GoogleFonts.outfit(color: Colors.amber[900], fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReturnItem(String label, String value) {
     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         Text(label, style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 12)),
         const SizedBox(height: 2),
         Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
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
