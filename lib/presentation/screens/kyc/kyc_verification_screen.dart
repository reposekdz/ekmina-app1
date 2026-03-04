import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/kyc_service.dart';
import '../../../data/remote/api_client.dart';

class KYCVerificationScreen extends StatefulWidget {
  const KYCVerificationScreen({Key? key}) : super(key: key);

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
      final XFile? image = await _kycService.captureDocument();
      if (image != null) {
        setState(() => _documentImage = File(image.path));
      }
    } catch (e) {
      _showError('Ntibyashobotse gufata ifoto: ${e.toString()}');
    }
  }

  Future<void> _captureSelfie() async {
    try {
      final XFile? image = await _kycService.captureSelfie();
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
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                SizedBox(width: 12),
                Expanded(child: Text('Byagenze neza!')),
              ],
            ),
            content: const Text(
              'Umwirondoro wawe woherejwe neza. Uzahabwa ubutumwa iyo byemejwe.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
                child: const Text('Siga'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emeza Umwirondoro (KYC)'),
        centerTitle: true,
      ),
      body: Stepper(
        currentStep: _currentStep,
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
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : details.onStepContinue,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(_currentStep == 2 ? 'Ohereza' : 'Komeza'),
                ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Subira inyuma'),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Hitamo Ubwoko bw\'Irangamuntu'),
            content: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedDocumentType,
                    decoration: const InputDecoration(
                      labelText: 'Ubwoko bw\'irangamuntu',
                      border: OutlineInputBorder(),
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
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _documentNumberController,
                    decoration: InputDecoration(
                      labelText: 'Nomero y\'irangamuntu',
                      hintText: _kycService.getDocumentNumberHint(_selectedDocumentType, 'rw'),
                      border: const OutlineInputBorder(),
                    ),
                    inputFormatters: [
                      if (_selectedDocumentType == 'NATIONAL_ID')
                        FilteringTextInputFormatter.digitsOnly,
                      if (_selectedDocumentType == 'NATIONAL_ID')
                        LengthLimitingTextInputFormatter(16),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Shyiramo nomero y\'irangamuntu';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Fata Ifoto y\'Irangamuntu'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_documentImage != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _documentImage!,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.credit_card, size: 48, color: Colors.blue[700]),
                      const SizedBox(height: 8),
                      const Text(
                        'Amabwiriza:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '• Fata ifoto itangaje\n'
                        '• Menya ko amazina aboneka neza\n'
                        '• Koresha umucyo mwiza',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _captureDocument,
                  icon: const Icon(Icons.camera_alt),
                  label: Text(_documentImage == null ? 'Fata Ifoto' : 'Ongera Ufate'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Fata Selfie Yawe'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_selfieImage != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _selfieImage!,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.face, size: 48, color: Colors.green[700]),
                      const SizedBox(height: 8),
                      const Text(
                        'Amabwiriza:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '• Reba kamera neza\n'
                        '• Kuraho ibirimo (eyeglasses, hat)\n'
                        '• Koresha umucyo mwiza\n'
                        '• Ntukoreshe ifoto ya kera',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _captureSelfie,
                  icon: const Icon(Icons.camera_front),
                  label: Text(_selfieImage == null ? 'Fata Selfie' : 'Ongera Ufate'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
            isActive: _currentStep >= 2,
            state: StepState.indexed,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _documentNumberController.dispose();
    super.dispose();
  }
}
