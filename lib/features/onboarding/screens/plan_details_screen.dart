import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:investorapp_eminates/features/onboarding/models/investment_plan.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:investorapp_eminates/features/onboarding/providers/onboarding_provider.dart';

class PlanDetailsScreen extends ConsumerStatefulWidget {
  final InvestmentPlan plan;
  final bool fromOnboarding;

  const PlanDetailsScreen({super.key, required this.plan, this.fromOnboarding = false});

  @override
  ConsumerState<PlanDetailsScreen> createState() => _PlanDetailsScreenState();
}

class _PlanDetailsScreenState extends ConsumerState<PlanDetailsScreen> {
  late TextEditingController _amountController;
  late double _currentAmount;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.plan.isCustom) {
      _currentAmount = widget.plan.minAmount ?? 2500000;
    } else {
      _currentAmount = _parseAmount(widget.plan.amountWithSymbol);
    }

    _amountController = TextEditingController(text: _formatAmountForInput(_currentAmount));
    _amountController.addListener(_updateCalculations);
  }

  double _parseAmount(String amountStr) {
     final cleanStr = amountStr.replaceAll(RegExp(r'[^\d.]'), '');
     return double.tryParse(cleanStr) ?? 0.0;
  }

  String _formatAmountForInput(double amount) {
    return amount.toInt().toString();
  }

  @override
  void dispose() {
    _amountController.removeListener(_updateCalculations);
    _amountController.dispose();
    super.dispose();
  }

  void _updateCalculations() {
    setState(() {
      final val = double.tryParse(_amountController.text.replaceAll(',', ''));
      if (val != null) {
        _currentAmount = val;
      }
    });
  }

  void _selectPlan() {
    if (_formKey.currentState?.validate() ?? false) {
      // Update the provider with the selected plan and amount
      final currentRequest = ref.read(currentEditingRequestProvider);
      ref.read(onboardingFormProvider(currentRequest).notifier).updateInvestmentDetails(
        planName: widget.plan.name,
        investmentAmount: _amountController.text,
      );

      if (widget.fromOnboarding) {
        // If from onboarding, just pop back (with result as backup, though provider is updated)
        String resultString = '₹${_amountController.text} – ${widget.plan.name}';
        context.pop(resultString);
      } else {
        // If from dashboard/plans, navigate to onboarding
        context.go('/onboarding');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final annualProfit = _currentAmount * (widget.plan.roiPercentage / 100);
    final totalProfit = annualProfit * widget.plan.tenureYears; // Simple interest assumption for total over tenure
    final tdsAmount = totalProfit * 0.10; // 10% TDS assumption
    final netProfit = totalProfit - tdsAmount;
    
    // Next payout estimate
    final nextPayoutDate = DateTime.now().add(Duration(days: widget.plan.payoutFrequencyMonths * 30));
    final dateFormat = DateFormat('MMM d, yyyy');
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Premium Gradients based on plan name
    LinearGradient headerGradient;
    if (widget.plan.name.contains('Silver')) {
      headerGradient = const LinearGradient(
        colors: [Color(0xFF757F9A), Color(0xFFD7DDE8)], // Metallic Silver
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (widget.plan.name.contains('Gold')) {
      headerGradient = const LinearGradient(
        colors: [Color(0xFFDAA520), Color(0xFFFDB931)], // Metallic Gold
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (widget.plan.name.contains('Platinum')) {
      headerGradient = const LinearGradient(
        colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)], // Deep Platinum/Blue
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (widget.plan.name.contains('Elite')) {
      headerGradient = const LinearGradient(
        colors: [Color(0xFF141E30), Color(0xFF243B55)], // Premium Dark Midnight
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else {
      headerGradient = LinearGradient(
        colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withOpacity(0.7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }

    // Text color on gradient (usually white looks best on these premium colors, but silver might be light)
    final onGradientColor = widget.plan.name.contains('Silver') ? Colors.black87 : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plan.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: headerGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.plan.name,
                      style: TextStyle(color: onGradientColor, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.plan.description ?? 'Premium Investment Plan',
                      style: TextStyle(color: onGradientColor.withOpacity(0.8), fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Investment Input
              Text('Investment Amount', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                  helperText: 'Enter amount to see projected returns',
                ),
                validator: (value) {
                    if (value == null || value.isEmpty) return 'Enter amount';
                    final val = double.tryParse(value.replaceAll(',', ''));
                    if (val == null) return 'Invalid amount';
                    
                    if (val < (widget.plan.minAmount ?? 0)) {
                      return 'Min amount is ${currencyFormat.format(widget.plan.minAmount)}';
                    }
                    if (widget.plan.maxAmount != null && val > widget.plan.maxAmount!) {
                      return 'Max amount is ${currencyFormat.format(widget.plan.maxAmount)}';
                    }
                    return null;
                },
              ),
              
              const SizedBox(height: 24),

              // Info Grid
              Row(
                children: [
                  Expanded(child: _buildInfoCard(context, 'Tenure', widget.plan.tenure, Icons.calendar_today)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildInfoCard(context, 'Payout', widget.plan.payout, Icons.payments_outlined)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                   Expanded(child: _buildInfoCard(context, 'ROI', widget.plan.roi, Icons.trending_up)),
                ],
              ),

              const SizedBox(height: 24),

              // Calculations
              Text('Projected Returns', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  children: [
                    _buildCalcRow(context, 'Total Investment', currencyFormat.format(_currentAmount), isBold: true),
                    const Divider(),
                    _buildCalcRow(context, 'Approx Yearly Profit', currencyFormat.format(annualProfit)),
                    _buildCalcRow(context, 'Approx Total Profit', currencyFormat.format(totalProfit)),
                     // If payout is yearly, total profit is simple; if compounding involved, it differs, but simple interest assumption here.
                    const Divider(),
                    _buildCalcRow(context, 'Net Profit (Post-TDS)', currencyFormat.format(netProfit), isGreen: true),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Next Payout Estimate', style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600], fontSize: 13)),
                        Text(dateFormat.format(nextPayoutDate), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDarkMode ? Colors.white70 : Colors.black87)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // TDS & Legal
               Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'TDS will be deducted as per applicable income tax rules. TDS certificate will be available in app.',
                        style: TextStyle(color: Colors.blue[800], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              const Text(
                'Risk Disclaimer: Investments are subject to market risks. Please read all scheme related documents carefully.',
                style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  // Mock action
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening Legal Terms...')));
                },
                child: Text(
                  'View Legal Terms for this Plan',
                  style: TextStyle(color: Theme.of(context).primaryColor, decoration: TextDecoration.underline),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _selectPlan,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Select this Plan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, String label, String value, IconData icon) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDarkMode ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildCalcRow(BuildContext context, String label, String value, {bool isBold = false, bool isGreen = false}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[700], 
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal
          )),
          Text(value, style: TextStyle(
            fontWeight: isBold || isGreen ? FontWeight.bold : FontWeight.w500,
            fontSize: isBold || isGreen ? 16 : 14,
            color: isGreen ? Colors.green[700] : (isDarkMode ? Colors.white : Colors.black87),
          )),
        ],
      ),
    );
  }
}
