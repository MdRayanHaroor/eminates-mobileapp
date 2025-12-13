import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:investorapp_eminates/features/dashboard/providers/dashboard_provider.dart';
import 'package:investorapp_eminates/features/onboarding/models/investment_plan.dart';

class EditPlanScreen extends ConsumerStatefulWidget {
  final InvestmentPlan plan;

  const EditPlanScreen({super.key, required this.plan});

  @override
  ConsumerState<EditPlanScreen> createState() => _EditPlanScreenState();
}

class _EditPlanScreenState extends ConsumerState<EditPlanScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _roiController;
  late TextEditingController _minAmountController;
  late TextEditingController _maxAmountController;
  late TextEditingController _tenureController; // Kept for display/legacy basic tenure text
  
  // New Controllers
  late TextEditingController _monthlyProfitController;
  late TextEditingController _descriptionController;
  late TextEditingController _featuresController; // One per line
  bool _isActive = true;
  
  // Dynamic Tenure Bonuses
  final Map<int, TextEditingController> _bonusControllers = {}; // Key: Years, Value: Controller for Bonus %

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _roiController = TextEditingController(text: widget.plan.roiPercentage.toString());
    _minAmountController = TextEditingController(text: widget.plan.minAmount?.toString() ?? '0');
    _maxAmountController = TextEditingController(text: widget.plan.maxAmount?.toString() ?? '');
    _tenureController = TextEditingController(text: widget.plan.tenureYears.toString()); // Display tenure
    
    _monthlyProfitController = TextEditingController(text: widget.plan.monthlyProfitPercentage.toString());
    _descriptionController = TextEditingController(text: widget.plan.description ?? '');
    _featuresController = TextEditingController(text: widget.plan.features.join('\n'));
    _isActive = widget.plan.isActive;

    // Initialize Bonus Controllers
    widget.plan.tenureBonuses.forEach((year, bonus) {
      _bonusControllers[year] = TextEditingController(text: bonus.toString());
    });
  }

  @override
  void dispose() {
    _roiController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    _tenureController.dispose();
    _monthlyProfitController.dispose();
    _descriptionController.dispose();
    _featuresController.dispose();
    for (var c in _bonusControllers.values) {
      c.dispose();
    }
    super.dispose();
  }
  
  void _addTenureOption() {
     // Simple Dialog to ask for Year
     showDialog(
       context: context, 
       builder: (ctx) {
         final yearCtrl = TextEditingController();
         return AlertDialog(
           title: const Text('Add Tenure Option'),
           content: TextField(
             controller: yearCtrl,
             decoration: const InputDecoration(labelText: 'Years (e.g. 3)'),
             keyboardType: TextInputType.number,
           ),
           actions: [
             TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
             TextButton(
               onPressed: () {
                 final y = int.tryParse(yearCtrl.text);
                 if (y != null && !_bonusControllers.containsKey(y)) {
                   setState(() {
                     _bonusControllers[y] = TextEditingController(text: '0');
                   });
                   Navigator.pop(ctx);
                 }
               },
               child: const Text('Add'),
             )
           ],
         );
       }
     );
  }

  void _removeTenureOption(int year) {
    setState(() {
       _bonusControllers[year]?.dispose();
       _bonusControllers.remove(year);
    });
  }

  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // Parse Features
      final featuresList = _featuresController.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // Parse Tenure Bonuses
      final Map<int, double> tenureMap = {};
      _bonusControllers.forEach((year, ctrl) {
         tenureMap[year] = double.tryParse(ctrl.text) ?? 0.0;
      });

      final updatedPlan = InvestmentPlan(
        id: widget.plan.id,
        name: widget.plan.name,
        // Derived Fields (Ideally, these should also include 'tenure' based on bonuses, but kept simple for now)
        amountWithSymbol: widget.plan.amountWithSymbol, 
        tenure: widget.plan.tenure, 
        payout: widget.plan.payout, 
        roi: widget.plan.roi, 
        
        description: _descriptionController.text,
        isCustom: widget.plan.isCustom,
        
        // Updated Values
        roiPercentage: double.parse(_roiController.text),
        minAmount: double.parse(_minAmountController.text),
        maxAmount: _maxAmountController.text.isNotEmpty ? double.parse(_maxAmountController.text) : null,
        tenureYears: double.parse(_tenureController.text), // Still kept as 'primary' tenure logic if usage elsewhere
        payoutFrequencyMonths: widget.plan.payoutFrequencyMonths,
        
        features: featuresList,
        isActive: _isActive,
        monthlyProfitPercentage: double.parse(_monthlyProfitController.text),
        tenureBonuses: tenureMap,
      );

      await ref.read(investorRepositoryProvider).updateInvestmentPlan(updatedPlan);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plan updated successfully')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit ${widget.plan.name}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Active Switch
              SwitchListTile(
                title: const Text('Is Active?'),
                subtitle: const Text('Deactivated plans are hidden from users'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              const Divider(),
              const SizedBox(height: 16),
              
              // Basic Stats
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _roiController,
                      decoration: const InputDecoration(labelText: 'Annual ROI (%)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _monthlyProfitController,
                      decoration: const InputDecoration(labelText: 'Monthly Profit (%)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Amounts
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minAmountController,
                      decoration: const InputDecoration(labelText: 'Min Amount', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _maxAmountController,
                      decoration: const InputDecoration(labelText: 'Max Amount (Optional)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _tenureController,
                decoration: const InputDecoration(labelText: 'Primary Tenure (Display purposes)', border: OutlineInputBorder()),
                 keyboardType: TextInputType.number,
                 validator: (val) => val!.isEmpty ? 'Required' : null,
              ),

              const SizedBox(height: 24),
              const Text('Tenure Options & Maturity Bonuses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              
              // Dynamic Tenure List
              Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                child: Column(
                   children: [
                      ..._bonusControllers.keys.map((year) {
                         return ListTile(
                           title: Text('$year Years'),
                           trailing: SizedBox(
                             width: 150,
                             child: Row(
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                 Expanded(
                                   child: TextFormField(
                                     controller: _bonusControllers[year],
                                     decoration: const InputDecoration(labelText: 'Bonus %', isDense: true),
                                     keyboardType: TextInputType.number,
                                   ),
                                 ),
                                 IconButton(
                                   icon: const Icon(Icons.delete, color: Colors.red),
                                   onPressed: () => _removeTenureOption(year),
                                 ),
                               ],
                             ),
                           ),
                         );
                      }),
                      TextButton.icon(
                        onPressed: _addTenureOption,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Tenure Option'),
                      ),
                   ],
                ),
              ),

              const SizedBox(height: 24),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Plan Description', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _featuresController,
                decoration: const InputDecoration(
                  labelText: 'Features (One per line)', 
                  border: OutlineInputBorder(),
                  hintText: 'High Returns\nSecure\nNo Risk',
                ),
                maxLines: 4,
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _savePlan,
                  child: _isLoading ? const CircularProgressIndicator() : const Text('Save Changes'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
