import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

class AuthService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(milliseconds: AppConfig.connectionTimeout),
    receiveTimeout: const Duration(milliseconds: AppConfig.receiveTimeout),
  ));
  
  final _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      final response = await _dio.post('/api/auth?action=login', data: {'phone': phone, 'password': password});
      if (response.statusCode == 200) {
        await _storage.write(key: 'auth_token', value: response.data['token']);
        await _storage.write(key: 'user_id', value: response.data['user']['id']);
        return {'success': true, 'user': response.data['user']};
      }
      return {'success': false, 'error': 'Ikosa ryabaye'};
    } on DioException catch (e) {
      return {'success': false, 'error': e.response?.statusCode == 401 ? 'Telefoni cyangwa ijambo ryibanga ntibikora' : 'Ikosa ryo kwinjira'};
    }
  }

  Future<Map<String, dynamic>> register({required String name, required String phone, required String nid, required String password, required String province, required String district, required String sector, required String cell, required String village, String language = 'rw'}) async {
    try {
      final response = await _dio.post('/api/auth?action=register', data: {'name': name, 'phone': phone, 'nid': nid, 'password': password, 'province': province, 'district': district, 'sector': sector, 'cell': cell, 'village': village, 'language': language});
      if (response.statusCode == 201) {
        await _storage.write(key: 'auth_token', value: response.data['token']);
        await _storage.write(key: 'user_id', value: response.data['user']['id']);
        return {'success': true, 'user': response.data['user']};
      }
      return {'success': false, 'error': 'Ikosa ryabaye'};
    } on DioException catch (e) {
      return {'success': false, 'error': e.response?.statusCode == 409 ? 'Telefoni cyangwa indangamuntu zirasanzwe' : 'Ikosa ryo kwiyandikisha'};
    }
  }

  Future<String?> getToken() => _storage.read(key: 'auth_token');
  Future<String?> getUserId() => _storage.read(key: 'user_id');
  Future<bool> isLoggedIn() async => await getToken() != null;
  Future<void> logout() => _storage.deleteAll();
}
