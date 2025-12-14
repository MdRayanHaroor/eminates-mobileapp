import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:investorapp_eminates/features/dashboard/providers/dashboard_provider.dart';
import 'package:investorapp_eminates/features/onboarding/models/investment_plan.dart';
import 'package:go_router/go_router.dart';

class AutoSlidingPlans extends ConsumerStatefulWidget {
  const AutoSlidingPlans({super.key});

  @override
  ConsumerState<AutoSlidingPlans> createState() => _AutoSlidingPlansState();
}

class _AutoSlidingPlansState extends ConsumerState<AutoSlidingPlans> {
  final PageController _pageController = PageController(viewportFraction: 0.93);
  Timer? _timer;
  int _currentPage = 0;
  List<InvestmentPlan> _plans = [];

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_timer != null && _timer!.isActive) return;
    
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
     
      // Pause if a route is pushed on top (e.g. Walkthrough)
      // This is a simple heuristic: if the current route is not top-most or if a dialog is open.
      // But a better way for "Walkthrough" specifically: logic in Dashboard handles navigation.
      // Here, check if ModalRoute.of(context)?.isCurrent is true.
      
      final modalRoute = ModalRoute.of(context);
      if (modalRoute != null && !modalRoute.isCurrent) {
        // Paused because another route is on top
        return;
      }

      if (_plans.isEmpty) return;
      if (_pageController.hasClients) {
        int nextPage = _currentPage + 1;
        if (nextPage >= _plans.length) nextPage = 0;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final plansAsync = ref.watch(plansProvider);
    final theme = Theme.of(context);

    return plansAsync.when(
      data: (data) {
        if (data.isEmpty) return const SizedBox.shrink();
        _plans = data.map((e) => InvestmentPlan.fromJson(e)).toList();
        
        // Start timer
        _startTimer();

        return Column(
          children: [
             SizedBox(
               height: 180, 
               child: PageView.builder(
                 controller: _pageController,
                 itemCount: _plans.length,
                 onPageChanged: (index) {
                   setState(() => _currentPage = index);
                 },
                 itemBuilder: (context, index) {
                   return Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 6.0),
                     child: _buildCompactPlanCard(context, _plans[index]),
                   );
                 },
               ),
             ),
             const SizedBox(height: 12),
             // Indicators
             Row(
               mainAxisAlignment: MainAxisAlignment.center,
               children: List.generate(_plans.length, (index) {
                 return AnimatedContainer(
                   duration: const Duration(milliseconds: 300),
                   margin: const EdgeInsets.symmetric(horizontal: 3),
                   width: _currentPage == index ? 24 : 6,
                   height: 6,
                   decoration: BoxDecoration(
                     borderRadius: BorderRadius.circular(3),
                     color: _currentPage == index ? theme.primaryColor : Colors.grey.withOpacity(0.3),
                   ),
                 );
               }),
             ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_,__) => const SizedBox.shrink(),
    );
  }

  Widget _buildCompactPlanCard(BuildContext context, InvestmentPlan plan) {
    // Determine colors
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
         Colors.blueAccent.shade100,
         Colors.blueAccent.shade400
       ];
       textColor = Colors.white;
    }

    return InkWell(
      onTap: () {
         context.push('/plan-details', extra: {'plan': plan, 'fromOnboarding': false});
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
             BoxShadow(
               color: Colors.black.withOpacity(0.05),
               blurRadius: 10,
               offset: const Offset(0, 4),
             )
          ]
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
             Expanded(
               flex: 3,
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                    Text(
                      plan.name,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Returns up to',
                      style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 10),
                    ),
                    Text(
                      '${plan.quarterlyProfitPercentage}% Quarterly',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                 ],
               ),
             ),
             Container(width: 1, color: textColor.withOpacity(0.2)),
             Expanded(
               flex: 2,
               child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Icon(Icons.arrow_forward_ios, color: textColor, size: 16),
                     const SizedBox(height: 4),
                     Text('Start with', style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 10)),
                     Text(
                       plan.amountWithSymbol, 
                       style: GoogleFonts.outfit(
                         fontWeight: FontWeight.bold, 
                         color: textColor,
                         fontSize: 14
                       )
                     ),
                  ],
               ),
             )
          ],
        ),
      ),
    );
  }
}
