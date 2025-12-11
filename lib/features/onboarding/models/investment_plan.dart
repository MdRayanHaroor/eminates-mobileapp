class InvestmentPlan {
  final String? id; // Supabase UUID
  final String name;
  final String amountWithSymbol; // Derived or stored? We'll derive it if not custom
  final String tenure; // Derived or stored?
  final String payout; // Derived or stored?
  final String roi; // Derived or stored?
  final String? description;
  final bool isCustom;
  final double? minAmount;
  final double? maxAmount; // New from DB
  
  // Numeric values for calculations
  final double roiPercentage; // e.g., 24.0 for 24%
  final double tenureYears; // e.g., 3.0
  final int payoutFrequencyMonths; // derived from features or stored?
  final List<String> features; // New from DB
  final bool isActive; // New from DB

  const InvestmentPlan({
    this.id,
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
    this.maxAmount,
    this.features = const [],
    this.isActive = true,
  });

  factory InvestmentPlan.fromJson(Map<String, dynamic> json) {
    // Map DB fields to UI fields
    final durationMonths = json['duration_months'] as int;
    final roiPct = (json['roi_percentage'] as num).toDouble();
    final isCustom = json['is_custom'] as bool? ?? false;
    final minAmt = (json['min_amount'] as num).toDouble();
    final maxAmt = (json['max_amount'] as num).toDouble();
    final featuresList = List<String>.from(json['features'] ?? []);
    
    // Derived UI Strings
    // Tenure
    final years = durationMonths / 12;
    final tenureStr = years % 1 == 0 ? '${years.toInt()} years' : '${years.toStringAsFixed(1)} years';
    
    // Payout Frequency - derive from features or rules
    // Silver: Quarterly (3), Gold: Half-Yearly (6), Platinum: Yearly (12)
    int payoutFreq = 3;
    String payoutStr = 'Quarterly';
    if (json['name'].toString().contains('Gold')) {
      payoutFreq = 6;
      payoutStr = 'Half-yearly';
    } else if (json['name'].toString().contains('Platinum') || json['name'].toString().contains('Elite')) {
      payoutFreq = 12;
      payoutStr = 'Yearly';
    }
    
    // Amount String
    String amtStr;
    String formatCurrency(double amount) {
       // Simple formatter for India locale like string
       // 100000 -> 1,00,000
       final intVal = amount.toInt();
       if (intVal >= 100000 && intVal < 10000000) {
          return '${(intVal/100000).toStringAsFixed(0)},${(intVal%100000).toString().padLeft(3,'0').padLeft(5,'0').substring(0,2)},${(intVal%1000).toString().padLeft(3,'0')}'.replaceAll(',00,', ',00,'); // Quick crude format
       }
       // Fallback to simple
       return intVal.toString();
    }
    
    // Better simple formatter logic since we can't import intl easily without checking deps
    String toLakhs(double val) {
       int v = val.toInt();
       if (v == 100000) return '1,00,000';
       if (v == 300000) return '3,00,000';
       if (v == 500000) return '5,00,000';
       if (v == 1000000) return '10,00,000';
       if (val >= 10000000) return '1 Cr+';
       return v.toString(); // Fallback
    }

    if (isCustom) {
      amtStr = 'Above ₹${toLakhs(minAmt)}';
    } else {
      if (maxAmt > 0) {
         amtStr = 'Up to ₹${toLakhs(maxAmt)}';
      } else {
         amtStr = '₹${toLakhs(minAmt)}';
      }
    }

    return InvestmentPlan(
      id: json['id'],
      name: json['name'],
      amountWithSymbol: amtStr,
      tenure: tenureStr,
      payout: payoutStr,
      roi: 'Approx $roiPct% annual',
      roiPercentage: roiPct,
      tenureYears: years,
      payoutFrequencyMonths: payoutFreq,
      description: json['description'],
      isCustom: isCustom,
      minAmount: minAmt,
      maxAmount: maxAmt,
      features: featuresList,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      // ... only useful if we were writing back to DB, but mostly we read
    };
  }
}
