import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static const String userBox = 'user_box';
  static const String settingsBox = 'settings_box';
  static const String cacheBox = 'cache_box';
  
  static Future<void> init() async {
    await Hive.openBox(userBox);
    await Hive.openBox(settingsBox);
    await Hive.openBox(cacheBox);
  }
  
  static Box get user => Hive.box(userBox);
  static Box get settings => Hive.box(settingsBox);
  static Box get cache => Hive.box(cacheBox);
  
  static Future<void> saveUser(Map<String, dynamic> userData) async {
    await user.put('current_user', userData);
  }
  
  static Map<String, dynamic>? getUser() {
    return user.get('current_user');
  }
  
  static Future<void> saveToken(String token) async {
    await user.put('auth_token', token);
  }
  
  static String? getToken() {
    return user.get('auth_token');
  }
  
  static Future<void> clearUser() async {
    await user.clear();
  }
  
  static Future<void> saveThemeMode(String mode) async {
    await settings.put('theme_mode', mode);
  }
  
  static String getThemeMode() {
    return settings.get('theme_mode', defaultValue: 'system');
  }
  
  static Future<void> saveLanguage(String languageCode) async {
    await settings.put('language', languageCode);
  }
  
  static String getLanguage() {
    return settings.get('language', defaultValue: 'rw');
  }
  
  static Future<void> saveBiometricEnabled(bool enabled) async {
    await settings.put('biometric_enabled', enabled);
  }
  
  static bool getBiometricEnabled() {
    return settings.get('biometric_enabled', defaultValue: false);
  }
}
