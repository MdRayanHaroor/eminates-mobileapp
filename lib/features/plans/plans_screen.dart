import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:investorapp_eminates/features/auth/providers/auth_provider.dart';
import 'package:investorapp_eminates/features/dashboard/providers/dashboard_provider.dart';
import 'package:investorapp_eminates/features/onboarding/models/investment_plan.dart';
import 'package:intl/intl.dart';

class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({super.key});

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;
  List<InvestmentPlan> _plans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    try {
      final planData = await ref.read(investorRepositoryProvider).getInvestmentPlans();
      setState(() {
        _plans = planData.map((e) => InvestmentPlan.fromJson(e)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading plans: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Investment Plans')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                 children: [
                   const SizedBox(height: 16),
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 24.0),
                     child: Text(
                       'Choose the plan that grows with you.',
                       style: GoogleFonts.outfit(
                         fontSize: 18, 
                         color: Colors.grey[700],
                         fontWeight: FontWeight.w500
                       ),
                       textAlign: TextAlign.center,
                     ),
                   ),
                   const SizedBox(height: 0),
                   SizedBox(
                     height: 520, // Reduced from 600 
                     child: PageView.builder(
                       controller: _pageController,
                       itemCount: _plans.length,
                       onPageChanged: (int index) {
                         setState(() => _currentPage = index);
                       },
                       itemBuilder: (context, index) {
                         return Padding(
                           padding: const EdgeInsets.only(bottom: 20), // Add padding for shadow/elevation
                           child: _buildPlanCard(_plans[index], index == _currentPage),
                         );
                       },
                       padEnds: true,
                     ),
                   ),
                   const SizedBox(height: 6),
                   // Page Indicator
                   Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: List.generate(_plans.length, (index) {
                       return AnimatedContainer(
                         duration: const Duration(milliseconds: 300),
                         margin: const EdgeInsets.symmetric(horizontal: 4),
                         width: _currentPage == index ? 24 : 8,
                         height: 8,
                         decoration: BoxDecoration(
                           borderRadius: BorderRadius.circular(4),
                           color: _currentPage == index ? Theme.of(context).primaryColor : Colors.grey.shade300,
                         ),
                       );
                     }),
                   ),
                   const SizedBox(height: 100), // Huge bottom space to clear bottom nav overlap
                 ],
               ),
             ),
           ),
         ],
       ),
    );
  }

  Widget _buildPlanCard(InvestmentPlan plan, bool isActive) {
    // ... existing colors ...
    // Determine card gradient/color based on plan name
    List<Color> gradientColors;
    Color textColor;

    if (plan.name.contains('Silver')) {
       gradientColors = [const Color(0xFFF5F5F5), const Color(0xFFCFD8DC)]; 
       textColor = Colors.black87;
    } else if (plan.name.contains('Gold')) {
       gradientColors = [const Color(0xFFFFECB3), const Color(0xFFFFCA28)]; 
       textColor = Colors.brown.shade900;
    } else if (plan.name.contains('Platinum')) {
       gradientColors = [const Color(0xFFE3F2FD), const Color(0xFF90CAF9)]; 
       textColor = Colors.indigo.shade900;
    } else if (plan.name.contains('Elite')) {
       gradientColors = [const Color(0xFFEDE7F6), const Color(0xFF9575CD)]; 
       textColor = Colors.deepPurple.shade900;
    } else {
       gradientColors = [
         Theme.of(context).primaryColor.withOpacity(0.1),
         Theme.of(context).primaryColor.withOpacity(0.3)
       ];
       textColor = Theme.of(context).primaryColor;
    }

    // Default amount for display
    final displayAmount = plan.minAmount ?? 100000;
    
    // Calculate payouts
    final monthly = (displayAmount * plan.monthlyProfitPercentage / 100).toStringAsFixed(0);
    final quarterly = (displayAmount * plan.quarterlyProfitPercentage / 100).toStringAsFixed(0);
    final halfYearly = (displayAmount * plan.halfYearlyProfitPercentage / 100).toStringAsFixed(0);

    return AnimatedScale(
      scale: isActive ? 1.0 : 0.9,
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
             BoxShadow(
               color: Colors.black.withOpacity(isActive ? 0.15 : 0.05),
               blurRadius: isActive ? 15 : 10,
               offset: const Offset(0, 8),
             ),
          ],
        ),
        child: Column(
          children: [
            // Header with Gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16), // Reduced from 20
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Text(
                    plan.name,
                    style: GoogleFonts.outfit(
                      fontSize: 18, // Reduced from 22
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2), // Reduced from 4
                  Text(
                     // Show Tenure Based Text instead of fixed amount
                    '${plan.tenure} Plan', 
                    style: GoogleFonts.outfit(
                      fontSize: 20, // Reduced from 24
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                   const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${plan.monthlyProfitPercentage}% / month',
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  )
                ],
              ),
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0), // Reduced from 16.0
                child: Column(
                  children: [
                     _buildFeatureRow('Min. Investment', '₹${NumberFormat.compact(locale: 'en_IN').format(plan.minAmount ?? 0)}'),
                     const Divider(),
                     const SizedBox(height: 8),

                     // Returns Section
                     Align(
                       alignment: Alignment.centerLeft,
                       child: Text(
                         'Estimated Returns (on ₹1L)',
                         style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey[800]),
                       ),
                     ),
                     const SizedBox(height: 8),
                     _buildPayoutRow('Monthly', '₹$monthly'),
                     _buildPayoutRow('Quarterly', '₹$quarterly'),
                     
                     const Spacer(),

                     // Action Links
                     SizedBox(
                       width: double.infinity,
                       child: ElevatedButton(
                         onPressed: () {
                           context.push('/plan-details', extra: {'plan': plan, 'fromOnboarding': false});
                         },
                         style: ElevatedButton.styleFrom(
                           backgroundColor: Colors.black, // Sleek black button
                           foregroundColor: Colors.white,
                           padding: const EdgeInsets.symmetric(vertical: 12), // Reduced from 14
                           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                         ),
                         child: const Text('View Details'),
                       ),
                     ),

                     // Admin Edit Button
                      Consumer(
                        builder: (context, ref, child) {
                          final isAdmin = ref.watch(isAdminProvider).value ?? false;
                          if (!isAdmin) return const SizedBox.shrink();
                          
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: TextButton.icon(
                              onPressed: () {
                                 context.push('/edit-plan', extra: plan).then((_) => _loadPlans()); 
                              },
                              icon: Icon(Icons.edit, size: 16, color: Colors.grey[600]),
                              label: Text('Edit Plan', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
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
      ),
    );
  }

  Widget _buildPayoutRow(String period, String amount) {
     return Padding(
       padding: const EdgeInsets.symmetric(vertical: 6),
       child: Row(
         mainAxisAlignment: MainAxisAlignment.spaceBetween,
         children: [
           Text(period, style: GoogleFonts.outfit(color: Colors.grey[600], fontSize: 14)),
           Text(amount, style: GoogleFonts.outfit(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 15)),
         ],
       ),
     );
  }

  Widget _buildFeatureRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(color: Colors.grey[700], fontSize: 16)),
          Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
        ],
      ),
    );
  }
}
