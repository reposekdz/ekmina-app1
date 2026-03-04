import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../core/config/app_config.dart';
import '../../core/services/secure_storage_service.dart';
import '../../core/utils/error_handler.dart';
import '../local/hive_service.dart';

final apiClientProvider = Provider((ref) => ApiClient());

class ApiClient {
  late final Dio _dio;
  final Logger _logger = Logger();
  final SecureStorageService _storage = SecureStorageService();
  
  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(milliseconds: AppConfig.connectionTimeout),
        receiveTimeout: const Duration(milliseconds: AppConfig.receiveTimeout),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      ),
    );
    
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getAuthToken() ?? HiveService.getToken();
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          _logger.d('Request: ${options.method} ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.d('Response: ${response.statusCode} ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (error, handler) {
          _logger.e('Error: ${error.response?.statusCode} ${error.requestOptions.path}');
          if (error.response?.statusCode == 401) {
            HiveService.clearUser();
            _storage.clearAuthData();
          }
          return handler.next(error);
        },
      ),
    );
  }
  
  Dio get dio => _dio;
  
  // Auth
  Future<Map<String, dynamic>> login(String phone, String password, {String? deviceId}) async {
    try {
      final response = await _dio.post('/api/auth?action=login', data: {
        'phone': phone, 
        'password': password, 
        'deviceId': deviceId
      });
      return response.data;
    } catch (e) {
      throw NetworkException(ErrorHandler.handleError(e));
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/api/auth?action=register', data: data);
      return response.data;
    } catch (e) {
      throw NetworkException(ErrorHandler.handleError(e));
    }
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    try {
      final response = await _dio.post('/api/auth?action=refresh', data: {'refreshToken': refreshToken});
      return response.data;
    } catch (e) {
      throw NetworkException(ErrorHandler.handleError(e));
    }
  }

  Future<void> logout(String userId, String? refreshToken) async {
    try {
      await _dio.post('/api/auth?action=logout', data: {'userId': userId, 'refreshToken': refreshToken});
    } catch (e) {
      throw NetworkException(ErrorHandler.handleError(e));
    }
  }

  // Groups
  Future<Map<String, dynamic>> getGroups(String userId) async {
    try {
      final response = await _dio.get('/groups', queryParameters: {'userId': userId});
      return response.data;
    } catch (e) {
      throw NetworkException(ErrorHandler.handleError(e));
    }
  }

  Future<Map<String, dynamic>> createGroup(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/groups', data: data);
      return response.data;
    } catch (e) {
      throw NetworkException(ErrorHandler.handleError(e));
    }
  }

  Future<Map<String, dynamic>> getGroupDetails(String groupId, String userId) async {
    try {
      final response = await _dio.get('/groups/$groupId', queryParameters: {'userId': userId});
      return response.data;
    } catch (e) {
      throw NetworkException(ErrorHandler.handleError(e));
    }
  }

  Future<Map<String, dynamic>> getGroupMembership(String groupId, String userId) async {
    try {
      final response = await _dio.get('/groups/$groupId/membership', queryParameters: {'userId': userId});
      return response.data;
    } catch (e) {
      throw NetworkException(ErrorHandler.handleError(e));
    }
  }

  Future<Map<String, dynamic>> joinGroup(String groupId, String userId) async {
    try {
      final response = await _dio.post('/groups/$groupId/join', data: {'userId': userId});
      return response.data;
    } catch (e) {
      throw NetworkException(ErrorHandler.handleError(e));
    }
  }

  Future<Map<String, dynamic>> approveJoinRequest(String requestId, bool approve) async {
    try {
      final response = await _dio.post('/groups/join-requests/$requestId', data: {'approve': approve});
      return response.data;
    } catch (e) {
      throw NetworkException(ErrorHandler.handleError(e));
    }
  }

  Future<Map<String, dynamic>> getFounderDashboard(String groupId, String userId) async {
    try {
      final response = await _dio.get('/groups/$groupId/founder-dashboard', queryParameters: {'userId': userId});
      return response.data;
    } catch (e) {
      throw NetworkException(ErrorHandler.handleError(e));
    }
  }

  // Loans
  Future<Map<String, dynamic>> getLoans({String? groupId, String? membershipId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (groupId != null) queryParams['groupId'] = groupId;
      if (membershipId != null) queryParams['membershipId'] = membershipId;
      final response = await _dio.get('/api/loans', queryParameters: queryParams);
      return response.data;
    } catch (e) {
      throw NetworkException(ErrorHandler.handleError(e));
    }
  }

  Future<Map<String, dynamic>> applyForLoan(String groupId, double amount, String purpose, List<String> guarantorIds, int repaymentPeriod) async {
    try {
      final response = await _dio.post('/api/loans?action=apply', data: {
        'groupId': groupId, 
        'amount': amount, 
        'purpose': purpose, 
        'guarantorIds': guarantorIds, 
        'repaymentPeriod': repaymentPeriod
      });
      return response.data;
    } catch (e) {
      throw NetworkException(ErrorHandler.handleError(e));
    }
  }

  Future<Map<String, dynamic>> payLoan(String loanId, double amount, [String? paymentMethod, String? phone, String? pin]) async {
    try {
      final response = await _dio.post('/api/loans?action=pay', data: {
        'loanId': loanId, 
        'amount': amount, 
        'paymentMethod': paymentMethod ?? 'MTN_MOMO', 
        'phone': phone, 
        'pin': pin
      });
      return response.data;
    } catch (e) {
      throw NetworkException(ErrorHandler.handleError(e));
    }
  }

  // Wallet
  Future<Map<String, dynamic>> getWallet([String? userId]) async {
    try {
      final queryParams = <String, dynamic>{};
      if (userId != null) queryParams['userId'] = userId;
      final response = await _dio.get('/api/wallet', queryParameters: queryParams);
      return response.data;
    } catch (e) {
      throw NetworkException(ErrorHandler.handleError(e));
    }
  }

  Future<Map<String, dynamic>> deposit(String userId, double amount, String provider, {String? phone}) async {
    try {
      final response = await _dio.post('/api/wallet?action=deposit', data: {
        'userId': userId, 
        'amount': amount, 
        'phone': phone, 
        'provider': provider
      });
      return response.data;
    } catch (e) {
      throw NetworkException(ErrorHandler.handleError(e));
    }
  }

  Future<Map<String, dynamic>> withdraw(String userId, double amount, String provider, String pin, {String? phone}) async {
    try {
      final response = await _dio.post('/api/wallet?action=withdraw', data: {
        'userId': userId, 
        'amount': amount, 
        'phone': phone, 
        'provider': provider, 
        'pin': pin
      });
      return response.data;
    } catch (e) {
      throw NetworkException(ErrorHandler.handleError(e));
    }
  }

  Future<Map<String, dynamic>> transfer(double amount, String toPhone, String pin, {String? description}) async {
    try {
      final response = await _dio.post('/api/wallet?action=transfer', data: {
        'amount': amount, 
        'toPhone': toPhone, 
        'pin': pin, 
        'description': description
      });
      return response.data;
    } catch (e) {
      throw NetworkException(ErrorHandler.handleError(e));
    }
  }

  // Transactions
  Future<Map<String, dynamic>> getTransactions({String? userId, String? groupId, String? type}) async {
    try {
      final response = await _dio.get('/transactions', queryParameters: {
        'userId': userId, 
        'groupId': groupId, 
        'type': type
      });
      return response.data;
    } catch (e) {
      throw NetworkException(ErrorHandler.handleError(e));
    }
  }

  // Notifications
  Future<Map<String, dynamic>> getNotifications(String userId) async {
    try {
      final response = await _dio.get('/notifications', queryParameters: {'userId': userId});
      return response.data;
    } catch (e) {
      throw NetworkException(ErrorHandler.handleError(e));
    }
  }

  Future<void> markNotificationRead(String notificationId) async {
    try {
      await _dio.put('/notifications/$notificationId/read');
    } catch (e) {
      throw NetworkException(ErrorHandler.handleError(e));
    }
  }

  // KYC
  Future<Map<String, dynamic>> submitKYC(String documentType, String documentNumber, String documentImage, String selfieImage, {Map<String, dynamic>? metadata}) async {
    try {
      final response = await _dio.post('/api/kyc?action=submit', data: {
        'documentType': documentType, 
        'documentNumber': documentNumber, 
        'documentImage': documentImage, 
        'selfieImage': selfieImage, 
        'metadata': metadata
      });
      return response.data;
    } catch (e) {
      throw NetworkException(ErrorHandler.handleError(e));
    }
  }

  Future<Map<String, dynamic>> getKYCStatus() async {
    try {
      final response = await _dio.get('/api/kyc?action=status');
      return response.data;
    } catch (e) {
      throw NetworkException(ErrorHandler.handleError(e));
    }
  }

  // Contributions
  Future<Map<String, dynamic>> getContributions({String? membershipId, String? groupId}) async {
    try {
      final response = await _dio.get('/contributions', queryParameters: {
        'membershipId': membershipId,
        'groupId': groupId
      });
      return response.data;
    } catch (e) {
      throw NetworkException(ErrorHandler.handleError(e));
    }
  }

  Future<Map<String, dynamic>> payContribution(String membershipId, String groupId, double amount) async {
    try {
      final response = await _dio.post('/contributions', data: {
        'membershipId': membershipId,
        'groupId': groupId,
        'amount': amount
      });
      return response.data;
    } catch (e) {
      throw NetworkException(ErrorHandler.handleError(e));
    }
  }

  // Meetings
  Future<Map<String, dynamic>> getMeetings(String groupId) async {
    try {
      final response = await _dio.get('/meetings', queryParameters: {'groupId': groupId});
      return response.data;
    } catch (e) {
      throw NetworkException(ErrorHandler.handleError(e));
    }
  }

  Future<Map<String, dynamic>> createMeeting(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/meetings', data: data);
      return response.data;
    } catch (e) {
      throw NetworkException(ErrorHandler.handleError(e));
    }
  }

  Future<void> markAttendance(String meetingId, String userId) async {
    try {
      await _dio.post('/meetings/$meetingId/attendance', data: {'userId': userId});
    } catch (e) {
      throw NetworkException(ErrorHandler.handleError(e));
    }
  }

  // Announcements
  Future<Map<String, dynamic>> getAnnouncements(String groupId) async {
    try {
      final response = await _dio.get('/announcements', queryParameters: {'groupId': groupId});
      return response.data;
    } catch (e) {
      throw NetworkException(ErrorHandler.handleError(e));
    }
  }

  Future<Map<String, dynamic>> createAnnouncement(dynamic dataOrGroupId, [String? title, String? content]) async {
    try {
      Map<String, dynamic> body;
      if (dataOrGroupId is Map<String, dynamic>) {
        body = dataOrGroupId;
      } else {
        body = {'groupId': dataOrGroupId, 'title': title, 'content': content};
      }
      final response = await _dio.post('/announcements', data: body);
      return response.data;
    } catch (e) {
      throw NetworkException(ErrorHandler.handleError(e));
    }
  }

  // Dividends
  Future<Map<String, dynamic>> getDividends({String? groupId, String? membershipId}) async {
    try {
      final response = await _dio.get('/dividends', queryParameters: {
        'groupId': groupId, 
        'membershipId': membershipId
      });
      return response.data;
    } catch (e) {
      throw NetworkException(ErrorHandler.handleError(e));
    }
  }

  // User Profile
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final response = await _dio.get('/users/$userId');
      return response.data;
    } catch (e) {
      throw NetworkException(ErrorHandler.handleError(e));
    }
  }

  Future<Map<String, dynamic>> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/users/$userId', data: data);
      return response.data;
    } catch (e) {
      throw NetworkException(ErrorHandler.handleError(e));
    }
  }

  // Generic methods
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await _dio.get(path, queryParameters: queryParameters);
  }
  
  Future<Response> post(String path, {dynamic data}) async {
    return await _dio.post(path, data: data);
  }
  
  Future<Response> put(String path, {dynamic data}) async {
    return await _dio.put(path, data: data);
  }
}
