class InvestmentPlan {
  final String name;
  final String amountWithSymbol;
  final String tenure;
  final String payout;
  final String roi;
  final String? description;
  final bool isCustom;
  final double? minAmount;
  
  // Numeric values for calculations
  final double roiPercentage; // e.g., 24.0 for 24%
  final double tenureYears; // e.g., 3.0
  final int payoutFrequencyMonths; // e.g., 3 for Quarterly, 12 for Yearly

  const InvestmentPlan({
    required this.name,
    required this.amountWithSymbol,
    required this.tenure,
    required this.payout,
    required this.roi,
    required this.roiPercentage,
    required this.tenureYears,
    required this.payoutFrequencyMonths,
    this.description,
    this.isCustom = false,
    this.minAmount,
  });
}
