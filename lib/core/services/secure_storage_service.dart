import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:logger/logger.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  final Logger _logger = Logger();

  // Keys
  static const String _keyAuthToken = 'auth_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserPhone = 'user_phone';
  static const String _keyWalletPin = 'wallet_pin';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyEncryptionKey = 'encryption_key';

  // Auth tokens
  Future<void> saveAuthToken(String token) async {
    await _storage.write(key: _keyAuthToken, value: token);
  }

  Future<String?> getAuthToken() async {
    return await _storage.read(key: _keyAuthToken);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _keyRefreshToken, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _keyRefreshToken);
  }

  // User data
  Future<void> saveUserId(String userId) async {
    await _storage.write(key: _keyUserId, value: userId);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: _keyUserId);
  }

  Future<void> saveUserPhone(String phone) async {
    await _storage.write(key: _keyUserPhone, value: phone);
  }

  Future<String?> getUserPhone() async {
    return await _storage.read(key: _keyUserPhone);
  }

  // Wallet PIN (encrypted)
  Future<void> saveWalletPin(String pin) async {
    final encryptedPin = _encryptData(pin);
    await _storage.write(key: _keyWalletPin, value: encryptedPin);
  }

  Future<String?> getWalletPin() async {
    final encryptedPin = await _storage.read(key: _keyWalletPin);
    if (encryptedPin == null) return null;
    return _decryptData(encryptedPin);
  }

  Future<bool> verifyWalletPin(String pin) async {
    final storedPin = await getWalletPin();
    return storedPin == pin;
  }

  // Biometric settings
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _keyBiometricEnabled, value: enabled.toString());
  }

  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: _keyBiometricEnabled);
    return value == 'true';
  }

  // Clear all data
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  Future<void> clearAuthData() async {
    await _storage.delete(key: _keyAuthToken);
    await _storage.delete(key: _keyRefreshToken);
  }

  // Encryption helpers
  String _encryptData(String data) {
    try {
      final key = encrypt.Key.fromLength(32);
      final iv = encrypt.IV.fromLength(16);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      return encrypter.encrypt(data, iv: iv).base64;
    } catch (e) {
      _logger.e('Encryption error: $e');
      return data;
    }
  }

  String _decryptData(String encryptedData) {
    try {
      final key = encrypt.Key.fromLength(32);
      final iv = encrypt.IV.fromLength(16);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      return encrypter.decrypt64(encryptedData, iv: iv);
    } catch (e) {
      _logger.e('Decryption error: $e');
      return encryptedData;
    }
  }
}
