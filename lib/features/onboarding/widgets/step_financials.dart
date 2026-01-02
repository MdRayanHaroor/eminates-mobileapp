import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:investorapp_eminates/features/onboarding/providers/onboarding_provider.dart';
import 'package:intl/intl.dart';

class StepFinancials extends ConsumerStatefulWidget {
  const StepFinancials({super.key});

  @override
  ConsumerState<StepFinancials> createState() => _StepFinancialsState();
}

class _StepFinancialsState extends ConsumerState<StepFinancials> {
  final _bankNameController = TextEditingController();
  final _accountHolderController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscController = TextEditingController();
  final _branchController = TextEditingController();
  
  final _nomineeNameController = TextEditingController();
  final _nomineeRelController = TextEditingController();
  final _nomineeDobController = TextEditingController();
  final _nomineeContactController = TextEditingController();
  final _nomineeAddressController = TextEditingController();

  // Helper for consistent dark mode friendly decoration
  InputDecoration _getInputDecoration(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      suffixIcon: suffixIcon,
      labelStyle: const TextStyle(color: Colors.grey),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.blue),
         borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      filled: true,
      fillColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[900] : Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  @override
  void initState() {
    super.initState();
    final currentRequest = ref.read(currentEditingRequestProvider);
    final state = ref.read(onboardingFormProvider(currentRequest));
    _bankNameController.text = state.bankName ?? '';
    _accountHolderController.text = state.accountHolderName ?? '';
    _accountNumberController.text = state.accountNumber ?? '';
    _ifscController.text = state.ifscCode ?? '';
    _branchController.text = state.branchNameLocation ?? '';
    
    _nomineeNameController.text = state.nomineeName ?? '';
    _nomineeRelController.text = state.nomineeRelationship ?? '';
    _nomineeDobController.text = state.nomineeDob != null ? DateFormat('yyyy-MM-dd').format(state.nomineeDob!) : '';
    _nomineeContactController.text = state.nomineeContact ?? '';
    _nomineeAddressController.text = state.nomineeAddress ?? '';

    _bankNameController.addListener(_updateState);
    _accountHolderController.addListener(_updateState);
    _accountNumberController.addListener(_updateState);
    _ifscController.addListener(_updateState);
    _branchController.addListener(_updateState);
    
    _nomineeNameController.addListener(_updateState);
    _nomineeRelController.addListener(_updateState);
    _nomineeContactController.addListener(_updateState);
    _nomineeAddressController.addListener(_updateState);
  }

  void _updateState() {
    final currentRequest = ref.read(currentEditingRequestProvider);
    ref.read(onboardingFormProvider(currentRequest).notifier).updateFinancialDetails(
      bankName: _bankNameController.text,
      accountHolderName: _accountHolderController.text,
      accountNumber: _accountNumberController.text,
      ifscCode: _ifscController.text,
      branchNameLocation: _branchController.text,
      nomineeName: _nomineeNameController.text,
      nomineeRelationship: _nomineeRelController.text,
      nomineeContact: _nomineeContactController.text,
      nomineeAddress: _nomineeAddressController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRequest = ref.watch(currentEditingRequestProvider);
    final state = ref.watch(onboardingFormProvider(currentRequest));

    const relationships = ['Father', 'Mother', 'Sibling', 'Spouse', 'Child', 'Other'];
    String? selectedRelationship;
    if (_nomineeRelController.text.isNotEmpty) {
      try {
        selectedRelationship = relationships.firstWhere(
          (element) => element.toLowerCase() == _nomineeRelController.text.toLowerCase(),
        );
      } catch (e) {
        selectedRelationship = null;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Section F: Bank Details', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        TextFormField(controller: _bankNameController, decoration: _getInputDecoration('Bank Name *')),
        const SizedBox(height: 8),
        Row(
          children: [
            Checkbox(
              value: _accountHolderController.text == state.fullName && _accountHolderController.text.isNotEmpty,
              onChanged: (val) {
                if (val == true) {
                  _accountHolderController.text = state.fullName ?? '';
                  _updateState();
                } else {
                  _accountHolderController.clear();
                  _updateState();
                }
              },
            ),
            const Text('Same as Applicant Name'),
          ],
        ),
        TextFormField(controller: _accountHolderController, decoration: _getInputDecoration('Account Holder Name *')),
        const SizedBox(height: 8),
        TextFormField(
          controller: _accountNumberController,
          decoration: _getInputDecoration('Account Number *'),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Account Number is required';
            if (!RegExp(r'^[0-9]+$').hasMatch(value)) return 'Only digits allowed';
            return null;
          },
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _ifscController,
          decoration: _getInputDecoration('IFSC Code *'),
          textCapitalization: TextCapitalization.characters,
          validator: (value) {
            if (value == null || value.isEmpty) return 'IFSC is required';
            if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(value)) return 'Invalid IFSC format';
            return null;
          },
        ),
        const SizedBox(height: 8),
        TextFormField(controller: _branchController, decoration: _getInputDecoration('Branch Name & Location *')),
        
        const SizedBox(height: 24),
        Text('Section G: Nominee Details', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        TextFormField(controller: _nomineeNameController, decoration: _getInputDecoration('Nominee Full Name *')),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedRelationship,
          decoration: _getInputDecoration('Relationship *'),
          items: relationships.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: (val) {
            if (val != null) {
              _nomineeRelController.text = val;
              _updateState();
            }
          },
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nomineeDobController,
          decoration: _getInputDecoration('Nominee Date of Birth *', suffixIcon: const Icon(Icons.calendar_today)),
          readOnly: true,
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (date != null) {
              _nomineeDobController.text = DateFormat('yyyy-MM-dd').format(date);
              final currentRequest = ref.read(currentEditingRequestProvider);
              ref.read(onboardingFormProvider(currentRequest).notifier).updateFinancialDetails(nomineeDob: date);
            }
          },
        ),
        const SizedBox(height: 8),
        TextFormField(controller: _nomineeContactController, decoration: _getInputDecoration('Nominee Contact Number *'), keyboardType: TextInputType.phone),
        const SizedBox(height: 8),
        TextFormField(controller: _nomineeAddressController, decoration: _getInputDecoration('Nominee Address *')),
      ],
    );
  }
}
