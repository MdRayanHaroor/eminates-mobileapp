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
  late TextEditingController _tenureController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _roiController = TextEditingController(text: widget.plan.roiPercentage.toString());
    _minAmountController = TextEditingController(text: widget.plan.minAmount?.toString() ?? '0');
    _tenureController = TextEditingController(text: widget.plan.tenureYears.toString());
  }

  @override
  void dispose() {
    _roiController.dispose();
    _minAmountController.dispose();
    _tenureController.dispose();
    super.dispose();
  }

  Future<void> _savePlan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final updatedPlan = InvestmentPlan(
        id: widget.plan.id,
        name: widget.plan.name,
        amountWithSymbol: widget.plan.amountWithSymbol, // This string is derived, but ID keeps link
        tenure: widget.plan.tenure, // Derived
        payout: widget.plan.payout, // Derived
        roi: widget.plan.roi, // Derived
        description: widget.plan.description,
        isCustom: widget.plan.isCustom,
        
        // Updated Values
        roiPercentage: double.parse(_roiController.text),
        minAmount: double.parse(_minAmountController.text),
        maxAmount: widget.plan.maxAmount, // Keep existing max for now
        tenureYears: double.parse(_tenureController.text),
        payoutFrequencyMonths: widget.plan.payoutFrequencyMonths,
        features: widget.plan.features,
        isActive: widget.plan.isActive,
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
              TextFormField(
                controller: _roiController,
                decoration: const InputDecoration(labelText: 'Annual ROI (%)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tenureController,
                decoration: const InputDecoration(labelText: 'Tenure (Years)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _minAmountController,
                decoration: const InputDecoration(labelText: 'Min Investment Amount', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _savePlan,
                  child: _isLoading ? const CircularProgressIndicator() : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
