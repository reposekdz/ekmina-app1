import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../data/remote/api_client.dart';

class KYCService {
  final ApiClient _apiClient;
  final ImagePicker _imagePicker = ImagePicker();

  KYCService(this._apiClient);

  Future<Map<String, dynamic>> submitKYC({
    required String documentType,
    required String documentNumber,
    required File documentImage,
    required File selfieImage,
    Map<String, dynamic>? metadata,
  }) async {
    // Validate document number format
    if (!_validateDocumentNumber(documentType, documentNumber)) {
      throw Exception('Nomero y\'irangamuntu ntabwo ari yo');
    }

    // Convert images to base64
    final docBase64 = base64Encode(await documentImage.readAsBytes());
    final selfieBase64 = base64Encode(await selfieImage.readAsBytes());

    return await _apiClient.submitKYC(
      documentType,
      documentNumber,
      docBase64,
      selfieBase64,
      metadata: metadata,
    );
  }

  Future<Map<String, dynamic>> getKYCStatus() async {
    return await _apiClient.getKYCStatus();
  }

  Future<XFile?> captureDocument() async {
    return await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1080,
    );
  }

  Future<XFile?> captureSelfie() async {
    return await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1080,
      maxHeight: 1920,
      preferredCameraDevice: CameraDevice.front,
    );
  }

  Future<XFile?> pickImageFromGallery() async {
    return await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
  }

  bool _validateDocumentNumber(String type, String number) {
    switch (type) {
      case 'NATIONAL_ID':
        // Rwanda National ID: 16 digits
        return RegExp(r'^\d{16}$').hasMatch(number);
      case 'PASSPORT':
        // Passport: 7-9 alphanumeric characters
        return RegExp(r'^[A-Z0-9]{7,9}$').hasMatch(number);
      case 'DRIVING_LICENSE':
        // Driving License: varies, but typically alphanumeric
        return RegExp(r'^[A-Z0-9]{6,12}$').hasMatch(number);
      default:
        return false;
    }
  }

  String getDocumentTypeText(String type, String language) {
    final texts = {
      'NATIONAL_ID': {
        'rw': 'Indangamuntu',
        'en': 'National ID',
        'fr': 'Carte d\'identité nationale'
      },
      'PASSPORT': {
        'rw': 'Pasiporo',
        'en': 'Passport',
        'fr': 'Passeport'
      },
      'DRIVING_LICENSE': {
        'rw': 'Uruhushya rwo gutwara',
        'en': 'Driving License',
        'fr': 'Permis de conduire'
      },
    };
    return texts[type]?[language] ?? type;
  }

  String getKYCStatusText(String status, String language) {
    final texts = {
      'PENDING': {
        'rw': 'Birategerezwa',
        'en': 'Pending Review',
        'fr': 'En attente'
      },
      'VERIFIED': {
        'rw': 'Byemejwe',
        'en': 'Verified',
        'fr': 'Vérifié'
      },
      'REJECTED': {
        'rw': 'Byanze',
        'en': 'Rejected',
        'fr': 'Rejeté'
      },
    };
    return texts[status]?[language] ?? status;
  }

  String getKYCStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return '#FF9800';
      case 'VERIFIED':
        return '#4CAF50';
      case 'REJECTED':
        return '#F44336';
      default:
        return '#9E9E9E';
    }
  }

  String getDocumentNumberHint(String type, String language) {
    final hints = {
      'NATIONAL_ID': {
        'rw': 'Imibare 16 (1 XXXX XXXX XXXX XXX)',
        'en': '16 digits (1 XXXX XXXX XXXX XXX)',
        'fr': '16 chiffres (1 XXXX XXXX XXXX XXX)'
      },
      'PASSPORT': {
        'rw': 'Inyuguti n\'imibare 7-9',
        'en': '7-9 alphanumeric characters',
        'fr': '7-9 caractères alphanumériques'
      },
      'DRIVING_LICENSE': {
        'rw': 'Inyuguti n\'imibare 6-12',
        'en': '6-12 alphanumeric characters',
        'fr': '6-12 caractères alphanumériques'
      },
    };
    return hints[type]?[language] ?? '';
  }

  bool isKYCRequired(double amount) {
    return amount >= 500000; // 500,000 RWF threshold
  }

  bool shouldShowKYCWarning(double amount) {
    return amount >= 100000; // 100,000 RWF warning threshold
  }

  String getKYCRequirementMessage(String language) {
    final messages = {
      'rw': 'Amafaranga menshi asaba kwemeza umwirondoro (KYC)',
      'en': 'Large transactions require KYC verification',
      'fr': 'Les transactions importantes nécessitent une vérification KYC'
    };
    return messages[language] ?? messages['en']!;
  }
}
