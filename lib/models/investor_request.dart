class InvestorRequest {
  final String? id;
  final String? investorId;
  final String userId;
  final String status;
  
  // Section A: Personal Information
  final String? fullName;
  final String? fatherName;
  final String? motherName;
  final DateTime? dob;
  final String? nationality;
  final String? nativePlace;
  final String? education;
  final String? occupation;
  final String? monthlyIncome;
  final String? gender;
  final String? maritalStatus;
  
  // Section B: Residential Address
  final String? addressDoorNo;
  final String? addressStreet;
  final String? addressCity;
  final String? addressDistrict;
  final String? addressState;
  final String? addressPincode;
  final String? addressLandmark;
  
  // Section C: Contact Details
  final String? primaryMobile;
  final String? alternateMobile;
  final String? whatsappNumber;
  final String? emailAddress;
  
  // Section D: KYC Details
  final String? panNumber;
  final String? aadhaarNumber;
  final String? voterId;
  final String? passportNumber;
  final String? panCardUrl;
  final String? aadhaarCardUrl;
  final String? selfieUrl;
  
  // Section E: Bank Details
  final String? bankName;
  final String? accountHolderName;
  final String? accountNumber;
  final String? ifscCode;
  final String? branchNameLocation;
  
  // Section F: Nominee Details
  final String? nomineeName;
  final String? nomineeRelationship;
  final DateTime? nomineeDob;
  final String? nomineeContact;
  final String? nomineeAddress;
  
  // Section G: Investment Package
  final String? investmentAmount;
  final String? planName;
  
  // Section H: Declaration
  final String? declarationPlace;
  final DateTime? declarationDate;
  final bool isConfirmed;
  
  // Transaction Details (Post-Acceptance)
  final String? transactionUtr;
  final DateTime? transactionDate;
  
  final DateTime? createdAt;
  final DateTime? updatedAt;

  InvestorRequest({
    this.id,
    this.investorId,
    required this.userId,
    this.status = 'Pending',
    this.fullName,
    this.fatherName,
    this.motherName,
    this.dob,
    this.nationality,
    this.nativePlace,
    this.education,
    this.occupation,
    this.monthlyIncome,
    this.gender,
    this.maritalStatus,
    this.addressDoorNo,
    this.addressStreet,
    this.addressCity,
    this.addressDistrict,
    this.addressState,
    this.addressPincode,
    this.addressLandmark,
    this.primaryMobile,
    this.alternateMobile,
    this.whatsappNumber,
    this.emailAddress,
    this.panNumber,
    this.aadhaarNumber,
    this.voterId,
    this.passportNumber,
    this.panCardUrl,
    this.aadhaarCardUrl,
    this.selfieUrl,
    this.bankName,
    this.accountHolderName,
    this.accountNumber,
    this.ifscCode,
    this.branchNameLocation,
    this.nomineeName,
    this.nomineeRelationship,
    this.nomineeDob,
    this.nomineeContact,
    this.nomineeAddress,
    this.investmentAmount,
    this.planName,
    this.declarationPlace,
    this.declarationDate,
    this.isConfirmed = false,
    this.transactionUtr,
    this.transactionDate,
    this.createdAt,
    this.updatedAt,
  });

  // Helper getters
  // If planName is not set (legacy data), try to extract from investmentAmount if it follows the pattern
  String get effectivePlanName {
    if (planName != null && planName!.isNotEmpty) return planName!;
    if (investmentAmount == null) return 'Investment Plan';
    final parts = investmentAmount!.split('–');
    return parts.length > 1 ? parts[1].trim() : parts[0].trim(); // Fallback
  }

  double get parsedAmount {
    if (investmentAmount == null) return 0;
    // Attempt to parse directly first
    final directParse = double.tryParse(investmentAmount!.replaceAll(',', ''));
    if (directParse != null) return directParse;
    
    // Fallback for legacy mixed string
    final parts = investmentAmount!.split('–');
    final amtStr = parts[0].replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(amtStr) ?? 0;
  }

  factory InvestorRequest.fromJson(Map<String, dynamic> json) {
    return InvestorRequest(
      id: json['id'] as String?,
      investorId: json['investor_id'] as String?,
      userId: json['user_id'] as String,
      status: json['status'] as String? ?? 'Pending',
      fullName: json['full_name'] as String?,
      fatherName: json['father_name'] as String?,
      motherName: json['mother_name'] as String?,
      dob: json['dob'] != null ? DateTime.tryParse(json['dob']) : null,
      nationality: json['nationality'] as String?,
      nativePlace: json['native_place'] as String?,
      education: json['education'] as String?,
      occupation: json['occupation'] as String?,
      monthlyIncome: json['monthly_income'] as String?,
      gender: json['gender'] as String?,
      maritalStatus: json['marital_status'] as String?,
      addressDoorNo: json['address_door_no'] as String?,
      addressStreet: json['address_street'] as String?,
      addressCity: json['address_city'] as String?,
      addressDistrict: json['address_district'] as String?,
      addressState: json['address_state'] as String?,
      addressPincode: json['address_pincode'] as String?,
      addressLandmark: json['address_landmark'] as String?,
      primaryMobile: json['primary_mobile'] as String?,
      alternateMobile: json['alternate_mobile'] as String?,
      whatsappNumber: json['whatsapp_number'] as String?,
      emailAddress: json['email_address'] as String?,
      panNumber: json['pan_number'] as String?,
      aadhaarNumber: json['aadhaar_number'] as String?,
      voterId: json['voter_id'] as String?,
      passportNumber: json['passport_number'] as String?,
      panCardUrl: json['pan_card_url'] as String?,
      aadhaarCardUrl: json['aadhaar_card_url'] as String?,
      selfieUrl: json['selfie_url'] as String?,
      bankName: json['bank_name'] as String?,
      accountHolderName: json['account_holder_name'] as String?,
      accountNumber: json['account_number'] as String?,
      ifscCode: json['ifsc_code'] as String?,
      branchNameLocation: json['branch_name_location'] as String?,
      nomineeName: json['nominee_name'] as String?,
      nomineeRelationship: json['nominee_relationship'] as String?,
      nomineeDob: json['nominee_dob'] != null ? DateTime.tryParse(json['nominee_dob']) : null,
      nomineeContact: json['nominee_contact'] as String?,
      nomineeAddress: json['nominee_address'] as String?,
      investmentAmount: json['investment_amount'] as String?,
      planName: json['plan_name'] as String?,
      declarationPlace: json['declaration_place'] as String?,
      declarationDate: json['declaration_date'] != null ? DateTime.tryParse(json['declaration_date']) : null,
      isConfirmed: json['is_confirmed'] as bool? ?? false,
      transactionUtr: json['transaction_utr'] as String?,
      transactionDate: json['transaction_date'] != null ? DateTime.tryParse(json['transaction_date']) : null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (investorId != null) 'investor_id': investorId,
      'user_id': userId,
      'status': status,
      'full_name': fullName,
      'father_name': fatherName,
      'mother_name': motherName,
      'dob': dob?.toIso8601String().split('T')[0], // Date only
      'nationality': nationality,
      'native_place': nativePlace,
      'education': education,
      'occupation': occupation,
      'monthly_income': monthlyIncome,
      'gender': gender,
      'marital_status': maritalStatus,
      'address_door_no': addressDoorNo,
      'address_street': addressStreet,
      'address_city': addressCity,
      'address_district': addressDistrict,
      'address_state': addressState,
      'address_pincode': addressPincode,
      'address_landmark': addressLandmark,
      'primary_mobile': primaryMobile,
      'alternate_mobile': alternateMobile,
      'whatsapp_number': whatsappNumber,
      'email_address': emailAddress,
      'pan_number': panNumber,
      'aadhaar_number': aadhaarNumber,
      'voter_id': voterId,
      'passport_number': passportNumber,
      'pan_card_url': panCardUrl,
      'aadhaar_card_url': aadhaarCardUrl,
      'selfie_url': selfieUrl,
      'bank_name': bankName,
      'account_holder_name': accountHolderName,
      'account_number': accountNumber,
      'ifsc_code': ifscCode,
      'branch_name_location': branchNameLocation,
      'nominee_name': nomineeName,
      'nominee_relationship': nomineeRelationship,
      'nominee_dob': nomineeDob?.toIso8601String().split('T')[0],
      'nominee_contact': nomineeContact,
      'nominee_address': nomineeAddress,
      'investment_amount': investmentAmount,
      'plan_name': planName,
      'declaration_place': declarationPlace,
      'declaration_date': declarationDate?.toIso8601String().split('T')[0],
      'is_confirmed': isConfirmed,
      'transaction_utr': transactionUtr,
      'transaction_date': transactionDate?.toIso8601String(),
    };
  }
}
