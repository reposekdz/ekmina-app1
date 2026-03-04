import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();
  final Logger _logger = Logger();

  Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics;
    } catch (e) {
      _logger.e('Error checking biometrics: $e');
      return false;
    }
  }

  Future<bool> isDeviceSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (e) {
      _logger.e('Error checking device support: $e');
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      _logger.e('Error getting available biometrics: $e');
      return [];
    }
  }

  Future<bool> authenticate({
    required String localizedReason,
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      final canAuth = await canCheckBiometrics();
      if (!canAuth) return false;

      return await _auth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      _logger.e('Biometric authentication error: $e');
      return false;
    }
  }

  Future<bool> authenticateForTransaction(double amount) async {
    return await authenticate(
      localizedReason: 'Emeza ibikorwa bya RWF ${amount.toStringAsFixed(0)}',
      useErrorDialogs: true,
      stickyAuth: true,
    );
  }

  Future<bool> authenticateForLogin() async {
    return await authenticate(
      localizedReason: 'Injira muri E-Kimina ukoresheje intoki cyangwa isura',
      useErrorDialogs: true,
      stickyAuth: false,
    );
  }
}
