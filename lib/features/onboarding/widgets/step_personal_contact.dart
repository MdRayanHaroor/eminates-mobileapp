import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:investorapp_eminates/features/auth/providers/auth_provider.dart';
import 'package:investorapp_eminates/features/onboarding/providers/onboarding_provider.dart';
import 'package:intl/intl.dart';

class StepPersonalContact extends ConsumerStatefulWidget {
  const StepPersonalContact({super.key});

  @override
  ConsumerState<StepPersonalContact> createState() => _StepPersonalContactState();
}

class _StepPersonalContactState extends ConsumerState<StepPersonalContact> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _fullNameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _nationalityController = TextEditingController();
  final _nativePlaceController = TextEditingController();
  final _educationController = TextEditingController();
  final _occupationController = TextEditingController();
  final _monthlyIncomeController = TextEditingController();
  final _genderController = TextEditingController();
  final _maritalStatusController = TextEditingController();
  
  final _doorNoController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _landmarkController = TextEditingController();
  
  final _primaryMobileController = TextEditingController();
  final _alternateMobileController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isWhatsappSameAsPrimary = false;

  final List<String> _indianStates = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh', 'Goa', 'Gujarat', 
    'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka', 'Kerala', 'Madhya Pradesh', 
    'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha', 'Punjab', 
    'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura', 'Uttar Pradesh', 
    'Uttarakhand', 'West Bengal', 'Andaman and Nicobar Islands', 'Chandigarh', 
    'Dadra and Nagar Haveli and Daman and Diu', 'Lakshadweep', 'Delhi', 'Puducherry', 
    'Ladakh', 'Jammu and Kashmir'
  ];

  final List<String> _emirates = [
    'Abu Dhabi', 'Dubai', 'Sharjah', 'Ajman', 'Umm Al Quwain', 'Ras Al Khaimah', 'Fujairah'
  ];

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current state
    final state = ref.read(onboardingFormProvider);
    final user = ref.read(currentUserProvider);

    // Auto-fill Full Name if not already set
    if (state.fullName == null || state.fullName!.isEmpty) {
      final userFullName = user?.userMetadata?['full_name'] ?? user?.userMetadata?['name'] ?? user?.userMetadata?['display_name'] ?? '';
      _fullNameController.text = userFullName;
      if (userFullName.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(onboardingFormProvider.notifier).updatePersonalDetails(fullName: userFullName);
        });
      }
    } else {
      _fullNameController.text = state.fullName ?? '';
    }

    _fatherNameController.text = state.fatherName ?? '';
    _motherNameController.text = state.motherName ?? '';
    _dobController.text = state.dob != null ? DateFormat('yyyy-MM-dd').format(state.dob!) : '';
    _nationalityController.text = state.nationality ?? 'Indian'; // Default to Indian
    _nativePlaceController.text = state.nativePlace ?? '';
    _educationController.text = state.education ?? '';
    _occupationController.text = state.occupation ?? '';
    _monthlyIncomeController.text = state.monthlyIncome ?? '';
    _genderController.text = state.gender ?? '';
    _maritalStatusController.text = state.maritalStatus ?? '';
    
    _doorNoController.text = state.addressDoorNo ?? '';
    _streetController.text = state.addressStreet ?? '';
    _cityController.text = state.addressCity ?? '';
    _districtController.text = state.addressDistrict ?? '';
    _stateController.text = state.addressState ?? '';
    _pincodeController.text = state.addressPincode ?? '';
    _landmarkController.text = state.addressLandmark ?? '';
    
    _primaryMobileController.text = state.primaryMobile ?? '';
    _alternateMobileController.text = state.alternateMobile ?? '';
    _whatsappController.text = state.whatsappNumber ?? '';
    
    // Auto-fill email if not already set
    if (state.emailAddress == null || state.emailAddress!.isEmpty) {
      _emailController.text = user?.email ?? '';
      // Update state immediately
      WidgetsBinding.instance.addPostFrameCallback((_) {
         ref.read(onboardingFormProvider.notifier).updateContactDetails(emailAddress: _emailController.text);
      });
    } else {
      _emailController.text = state.emailAddress ?? '';
    }

    // Listen to changes
    _fullNameController.addListener(_updateState);
    _fatherNameController.addListener(_updateState);
    _motherNameController.addListener(_updateState);
    _nationalityController.addListener(_updateState);
    _nativePlaceController.addListener(_updateState);
    _educationController.addListener(_updateState);
    _occupationController.addListener(_updateState);
    _monthlyIncomeController.addListener(_updateState);
    _genderController.addListener(_updateState);
    _maritalStatusController.addListener(_updateState);
    
    _doorNoController.addListener(_updateAddressState);
    _streetController.addListener(_updateAddressState);
    _cityController.addListener(_updateAddressState);
    _districtController.addListener(_updateAddressState);
    _stateController.addListener(_updateAddressState);
    _pincodeController.addListener(_updateAddressState);
    _landmarkController.addListener(_updateAddressState);
    
    _primaryMobileController.addListener(_updateContactState);
    _alternateMobileController.addListener(_updateContactState);
    _whatsappController.addListener(_updateContactState);
    _emailController.addListener(_updateContactState);
  }

  void _updateState() {
    ref.read(onboardingFormProvider.notifier).updatePersonalDetails(
      fullName: _fullNameController.text,
      fatherName: _fatherNameController.text,
      motherName: _motherNameController.text,
      nationality: _nationalityController.text,
      nativePlace: _nativePlaceController.text,
      education: _educationController.text,
      occupation: _occupationController.text,
      monthlyIncome: _monthlyIncomeController.text,
      gender: _genderController.text,
      maritalStatus: _maritalStatusController.text,
    );
  }
  
  void _updateAddressState() {
    ref.read(onboardingFormProvider.notifier).updateAddressDetails(
      addressDoorNo: _doorNoController.text,
      addressStreet: _streetController.text,
      addressCity: _cityController.text,
      addressDistrict: _districtController.text,
      addressState: _stateController.text,
      addressPincode: _pincodeController.text,
      addressLandmark: _landmarkController.text,
    );
  }
  
  void _updateContactState() {
    if (_isWhatsappSameAsPrimary) {
      if (_whatsappController.text != _primaryMobileController.text) {
        _whatsappController.text = _primaryMobileController.text;
      }
    }
    
    ref.read(onboardingFormProvider.notifier).updateContactDetails(
      primaryMobile: _primaryMobileController.text,
      alternateMobile: _alternateMobileController.text,
      whatsappNumber: _whatsappController.text,
      emailAddress: _emailController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Section B: Personal Information', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextFormField(controller: _fullNameController, decoration: const InputDecoration(labelText: 'Full Name (as per PAN) *')),
          const SizedBox(height: 8),
          TextFormField(controller: _fatherNameController, decoration: const InputDecoration(labelText: 'Father\'s Name *')),
          const SizedBox(height: 8),
          TextFormField(controller: _motherNameController, decoration: const InputDecoration(labelText: 'Mother\'s Name *')),
          const SizedBox(height: 8),
          TextFormField(
            controller: _dobController,
            decoration: const InputDecoration(labelText: 'Date of Birth (YYYY-MM-DD) *', suffixIcon: Icon(Icons.calendar_today)),
            readOnly: true,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                _dobController.text = DateFormat('yyyy-MM-dd').format(date);
                ref.read(onboardingFormProvider.notifier).updatePersonalDetails(dob: date);
              }
            },
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _nationalityController.text.isNotEmpty ? _nationalityController.text : 'Indian',
            decoration: const InputDecoration(labelText: 'Nationality *'),
            items: ['Indian', 'Emirati'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _nationalityController.text = val;
                  _stateController.clear(); // Reset state when nationality changes
                });
                // Force update to provider to clear state in backend state as well
                ref.read(onboardingFormProvider.notifier).updateAddressDetails(addressState: '');
                _updateState();
              }
            },
          ),
          const SizedBox(height: 8),
          TextFormField(controller: _nativePlaceController, decoration: const InputDecoration(labelText: 'Native Place *')),
          const SizedBox(height: 8),
          TextFormField(controller: _educationController, decoration: const InputDecoration(labelText: 'Highest Education *')),
          const SizedBox(height: 8),
          TextFormField(controller: _occupationController, decoration: const InputDecoration(labelText: 'Occupation / Profession *')),
          const SizedBox(height: 8),
          TextFormField(controller: _monthlyIncomeController, decoration: const InputDecoration(labelText: 'Regular Monthly Income *')),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _genderController.text.isEmpty ? null : _genderController.text,
            decoration: const InputDecoration(labelText: 'Gender *'),
            items: ['Male', 'Female', 'Other'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (val) {
              if (val != null) {
                _genderController.text = val;
                _updateState();
              }
            },
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _maritalStatusController.text.isEmpty ? null : _maritalStatusController.text,
            decoration: const InputDecoration(labelText: 'Marital Status *'),
            items: ['Single', 'Married', 'Divorced', 'Widowed'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (val) {
              if (val != null) {
                _maritalStatusController.text = val;
                _updateState();
              }
            },
          ),
          
          const SizedBox(height: 24),
          Text('Section C: Residential Address', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextFormField(controller: _doorNoController, decoration: const InputDecoration(labelText: 'Door / Flat No *')),
          const SizedBox(height: 8),
          TextFormField(controller: _streetController, decoration: const InputDecoration(labelText: 'Street / Area *')),
          const SizedBox(height: 8),
          TextFormField(controller: _cityController, decoration: const InputDecoration(labelText: 'Town / City / Village *')),
          const SizedBox(height: 8),
          TextFormField(controller: _districtController, decoration: const InputDecoration(labelText: 'District *')),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _stateController.text.isNotEmpty && (_indianStates.contains(_stateController.text) || _emirates.contains(_stateController.text)) 
                ? _stateController.text 
                : null,
            decoration: const InputDecoration(labelText: 'State / Emirate *'),
            items: _nationalityController.text == 'Indian'
                ? _indianStates.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList()
                : _emirates.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (val) {
              if (val != null) {
                _stateController.text = val;
                _updateAddressState();
              }
            },
          ),
          const SizedBox(height: 8),
          TextFormField(controller: _pincodeController, decoration: const InputDecoration(labelText: 'Pincode *'), keyboardType: TextInputType.number),
          const SizedBox(height: 8),
          TextFormField(controller: _landmarkController, decoration: const InputDecoration(labelText: 'Nearest Landmark')),
          
          const SizedBox(height: 24),
          Text('Section D: Contact Details', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextFormField(controller: _primaryMobileController, decoration: const InputDecoration(labelText: 'Primary Mobile Number *'), keyboardType: TextInputType.phone),
          const SizedBox(height: 8),
          TextFormField(controller: _alternateMobileController, decoration: const InputDecoration(labelText: 'Alternate Mobile Number'), keyboardType: TextInputType.phone),
          const SizedBox(height: 8),
          Row(
            children: [
              Checkbox(
                value: _isWhatsappSameAsPrimary,
                onChanged: (val) {
                  setState(() {
                    _isWhatsappSameAsPrimary = val ?? false;
                    if (_isWhatsappSameAsPrimary) {
                      _whatsappController.text = _primaryMobileController.text;
                      _updateContactState();
                    }
                  });
                },
              ),
              const Text('WhatsApp same as Primary Mobile'),
            ],
          ),
          TextFormField(
            controller: _whatsappController, 
            decoration: const InputDecoration(labelText: 'WhatsApp Number *'), 
            keyboardType: TextInputType.phone,
            enabled: !_isWhatsappSameAsPrimary,
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController, 
            decoration: const InputDecoration(labelText: 'Email Address *'), 
            keyboardType: TextInputType.emailAddress,
            readOnly: true, // Email is auto-filled and read-only
          ),
        ],
      ),
    );
  }
}
