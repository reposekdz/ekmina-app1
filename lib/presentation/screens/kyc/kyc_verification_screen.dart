import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/services/kyc_service.dart';
import '../../../data/remote/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class KYCVerificationScreen extends StatefulWidget {
  const KYCVerificationScreen({super.key});

  @override
  State<KYCVerificationScreen> createState() => _KYCVerificationScreenState();
}

class _KYCVerificationScreenState extends State<KYCVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _documentNumberController = TextEditingController();
  final _kycService = KYCService(ApiClient());
  
  String _selectedDocumentType = 'NATIONAL_ID';
  File? _documentImage;
  File? _selfieImage;
  bool _isLoading = false;
  int _currentStep = 0;

  final List<String> _documentTypes = [
    'NATIONAL_ID',
    'PASSPORT',
    'DRIVING_LICENSE',
  ];

  Future<void> _captureDocument() async {
    try {
      final image = await _kycService.captureDocument();
      if (image != null) {
        setState(() => _documentImage = File(image.path));
      }
    } catch (e) {
      _showError('Ntibyashobotse gufata ifoto: ${e.toString()}');
    }
  }

  Future<void> _captureSelfie() async {
    try {
      final image = await _kycService.captureSelfie();
      if (image != null) {
        setState(() => _selfieImage = File(image.path));
      }
    } catch (e) {
      _showError('Ntibyashobotse gufata selfie: ${e.toString()}');
    }
  }

  Future<void> _submitKYC() async {
    if (!_formKey.currentState!.validate()) return;
    if (_documentImage == null) {
      _showError('Fata ifoto y\'irangamuntu');
      return;
    }
    if (_selfieImage == null) {
      _showError('Fata selfie yawe');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _kycService.submitKYC(
        documentType: _selectedDocumentType,
        documentNumber: _documentNumberController.text.trim(),
        documentImage: _documentImage!,
        selfieImage: _selfieImage!,
        metadata: {
          'submittedAt': DateTime.now().toIso8601String(),
          'deviceInfo': 'Mobile App',
        },
      );

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
              child: const Icon(LucideIcons.check, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            const Text(
              'Byagenze neza!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              'Umwirondoro wawe woherejwe neza. Tugiye kuwusuzuma, turakumenyesha iyo byarangiye.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
                child: const Text('Siga'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message), 
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emeza Umwirondoro', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppTheme.primaryBlue),
        ),
        child: Stepper(
          type: StepperType.horizontal,
          currentStep: _currentStep,
          elevation: 0,
          onStepContinue: () {
            if (_currentStep < 2) {
              setState(() => _currentStep++);
            } else {
              _submitKYC();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            }
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 32.0),
              child: Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: _currentStep == 2 ? 'Ohereza' : 'Komeza',
                      onPressed: details.onStepContinue!,
                      isLoading: _isLoading,
                    ),
                  ),
                  if (_currentStep > 0) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomButton(
                        text: 'Subira inyuma',
                        onPressed: details.onStepCancel!,
                        isOutlined: true,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: [
            Step(
              title: const Text('Irangamuntu', style: TextStyle(fontSize: 11)),
              content: _buildStepOne(),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text('Ifoto ID', style: TextStyle(fontSize: 11)),
              content: _buildStepTwo(),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            ),
            Step(
              title: const Text('Selfie', style: TextStyle(fontSize: 11)),
              content: _buildStepThree(),
              isActive: _currentStep >= 2,
              state: StepState.indexed,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepOne() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hitamo Ubwoko bw\'Irangamuntu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          DropdownButtonFormField<String>(
            value: _selectedDocumentType,
            decoration: const InputDecoration(
              labelText: 'Ubwoko bw\'irangamuntu',
              prefixIcon: Icon(LucideIcons.fileText),
            ),
            items: _documentTypes.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(_kycService.getDocumentTypeText(type, 'rw')),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedDocumentType = value!;
                _documentNumberController.clear();
              });
            },
          ),
          const SizedBox(height: 24),
          CustomTextField(
            label: 'Nomero y\'irangamuntu',
            controller: _documentNumberController,
            hint: _kycService.getDocumentNumberHint(_selectedDocumentType, 'rw'),
            prefixIcon: LucideIcons.hash,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Shyiramo nomero y\'irangamuntu';
              return null;
            },
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildStepTwo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Fata Ifoto y\'Irangamuntu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text('Menya ko amazina n\'ifoto bishobora gusomwa neza.', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),
        if (_documentImage != null)
          Container(
            height: 200,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(image: FileImage(_documentImage!), fit: BoxFit.cover),
              border: Border.all(color: AppTheme.primaryBlue, width: 2),
            ),
          ).animate().scale(),
        CustomCard(
          onTap: _captureDocument,
          padding: const EdgeInsets.all(32),
          color: AppTheme.primaryBlue.withOpacity(0.05),
          child: Column(
            children: [
              const Icon(LucideIcons.camera, size: 48, color: AppTheme.primaryBlue),
              const SizedBox(height: 16),
              Text(
                _documentImage == null ? 'Fata Ifoto y\'Ibere' : 'Ongera Ufate Ifoto',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildStepThree() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Fata Selfie Yawe', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text('Reba kamera neza kandi ukureho amadarubindi cyangwa ingofero.', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),
        if (_selfieImage != null)
          Container(
            height: 240,
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: DecorationImage(image: FileImage(_selfieImage!), fit: BoxFit.cover),
              border: Border.all(color: Colors.green, width: 3),
            ),
          ).animate().scale(),
        CustomCard(
          onTap: _captureSelfie,
          padding: const EdgeInsets.all(32),
          color: Colors.green.withOpacity(0.05),
          child: Column(
            children: [
              const Icon(LucideIcons.user, size: 48, color: Colors.green),
              const SizedBox(height: 16),
              Text(
                _selfieImage == null ? 'Fata Selfie' : 'Ongera Ufate Selfie',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn();
  }

  @override
  void dispose() {
    _documentNumberController.dispose();
    super.dispose();
  }
}
