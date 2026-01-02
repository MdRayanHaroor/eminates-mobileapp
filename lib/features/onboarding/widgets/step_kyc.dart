import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:investorapp_eminates/features/onboarding/providers/onboarding_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:investorapp_eminates/services/storage_service.dart';

class StepKyc extends ConsumerStatefulWidget {
  const StepKyc({super.key});

  @override
  ConsumerState<StepKyc> createState() => _StepKycState();
}

class _StepKycState extends ConsumerState<StepKyc> {
  final _panController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _voterController = TextEditingController();
  final _passportController = TextEditingController();

  bool _isUploadingPan = false;
  bool _isUploadingAadhaar = false;
  bool _isUploadingSelfie = false;

  final ImagePicker _picker = ImagePicker();

  // Helper for consistent dark mode friendly decoration
  InputDecoration _getInputDecoration(String label, {String? hintText}) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
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
    _panController.text = state.panNumber ?? '';
    _aadhaarController.text = state.aadhaarNumber ?? '';
    _voterController.text = state.voterId ?? '';
    _passportController.text = state.passportNumber ?? '';

    _panController.addListener(_updateState);
    _aadhaarController.addListener(_updateState);
    _voterController.addListener(_updateState);
    _passportController.addListener(_updateState);
  }

  void _updateState() {
    final currentRequest = ref.read(currentEditingRequestProvider);
    ref.read(onboardingFormProvider(currentRequest).notifier).updateKycDetails(
      panNumber: _panController.text,
      aadhaarNumber: _aadhaarController.text,
      voterId: _voterController.text,
      passportNumber: _passportController.text,
    );
  }

  Future<void> _pickAndUpload(String docType, {bool useCamera = false}) async {
    try {
      File? file;
      
      if (useCamera) {
         final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
         if (image != null) file = File(image.path);
      } else {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        );
        if (result != null && result.files.single.path != null) {
          file = File(result.files.single.path!);
        }
      }

      if (file == null) return;

      setState(() {
        if (docType == 'pan') _isUploadingPan = true;
        if (docType == 'aadhaar') _isUploadingAadhaar = true;
        if (docType == 'selfie') _isUploadingSelfie = true;
      });

      final currentRequest = ref.read(currentEditingRequestProvider);
      final userId = ref.read(onboardingFormProvider(currentRequest)).userId;
      final path = await ref.read(storageServiceProvider).uploadFile(file, userId, docType);
      
      // Update KYC field based on type  
      switch (docType) {
        case 'pan':
          ref.read(onboardingFormProvider(currentRequest).notifier).updateKycDetails(panCardUrl: path);
          break;
        case 'aadhaar':
          ref.read(onboardingFormProvider(currentRequest).notifier).updateKycDetails(aadhaarCardUrl: path);
          break;
        case 'selfie':
          ref.read(onboardingFormProvider(currentRequest).notifier).updateKycDetails(selfieUrl: path);
          break;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload successful'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          if (docType == 'pan') _isUploadingPan = false;
          if (docType == 'aadhaar') _isUploadingAadhaar = false;
          if (docType == 'selfie') _isUploadingSelfie = false;
        });
      }
    }
  }

  Widget _buildUploadButton({
    required String label,
    required String? currentPath,
    required bool isUploading,
    required VoidCallback onPressed,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: isUploading ? null : onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey.shade50,
            ),
            child: isUploading
                ? const Center(child: CircularProgressIndicator())
                : currentPath != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 40),
                          const SizedBox(height: 8),
                          Text(
                            'File Uploaded',
                            style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Tap to replace',
                             style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, color: Colors.indigo, size: 40),
                          const SizedBox(height: 8),
                          Text(
                            'Click to Upload',
                            style: TextStyle(color: Colors.indigo.shade700),
                          ),
                        ],
                      ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentRequest = ref.watch(currentEditingRequestProvider);
    final state = ref.watch(onboardingFormProvider(currentRequest));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Section E: KYC Details', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          TextFormField(
            controller: _panController,
            decoration: _getInputDecoration('PAN Number *', hintText: 'ABCDE1234F'),
            textCapitalization: TextCapitalization.characters,
            validator: (value) {
              if (value == null || value.isEmpty) return 'PAN is required';
              final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
              if (!panRegex.hasMatch(value)) return 'Invalid PAN Number';
              return null;
            },
            onChanged: (value) {
              final upperValue = value.toUpperCase();
              if (value != upperValue) {
                _panController.value = _panController.value.copyWith(
                  text: upperValue,
                  selection: TextSelection.collapsed(offset: upperValue.length),
                );
              }
              _updateState();
            },
          ),
          const SizedBox(height: 16),
          _buildUploadButton(
            label: 'Upload PAN Card *',
            currentPath: state.panCardUrl,
            isUploading: _isUploadingPan,
            icon: Icons.upload_file,
            onPressed: () => _pickAndUpload('pan'), // Gallery/File
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _aadhaarController,
            decoration: _getInputDecoration('Aadhaar Number *'),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Aadhaar is required';
              if (value.length != 12) return 'Aadhaar must be 12 digits';
              return null;
            },
          ),
           const SizedBox(height: 16),
          _buildUploadButton(
            label: 'Upload Aadhaar Card *',
            currentPath: state.aadhaarCardUrl,
            isUploading: _isUploadingAadhaar,
            icon: Icons.upload_file,
            onPressed: () => _pickAndUpload('aadhaar'), // Gallery/File
          ),
          const SizedBox(height: 16),
          const Text('Verification Selfie *', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildUploadButton(
            label: 'Take a Selfie',
            currentPath: state.selfieUrl,
            isUploading: _isUploadingSelfie,
            icon: Icons.camera_alt,
            onPressed: () => showModalBottomSheet(
              context: context,
              builder: (ctx) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.camera),
                    title: const Text('Camera'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickAndUpload('selfie', useCamera: true);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo),
                    title: const Text('Gallery'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickAndUpload('selfie', useCamera: false);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(controller: _voterController, decoration: _getInputDecoration('Voter ID')),
          const SizedBox(height: 8),
          TextFormField(controller: _passportController, decoration: _getInputDecoration('Passport Number')),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
