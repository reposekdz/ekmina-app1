import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseUrl = 'https://api.ekimina.rw';
  late final Dio _dio;
  
  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
    ));
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }

  Future<Response> patch(String path, {dynamic data}) async {
    return await _dio.patch(path, data: data);
  }

  Future<Response> delete(String path) async {
    return await _dio.delete(path);
  }
}

class GroupRepository {
  final ApiClient _client;

  GroupRepository(this._client);

  Future<List<dynamic>> getGroups({String? userId, String? province, String? district}) async {
    final response = await _client.get('/api/groups', queryParameters: {
      if (userId != null) 'userId': userId,
      if (province != null) 'province': province,
      if (district != null) 'district': district,
    });
    return response.data['groups'];
  }

  Future<Map<String, dynamic>> createGroup(Map<String, dynamic> data) async {
    final response = await _client.post('/api/groups', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> joinGroup(String userId, String inviteCode) async {
    final response = await _client.post('/api/groups/join', data: {
      'userId': userId,
      'inviteCode': inviteCode,
    });
    return response.data;
  }
}

class TransactionRepository {
  final ApiClient _client;

  TransactionRepository(this._client);

  Future<Map<String, dynamic>> createDeposit(Map<String, dynamic> data) async {
    final response = await _client.post('/api/deposits', data: data);
    return response.data;
  }

  Future<List<dynamic>> getTransactions(String membershipId) async {
    final response = await _client.get('/api/transactions', queryParameters: {
      'membershipId': membershipId,
    });
    return response.data['transactions'];
  }
}

class LoanRepository {
  final ApiClient _client;

  LoanRepository(this._client);

  Future<Map<String, dynamic>> requestLoan(Map<String, dynamic> data) async {
    final response = await _client.post('/api/loans', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> approveLoan(String loanId, String approverId, String action) async {
    final response = await _client.patch('/api/loans', data: {
      'loanId': loanId,
      'approverId': approverId,
      'action': action,
    });
    return response.data;
  }

  Future<List<dynamic>> getLoans(String membershipId) async {
    final response = await _client.get('/api/loans', queryParameters: {
      'membershipId': membershipId,
    });
    return response.data['loans'];
  }
}

class LocationRepository {
  final ApiClient _client;

  LocationRepository(this._client);

  Future<List<String>> getProvinces() async {
    final response = await _client.get('/api/locations', queryParameters: {'type': 'provinces'});
    return List<String>.from(response.data['data']);
  }

  Future<List<String>> getDistricts(String province) async {
    final response = await _client.get('/api/locations', queryParameters: {
      'type': 'districts',
      'province': province,
    });
    return List<String>.from(response.data['data']);
  }

  Future<List<String>> getSectors(String province, String district) async {
    final response = await _client.get('/api/locations', queryParameters: {
      'type': 'sectors',
      'province': province,
      'district': district,
    });
    return List<String>.from(response.data['data']);
  }

  Future<List<String>> getCells(String province, String district, String sector) async {
    final response = await _client.get('/api/locations', queryParameters: {
      'type': 'cells',
      'province': province,
      'district': district,
      'sector': sector,
    });
    return List<String>.from(response.data['data']);
  }

  Future<List<String>> getVillages(String province, String district, String sector, String cell) async {
    final response = await _client.get('/api/locations', queryParameters: {
      'type': 'villages',
      'province': province,
      'district': district,
      'sector': sector,
      'cell': cell,
    });
    return List<String>.from(response.data['data']);
  }
}
