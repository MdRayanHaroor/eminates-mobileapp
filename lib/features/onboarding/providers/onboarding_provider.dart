import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:investorapp_eminates/features/auth/providers/auth_provider.dart';
import 'package:investorapp_eminates/features/dashboard/providers/dashboard_provider.dart';
import 'package:investorapp_eminates/models/investor_request.dart';

final onboardingStepProvider = StateProvider<int>((ref) => 0);

final onboardingFormProvider = NotifierProvider<OnboardingFormNotifier, InvestorRequest>(OnboardingFormNotifier.new);

class OnboardingFormNotifier extends Notifier<InvestorRequest> {
  @override
  InvestorRequest build() {
    final user = ref.watch(currentUserProvider);
    return InvestorRequest(userId: user?.id ?? '');
  }

  void updatePersonalDetails({
    String? fullName,
    String? fatherName,
    String? motherName,
    DateTime? dob,
    String? nationality,
    String? nativePlace,
    String? education,
    String? occupation,
    String? monthlyIncome,
    String? gender,
    String? maritalStatus,
  }) {
    state = InvestorRequest(
      id: state.id,
      investorId: state.investorId,
      createdAt: state.createdAt,
      updatedAt: state.updatedAt,
      userId: state.userId,
      status: state.status,
      // Keep existing values or update
      fullName: fullName ?? state.fullName,
      fatherName: fatherName ?? state.fatherName,
      motherName: motherName ?? state.motherName,
      dob: dob ?? state.dob,
      nationality: nationality ?? state.nationality,
      nativePlace: nativePlace ?? state.nativePlace,
      education: education ?? state.education,
      occupation: occupation ?? state.occupation,
      monthlyIncome: monthlyIncome ?? state.monthlyIncome,
      gender: gender ?? state.gender,
      maritalStatus: maritalStatus ?? state.maritalStatus,
      // Preserve other sections
      addressDoorNo: state.addressDoorNo,
      addressStreet: state.addressStreet,
      addressCity: state.addressCity,
      addressDistrict: state.addressDistrict,
      addressState: state.addressState,
      addressPincode: state.addressPincode,
      addressLandmark: state.addressLandmark,
      primaryMobile: state.primaryMobile,
      alternateMobile: state.alternateMobile,
      whatsappNumber: state.whatsappNumber,
      emailAddress: state.emailAddress,
      panNumber: state.panNumber,
      aadhaarNumber: state.aadhaarNumber,
      voterId: state.voterId,
      passportNumber: state.passportNumber,
      panCardUrl: state.panCardUrl,
      aadhaarCardUrl: state.aadhaarCardUrl,
      selfieUrl: state.selfieUrl,
      bankName: state.bankName,
      accountHolderName: state.accountHolderName,
      accountNumber: state.accountNumber,
      ifscCode: state.ifscCode,
      branchNameLocation: state.branchNameLocation,
      nomineeName: state.nomineeName,
      nomineeRelationship: state.nomineeRelationship,
      nomineeDob: state.nomineeDob,
      nomineeContact: state.nomineeContact,
      nomineeAddress: state.nomineeAddress,
      investmentAmount: state.investmentAmount,
      declarationPlace: state.declarationPlace,
      declarationDate: state.declarationDate,
      isConfirmed: state.isConfirmed,
    );
  }

  void updateAddressDetails({
    String? addressDoorNo,
    String? addressStreet,
    String? addressCity,
    String? addressDistrict,
    String? addressState,
    String? addressPincode,
    String? addressLandmark,
  }) {
    state = InvestorRequest(
      id: state.id,
      investorId: state.investorId,
      createdAt: state.createdAt,
      updatedAt: state.updatedAt,
      userId: state.userId,
      status: state.status,
      fullName: state.fullName,
      fatherName: state.fatherName,
      motherName: state.motherName,
      dob: state.dob,
      nationality: state.nationality,
      nativePlace: state.nativePlace,
      education: state.education,
      occupation: state.occupation,
      monthlyIncome: state.monthlyIncome,
      gender: state.gender,
      maritalStatus: state.maritalStatus,
      // Update Address
      addressDoorNo: addressDoorNo ?? state.addressDoorNo,
      addressStreet: addressStreet ?? state.addressStreet,
      addressCity: addressCity ?? state.addressCity,
      addressDistrict: addressDistrict ?? state.addressDistrict,
      addressState: addressState ?? state.addressState,
      addressPincode: addressPincode ?? state.addressPincode,
      addressLandmark: addressLandmark ?? state.addressLandmark,
      // Preserve others
      primaryMobile: state.primaryMobile,
      alternateMobile: state.alternateMobile,
      whatsappNumber: state.whatsappNumber,
      emailAddress: state.emailAddress,
      panNumber: state.panNumber,
      aadhaarNumber: state.aadhaarNumber,
      voterId: state.voterId,
      passportNumber: state.passportNumber,
      panCardUrl: state.panCardUrl,
      aadhaarCardUrl: state.aadhaarCardUrl,
      selfieUrl: state.selfieUrl,
      bankName: state.bankName,
      accountHolderName: state.accountHolderName,
      accountNumber: state.accountNumber,
      ifscCode: state.ifscCode,
      branchNameLocation: state.branchNameLocation,
      nomineeName: state.nomineeName,
      nomineeRelationship: state.nomineeRelationship,
      nomineeDob: state.nomineeDob,
      nomineeContact: state.nomineeContact,
      nomineeAddress: state.nomineeAddress,
      investmentAmount: state.investmentAmount,
      declarationPlace: state.declarationPlace,
      declarationDate: state.declarationDate,
      isConfirmed: state.isConfirmed,
    );
  }
  
  void updateContactDetails({
    String? primaryMobile,
    String? alternateMobile,
    String? whatsappNumber,
    String? emailAddress,
  }) {
    state = InvestorRequest(
      id: state.id,
      investorId: state.investorId,
      createdAt: state.createdAt,
      updatedAt: state.updatedAt,
      userId: state.userId,
      status: state.status,
      fullName: state.fullName,
      fatherName: state.fatherName,
      motherName: state.motherName,
      dob: state.dob,
      nationality: state.nationality,
      nativePlace: state.nativePlace,
      education: state.education,
      occupation: state.occupation,
      monthlyIncome: state.monthlyIncome,
      gender: state.gender,
      maritalStatus: state.maritalStatus,
      addressDoorNo: state.addressDoorNo,
      addressStreet: state.addressStreet,
      addressCity: state.addressCity,
      addressDistrict: state.addressDistrict,
      addressState: state.addressState,
      addressPincode: state.addressPincode,
      addressLandmark: state.addressLandmark,
      // Update Contact
      primaryMobile: primaryMobile ?? state.primaryMobile,
      alternateMobile: alternateMobile ?? state.alternateMobile,
      whatsappNumber: whatsappNumber ?? state.whatsappNumber,
      emailAddress: emailAddress ?? state.emailAddress,
      // Preserve others
      panNumber: state.panNumber,
      aadhaarNumber: state.aadhaarNumber,
      voterId: state.voterId,
      passportNumber: state.passportNumber,
      panCardUrl: state.panCardUrl,
      aadhaarCardUrl: state.aadhaarCardUrl,
      selfieUrl: state.selfieUrl,
      bankName: state.bankName,
      accountHolderName: state.accountHolderName,
      accountNumber: state.accountNumber,
      ifscCode: state.ifscCode,
      branchNameLocation: state.branchNameLocation,
      nomineeName: state.nomineeName,
      nomineeRelationship: state.nomineeRelationship,
      nomineeDob: state.nomineeDob,
      nomineeContact: state.nomineeContact,
      nomineeAddress: state.nomineeAddress,
      investmentAmount: state.investmentAmount,
      declarationPlace: state.declarationPlace,
      declarationDate: state.declarationDate,
      isConfirmed: state.isConfirmed,
    );
  }

  void updateKycDetails({
    String? panNumber,
    String? aadhaarNumber,
    String? voterId,
    String? passportNumber,
    String? panCardUrl,
    String? aadhaarCardUrl,
    String? selfieUrl,
  }) {
    state = InvestorRequest(
      id: state.id,
      investorId: state.investorId,
      createdAt: state.createdAt,
      updatedAt: state.updatedAt,
      userId: state.userId,
      status: state.status,
      fullName: state.fullName,
      fatherName: state.fatherName,
      motherName: state.motherName,
      dob: state.dob,
      nationality: state.nationality,
      nativePlace: state.nativePlace,
      education: state.education,
      occupation: state.occupation,
      monthlyIncome: state.monthlyIncome,
      gender: state.gender,
      maritalStatus: state.maritalStatus,
      addressDoorNo: state.addressDoorNo,
      addressStreet: state.addressStreet,
      addressCity: state.addressCity,
      addressDistrict: state.addressDistrict,
      addressState: state.addressState,
      addressPincode: state.addressPincode,
      addressLandmark: state.addressLandmark,
      primaryMobile: state.primaryMobile,
      alternateMobile: state.alternateMobile,
      whatsappNumber: state.whatsappNumber,
      emailAddress: state.emailAddress,
      // Update KYC
      panNumber: panNumber ?? state.panNumber,
      aadhaarNumber: aadhaarNumber ?? state.aadhaarNumber,
      voterId: voterId ?? state.voterId,
      passportNumber: passportNumber ?? state.passportNumber,
      panCardUrl: panCardUrl ?? state.panCardUrl,
      aadhaarCardUrl: aadhaarCardUrl ?? state.aadhaarCardUrl,
      selfieUrl: selfieUrl ?? state.selfieUrl,
      // Preserve others
      bankName: state.bankName,
      accountHolderName: state.accountHolderName,
      accountNumber: state.accountNumber,
      ifscCode: state.ifscCode,
      branchNameLocation: state.branchNameLocation,
      nomineeName: state.nomineeName,
      nomineeRelationship: state.nomineeRelationship,
      nomineeDob: state.nomineeDob,
      nomineeContact: state.nomineeContact,
      nomineeAddress: state.nomineeAddress,
      investmentAmount: state.investmentAmount,
      declarationPlace: state.declarationPlace,
      declarationDate: state.declarationDate,
      isConfirmed: state.isConfirmed,
    );
  }

  void updateFinancialDetails({
    String? bankName,
    String? accountHolderName,
    String? accountNumber,
    String? ifscCode,
    String? branchNameLocation,
    String? nomineeName,
    String? nomineeRelationship,
    DateTime? nomineeDob,
    String? nomineeContact,
    String? nomineeAddress,
  }) {
    state = InvestorRequest(
      id: state.id,
      investorId: state.investorId,
      createdAt: state.createdAt,
      updatedAt: state.updatedAt,
      userId: state.userId,
      status: state.status,
      fullName: state.fullName,
      fatherName: state.fatherName,
      motherName: state.motherName,
      dob: state.dob,
      nationality: state.nationality,
      nativePlace: state.nativePlace,
      education: state.education,
      occupation: state.occupation,
      monthlyIncome: state.monthlyIncome,
      gender: state.gender,
      maritalStatus: state.maritalStatus,
      addressDoorNo: state.addressDoorNo,
      addressStreet: state.addressStreet,
      addressCity: state.addressCity,
      addressDistrict: state.addressDistrict,
      addressState: state.addressState,
      addressPincode: state.addressPincode,
      addressLandmark: state.addressLandmark,
      primaryMobile: state.primaryMobile,
      alternateMobile: state.alternateMobile,
      whatsappNumber: state.whatsappNumber,
      emailAddress: state.emailAddress,
      panNumber: state.panNumber,
      aadhaarNumber: state.aadhaarNumber,
      voterId: state.voterId,
      passportNumber: state.passportNumber,
      panCardUrl: state.panCardUrl,
      aadhaarCardUrl: state.aadhaarCardUrl,
      selfieUrl: state.selfieUrl,
      // Update Financials
      bankName: bankName ?? state.bankName,
      accountHolderName: accountHolderName ?? state.accountHolderName,
      accountNumber: accountNumber ?? state.accountNumber,
      ifscCode: ifscCode ?? state.ifscCode,
      branchNameLocation: branchNameLocation ?? state.branchNameLocation,
      nomineeName: nomineeName ?? state.nomineeName,
      nomineeRelationship: nomineeRelationship ?? state.nomineeRelationship,
      nomineeDob: nomineeDob ?? state.nomineeDob,
      nomineeContact: nomineeContact ?? state.nomineeContact,
      nomineeAddress: nomineeAddress ?? state.nomineeAddress,
      // Preserve others
      investmentAmount: state.investmentAmount,
      declarationPlace: state.declarationPlace,
      declarationDate: state.declarationDate,
      isConfirmed: state.isConfirmed,
    );
  }

  void updateInvestmentDetails({String? investmentAmount, String? planName, int? selectedTenure, double? maturityBonusPercentage}) {
    state = InvestorRequest(
      id: state.id,
      investorId: state.investorId,
      createdAt: state.createdAt,
      updatedAt: state.updatedAt,
      userId: state.userId,
      status: state.status,
      fullName: state.fullName,
      fatherName: state.fatherName,
      motherName: state.motherName,
      dob: state.dob,
      nationality: state.nationality,
      nativePlace: state.nativePlace,
      education: state.education,
      occupation: state.occupation,
      monthlyIncome: state.monthlyIncome,
      gender: state.gender,
      maritalStatus: state.maritalStatus,
      addressDoorNo: state.addressDoorNo,
      addressStreet: state.addressStreet,
      addressCity: state.addressCity,
      addressDistrict: state.addressDistrict,
      addressState: state.addressState,
      addressPincode: state.addressPincode,
      addressLandmark: state.addressLandmark,
      primaryMobile: state.primaryMobile,
      alternateMobile: state.alternateMobile,
      whatsappNumber: state.whatsappNumber,
      emailAddress: state.emailAddress,
      panNumber: state.panNumber,
      aadhaarNumber: state.aadhaarNumber,
      voterId: state.voterId,
      passportNumber: state.passportNumber,
      panCardUrl: state.panCardUrl,
      aadhaarCardUrl: state.aadhaarCardUrl,
      selfieUrl: state.selfieUrl,
      bankName: state.bankName,
      accountHolderName: state.accountHolderName,
      accountNumber: state.accountNumber,
      ifscCode: state.ifscCode,
      branchNameLocation: state.branchNameLocation,
      nomineeName: state.nomineeName,
      nomineeRelationship: state.nomineeRelationship,
      nomineeDob: state.nomineeDob,
      nomineeContact: state.nomineeContact,
      nomineeAddress: state.nomineeAddress,
      // Update Investment
      investmentAmount: investmentAmount ?? state.investmentAmount,
      planName: planName ?? state.planName,
      selectedTenure: selectedTenure ?? state.selectedTenure,
      maturityBonusPercentage: maturityBonusPercentage ?? state.maturityBonusPercentage,
      // Preserve others
      declarationPlace: state.declarationPlace,
      declarationDate: state.declarationDate,
      isConfirmed: state.isConfirmed,
    );
  }

  void updateDeclaration({
    String? declarationPlace,
    DateTime? declarationDate,
    bool? isConfirmed,
  }) {
    state = InvestorRequest(
      id: state.id,
      investorId: state.investorId,
      createdAt: state.createdAt,
      updatedAt: state.updatedAt,
      userId: state.userId,
      status: state.status,
      fullName: state.fullName,
      fatherName: state.fatherName,
      motherName: state.motherName,
      dob: state.dob,
      nationality: state.nationality,
      nativePlace: state.nativePlace,
      education: state.education,
      occupation: state.occupation,
      monthlyIncome: state.monthlyIncome,
      gender: state.gender,
      maritalStatus: state.maritalStatus,
      addressDoorNo: state.addressDoorNo,
      addressStreet: state.addressStreet,
      addressCity: state.addressCity,
      addressDistrict: state.addressDistrict,
      addressState: state.addressState,
      addressPincode: state.addressPincode,
      addressLandmark: state.addressLandmark,
      primaryMobile: state.primaryMobile,
      alternateMobile: state.alternateMobile,
      whatsappNumber: state.whatsappNumber,
      emailAddress: state.emailAddress,
      panNumber: state.panNumber,
      aadhaarNumber: state.aadhaarNumber,
      voterId: state.voterId,
      passportNumber: state.passportNumber,
      panCardUrl: state.panCardUrl,
      aadhaarCardUrl: state.aadhaarCardUrl,
      selfieUrl: state.selfieUrl,
      bankName: state.bankName,
      accountHolderName: state.accountHolderName,
      accountNumber: state.accountNumber,
      ifscCode: state.ifscCode,
      branchNameLocation: state.branchNameLocation,
      nomineeName: state.nomineeName,
      nomineeRelationship: state.nomineeRelationship,
      nomineeDob: state.nomineeDob,
      nomineeContact: state.nomineeContact,
      nomineeAddress: state.nomineeAddress,
      investmentAmount: state.investmentAmount,
      // Update Declaration
      declarationPlace: declarationPlace ?? state.declarationPlace,
      declarationDate: declarationDate ?? state.declarationDate,
      isConfirmed: isConfirmed ?? state.isConfirmed,
    );
  }

  Future<void> submitForm(WidgetRef ref) async {
    if (state.id != null && state.id!.isNotEmpty) {
      // Explicitly set status to Pending for resubmission
      final resubmissionState = InvestorRequest(
         id: state.id,
         investorId: state.investorId,
         createdAt: state.createdAt,
         updatedAt: DateTime.now(), // Fixed: Pass DateTime object, not String
         userId: state.userId,
         status: 'Pending', // RESET STATUS
         fullName: state.fullName,
         fatherName: state.fatherName,
         motherName: state.motherName,
         dob: state.dob,
         nationality: state.nationality,
         nativePlace: state.nativePlace,
         education: state.education,
         occupation: state.occupation,
         monthlyIncome: state.monthlyIncome,
         gender: state.gender,
         maritalStatus: state.maritalStatus,
         addressDoorNo: state.addressDoorNo,
         addressStreet: state.addressStreet,
         addressCity: state.addressCity,
         addressDistrict: state.addressDistrict,
         addressState: state.addressState,
         addressPincode: state.addressPincode,
         addressLandmark: state.addressLandmark,
         primaryMobile: state.primaryMobile,
         alternateMobile: state.alternateMobile,
         whatsappNumber: state.whatsappNumber,
         emailAddress: state.emailAddress,
         panNumber: state.panNumber,
         aadhaarNumber: state.aadhaarNumber,
         voterId: state.voterId,
         passportNumber: state.passportNumber,
         panCardUrl: state.panCardUrl,
         aadhaarCardUrl: state.aadhaarCardUrl,
         selfieUrl: state.selfieUrl,
         bankName: state.bankName,
         accountHolderName: state.accountHolderName,
         accountNumber: state.accountNumber,
         ifscCode: state.ifscCode,
         branchNameLocation: state.branchNameLocation,
         nomineeName: state.nomineeName,
         nomineeRelationship: state.nomineeRelationship,
         nomineeDob: state.nomineeDob,
         nomineeContact: state.nomineeContact,
         nomineeAddress: state.nomineeAddress,
         investmentAmount: state.investmentAmount,
         planName: state.planName, // Ensure Plan Name is preserved
         declarationPlace: state.declarationPlace,
         declarationDate: state.declarationDate,
         isConfirmed: state.isConfirmed,
      );

      await ref.read(investorRepositoryProvider).updateRequest(resubmissionState);
      // We need to import request_details_screen.dart or move the provider to a shared location.
      // However, since we can't easily move it right now without refactoring, 
      // we can use the fact that we are in the same package.
      // But wait, requestDetailsProvider is in request_details_screen.dart which imports this file.
      // Circular dependency risk if we import it here.
      
      // Better approach: The caller of submitForm (OnboardingScreen) should handle navigation and invalidation?
      // Or we can just refresh the list and let the user navigate back.
      // But the user is redirected to dashboard.
      // If they click on the request again, it should reload if we invalidate the list?
      // No, requestDetailsProvider caches by ID.
      
      // Let's look at where requestDetailsProvider is defined.
      // It's in request_details_screen.dart.
      
      // We can't import request_details_screen.dart here because it imports onboarding_provider.dart.
      // We should move requestDetailsProvider to a separate file or repository provider file.
      
      // For now, let's just rely on the fact that when we go back to dashboard and click the item again,
      // if we invalidate the *list*, does it invalidate the *details*? No.
      
      // The user says "open the updated request shows old data".
      // This means they go Dashboard -> Details (Old) -> Edit -> Submit -> Dashboard -> Details (Old).
      
      // We need to invalidate the cache for that specific ID.
      // Since we can't import the provider here, we will do it in the OnboardingScreen after submit.
    } else {
      await ref.read(investorRepositoryProvider).createRequest(state);
    }
    // Refresh the dashboard list
    ref.refresh(userRequestsProvider);
  }

  Future<void> saveAsDraft(WidgetRef ref) async {
    if (_isFormEmpty()) {
      throw Exception('Cannot save empty draft. Please fill at least one field.');
    }

    final draftState = state = InvestorRequest(
      id: state.id,
      investorId: state.investorId,
      createdAt: state.createdAt,
      updatedAt: state.updatedAt,
      userId: state.userId,
      status: 'Draft', // Set status to Draft
      fullName: state.fullName,
      fatherName: state.fatherName,
      motherName: state.motherName,
      dob: state.dob,
      nationality: state.nationality,
      nativePlace: state.nativePlace,
      education: state.education,
      occupation: state.occupation,
      monthlyIncome: state.monthlyIncome,
      gender: state.gender,
      maritalStatus: state.maritalStatus,
      addressDoorNo: state.addressDoorNo,
      addressStreet: state.addressStreet,
      addressCity: state.addressCity,
      addressDistrict: state.addressDistrict,
      addressState: state.addressState,
      addressPincode: state.addressPincode,
      addressLandmark: state.addressLandmark,
      primaryMobile: state.primaryMobile,
      alternateMobile: state.alternateMobile,
      whatsappNumber: state.whatsappNumber,
      emailAddress: state.emailAddress,
      panNumber: state.panNumber,
      aadhaarNumber: state.aadhaarNumber,
      voterId: state.voterId,
      passportNumber: state.passportNumber,
      panCardUrl: state.panCardUrl,
      aadhaarCardUrl: state.aadhaarCardUrl,
      selfieUrl: state.selfieUrl,
      bankName: state.bankName,
      accountHolderName: state.accountHolderName,
      accountNumber: state.accountNumber,
      ifscCode: state.ifscCode,
      branchNameLocation: state.branchNameLocation,
      nomineeName: state.nomineeName,
      nomineeRelationship: state.nomineeRelationship,
      nomineeDob: state.nomineeDob,
      nomineeContact: state.nomineeContact,
      nomineeAddress: state.nomineeAddress,
      investmentAmount: state.investmentAmount,
      planName: state.planName ?? 'Draft', // Default to Draft if not selected
      declarationPlace: state.declarationPlace,
      declarationDate: state.declarationDate,
      isConfirmed: state.isConfirmed,
    );

    if (state.id != null && state.id!.isNotEmpty) {
      await ref.read(investorRepositoryProvider).updateRequest(draftState);
    } else {
      await ref.read(investorRepositoryProvider).createRequest(draftState);
    }
    ref.refresh(userRequestsProvider);
  }

  bool _isFormEmpty() {
    return (state.fullName ?? '').isEmpty &&
        (state.fatherName ?? '').isEmpty &&
        (state.motherName ?? '').isEmpty &&
        state.dob == null &&
        (state.nationality ?? '').isEmpty &&
        (state.nativePlace ?? '').isEmpty &&
        (state.education ?? '').isEmpty &&
        (state.occupation ?? '').isEmpty &&
        (state.monthlyIncome ?? '').isEmpty &&
        (state.gender ?? '').isEmpty &&
        (state.maritalStatus ?? '').isEmpty &&
        (state.addressDoorNo ?? '').isEmpty &&
        (state.addressStreet ?? '').isEmpty &&
        (state.addressCity ?? '').isEmpty &&
        (state.addressDistrict ?? '').isEmpty &&
        (state.addressState ?? '').isEmpty &&
        (state.addressPincode ?? '').isEmpty &&
        (state.primaryMobile ?? '').isEmpty &&
        (state.alternateMobile ?? '').isEmpty &&
        (state.whatsappNumber ?? '').isEmpty &&
        (state.emailAddress ?? '').isEmpty &&
        (state.panNumber ?? '').isEmpty &&
        (state.aadhaarNumber ?? '').isEmpty &&
        (state.voterId ?? '').isEmpty &&
        (state.passportNumber ?? '').isEmpty &&
        (state.panCardUrl ?? '').isEmpty &&
        (state.aadhaarCardUrl ?? '').isEmpty &&
        (state.selfieUrl ?? '').isEmpty &&
        (state.bankName ?? '').isEmpty &&
        (state.accountHolderName ?? '').isEmpty &&
        (state.accountNumber ?? '').isEmpty &&
        (state.ifscCode ?? '').isEmpty &&
        (state.branchNameLocation ?? '').isEmpty &&
        (state.nomineeName ?? '').isEmpty &&
        (state.nomineeRelationship ?? '').isEmpty &&
        state.nomineeDob == null &&
        (state.nomineeContact ?? '').isEmpty &&
        (state.nomineeAddress ?? '').isEmpty &&
        (state.investmentAmount ?? '').isEmpty &&
        (state.declarationPlace ?? '').isEmpty;
  }

  void resetState() {
    final user = ref.read(currentUserProvider);
    state = InvestorRequest(userId: user?.id ?? '');
  }

  void setRequest(InvestorRequest request) {
    state = request;
  }
}
