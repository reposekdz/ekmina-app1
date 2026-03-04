import 'package:dio/dio.dart';
import 'dart:math';

class PaymentService {
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000/api', connectTimeout: const Duration(seconds: 30)));

  Future<Map<String, dynamic>> depositMTN(String userId, double amount, String phone) async {
    try {
      final referenceId = _generateReference();
      final response = await _dio.post('/wallet', data: {'userId': userId, 'action': 'deposit', 'amount': amount, 'paymentMethod': 'MTN_MOMO', 'referenceId': referenceId, 'phone': phone});
      
      if (response.statusCode == 200) {
        return {'success': true, 'balance': response.data['balance'], 'referenceId': referenceId, 'message': 'Amafaranga yinjijwe neza'};
      }
      return {'success': false, 'error': 'Ikosa ryabaye'};
    } catch (e) {
      return {'success': false, 'error': 'Ikosa ryo kwinjiza amafaranga'};
    }
  }

  Future<Map<String, dynamic>> depositAirtel(String userId, double amount, String phone) async {
    try {
      final referenceId = _generateReference();
      final response = await _dio.post('/wallet', data: {'userId': userId, 'action': 'deposit', 'amount': amount, 'paymentMethod': 'AIRTEL_MONEY', 'referenceId': referenceId, 'phone': phone});
      
      if (response.statusCode == 200) {
        return {'success': true, 'balance': response.data['balance'], 'referenceId': referenceId, 'message': 'Amafaranga yinjijwe neza'};
      }
      return {'success': false, 'error': 'Ikosa ryabaye'};
    } catch (e) {
      return {'success': false, 'error': 'Ikosa ryo kwinjiza amafaranga'};
    }
  }

  Future<Map<String, dynamic>> withdraw(String userId, double amount, String paymentMethod, String phone) async {
    try {
      final referenceId = _generateReference();
      final response = await _dio.post('/wallet', data: {'userId': userId, 'action': 'withdraw', 'amount': amount, 'paymentMethod': paymentMethod, 'referenceId': referenceId, 'phone': phone});
      
      if (response.statusCode == 200) {
        return {'success': true, 'balance': response.data['balance'], 'referenceId': referenceId, 'message': 'Amafaranga yakuwe neza'};
      }
      return {'success': false, 'error': response.data['error'] ?? 'Ikosa ryabaye'};
    } catch (e) {
      return {'success': false, 'error': 'Ikosa ryo gukura amafaranga'};
    }
  }

  Future<Map<String, dynamic>> getBalance(String userId) async {
    try {
      final response = await _dio.get('/wallet', queryParameters: {'userId': userId});
      if (response.statusCode == 200) {
        return {'success': true, 'balance': response.data['balance'], 'transactions': response.data['transactions']};
      }
      return {'success': false, 'error': 'Ikosa ryabaye'};
    } catch (e) {
      return {'success': false, 'error': 'Ikosa ryo kubona amafaranga'};
    }
  }

  String _generateReference() => 'TXN${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(9999)}';
}
