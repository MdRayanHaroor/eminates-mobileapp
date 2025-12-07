import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:investorapp_eminates/features/auth/providers/auth_provider.dart';
import 'package:investorapp_eminates/features/onboarding/models/investment_plan.dart';

class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({super.key});

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;

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
      roiPercentage: 36.0,
      tenureYears: 5.0,
      payoutFrequencyMonths: 12,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Investment Plans')),
      body: Column(
        children: [
          const SizedBox(height: 24),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              'Choose the plan that grows with you.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 550,
            child: PageView.builder(
              controller: _pageController,
              itemCount: _plans.length,
              onPageChanged: (int index) {
                setState(() => _currentPage = index);
              },
              itemBuilder: (context, index) {
                return _buildPlanCard(_plans[index], index == _currentPage);
              },
            ),
          ),
          const SizedBox(height: 24),
          // Page Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_plans.length, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index ? Theme.of(context).primaryColor : Colors.grey.shade300,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(InvestmentPlan plan, bool isActive) {
    // Determine card color based on plan name
    Color themeColor;
    Color textColor;
    if (plan.name.contains('Silver')) {
      themeColor = Colors.blueGrey;
      textColor = Colors.white;
    } else if (plan.name.contains('Gold')) {
      themeColor = Colors.amber.shade700;
      textColor = Colors.black;
    } else if (plan.name.contains('Platinum')) {
      themeColor = const Color(0xFFE5E4E2); // Platinum color
      textColor = Colors.black87; // Dark text for visibility on light platinum
    } else if (plan.name.contains('Elite')) {
      themeColor = Colors.deepPurple;
      textColor = Colors.white;
    } else {
      themeColor = Theme.of(context).primaryColor;
      textColor = Colors.white;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: isActive ? 0 : 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: isActive ? Border.all(color: themeColor.withOpacity(0.5), width: 2) : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isActive 
                  ? themeColor.withOpacity(0.15) 
                  : Colors.grey.withOpacity(0.05),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Text(
                  plan.name,
                  style: TextStyle(
                    fontSize: 22, 
                    fontWeight: FontWeight.bold,
                    color: isActive ? (plan.name.contains('Platinum') && Theme.of(context).brightness == Brightness.light ? Colors.black87 : themeColor) : null,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  plan.amountWithSymbol,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isActive ? (plan.name.contains('Platinum') && Theme.of(context).brightness == Brightness.light ? Colors.black87 : themeColor) : Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                   _buildFeatureRow('Tenure', plan.tenure),
                   const Divider(),
                   _buildFeatureRow('Payout', plan.payout),
                   const Divider(),
                   _buildFeatureRow('ROI', plan.roi),
                   if (plan.description != null) ...[
                     const Divider(),
                     const SizedBox(height: 12),
                     Text(
                       plan.description!,
                       style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                       textAlign: TextAlign.center,
                     ),
                   ],
                   const Spacer(),
                   
                   SizedBox(
                     width: double.infinity,
                     child: FilledButton.icon(
                       onPressed: () {
                         context.push('/plan-details', extra: plan);
                       },
                       icon: Icon(Icons.calculate, color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white),
                       label: Text(
                         'Calculate Profit',
                         style: TextStyle(
                           color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                           fontWeight: FontWeight.bold,
                         ),
                       ),
                       style: FilledButton.styleFrom(
                         padding: const EdgeInsets.symmetric(vertical: 16),
                         // Use theme-aware colors or specific high-contrast ones
                         backgroundColor: Theme.of(context).brightness == Brightness.dark 
                             ? Colors.white 
                             : Colors.black, 
                       ),
                     ),
                   ),

                   // Admin Edit Button Moved to Bottom
                    Consumer(
                      builder: (context, ref, child) {
                        final isAdmin = ref.watch(isAdminProvider).value ?? false;
                        if (!isAdmin) return const SizedBox.shrink();
                        
                        return Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: TextButton.icon(
                            onPressed: () {
                               ScaffoldMessenger.of(context).showSnackBar(
                                 const SnackBar(content: Text('Edit Plan feature coming soon!')),
                               );
                            },
                            icon: Icon(Icons.edit, size: 16, color: Colors.grey[600]),
                            label: Text('Edit Plan', style: TextStyle(color: Colors.grey[600])),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700], fontSize: 16)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }
}
