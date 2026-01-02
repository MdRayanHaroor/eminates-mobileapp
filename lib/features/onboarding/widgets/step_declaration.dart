import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:investorapp_eminates/features/onboarding/providers/onboarding_provider.dart';
import 'package:intl/intl.dart';

class StepDeclaration extends ConsumerStatefulWidget {
  const StepDeclaration({super.key});

  @override
  ConsumerState<StepDeclaration> createState() => _StepDeclarationState();
}

class _StepDeclarationState extends ConsumerState<StepDeclaration> {
  final _placeController = TextEditingController();
  final _dateController = TextEditingController();
  bool _isConfirmed = false;

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
    _placeController.text = state.declarationPlace ?? '';
    _dateController.text = state.declarationDate != null 
        ? DateFormat('yyyy-MM-dd').format(state.declarationDate!) 
        : DateFormat('yyyy-MM-dd').format(DateTime.now());
    _isConfirmed = state.isConfirmed;

    // Set default date if empty
    if (state.declarationDate == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final currentRequest = ref.read(currentEditingRequestProvider);
        ref.read(onboardingFormProvider(currentRequest).notifier).updateDeclaration(declarationDate: DateTime.now());
      });
    }

    _placeController.addListener(() {
      final currentRequest = ref.read(currentEditingRequestProvider);
      ref.read(onboardingFormProvider(currentRequest).notifier).updateDeclaration(declarationPlace: _placeController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Section H: Final Declaration', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'I/We hereby declare that the details furnished above are true and correct to the best of my/our knowledge and belief and I/we undertake to inform you of any changes therein, immediately. In case any of the above information is found to be false or untrue or misleading or misrepresenting, I/we am/are aware that I/we may be held liable for it.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
        ),
        const SizedBox(height: 24),
        TextFormField(controller: _placeController, decoration: _getInputDecoration('Place')),
        const SizedBox(height: 8),
        TextFormField(
          controller: _dateController,
          decoration: _getInputDecoration('Date', suffixIcon: const Icon(Icons.calendar_today)),
          readOnly: true,
        ),
        const SizedBox(height: 24),
        CheckboxListTile(
          title: const Text('I confirm that I have read and agreed to the declaration above.'),
          value: _isConfirmed,
          onChanged: (val) {
            setState(() => _isConfirmed = val ?? false);
            final currentRequest = ref.read(currentEditingRequestProvider);
            ref.read(onboardingFormProvider(currentRequest).notifier).updateDeclaration(isConfirmed: val);
          },
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }
}
