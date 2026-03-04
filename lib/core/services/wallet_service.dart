import '../../data/remote/api_client.dart';

class WalletService {
  final ApiClient _apiClient;
  WalletService(this._apiClient);

  // Get wallet balance
  Future<Map<String, dynamic>> getWalletBalance(String userId) async {
    return await _apiClient.get('/wallet/$userId/balance');
  }

  // Deposit to wallet (MTN MoMo / Airtel Money)
  Future<Map<String, dynamic>> depositToWallet({
    required String userId,
    required double amount,
    required String provider, // MTN or AIRTEL
    required String phoneNumber,
  }) async {
    return await _apiClient.post('/wallet/deposit', data: {
      'userId': userId,
      'amount': amount,
      'provider': provider,
      'phoneNumber': phoneNumber,
      'currency': 'RWF',
    });
  }

  // Withdraw from wallet
  Future<Map<String, dynamic>> withdrawFromWallet({
    required String userId,
    required double amount,
    required String provider,
    required String phoneNumber,
    required String pin,
  }) async {
    return await _apiClient.post('/wallet/withdraw', data: {
      'userId': userId,
      'amount': amount,
      'provider': provider,
      'phoneNumber': phoneNumber,
      'pin': pin,
      'currency': 'RWF',
    });
  }

  // Transfer to investment from wallet
  Future<Map<String, dynamic>> transferToInvestment({
    required String userId,
    required double amount,
    required String pin,
  }) async {
    return await _apiClient.post('/wallet/transfer-to-investment', data: {
      'userId': userId,
      'amount': amount,
      'pin': pin,
    });
  }

  // Transfer to group from wallet
  Future<Map<String, dynamic>> transferToGroup({
    required String userId,
    required String groupId,
    required double amount,
    required String pin,
  }) async {
    return await _apiClient.post('/wallet/transfer-to-group', data: {
      'userId': userId,
      'groupId': groupId,
      'amount': amount,
      'pin': pin,
    });
  }

  // Get wallet transactions
  Future<Map<String, dynamic>> getWalletTransactions(String userId, {int page = 1, int limit = 20}) async {
    return await _apiClient.get('/wallet/$userId/transactions?page=$page&limit=$limit');
  }

  // Get wallet statistics
  Future<Map<String, dynamic>> getWalletStats(String userId) async {
    return await _apiClient.get('/wallet/$userId/stats');
  }
}
