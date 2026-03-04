import 'package:flutter/material.dart';
import '../../data/remote/api_client.dart';

class InvestmentService {
  final ApiClient _apiClient;
  InvestmentService(this._apiClient);

  // Dynamic interest rate based on amount and duration
  double calculateInterestRate(double amount, int days) {
    double baseRate;
    if (amount < 50000) baseRate = 0.08;
    else if (amount < 200000) baseRate = 0.12;
    else if (amount < 500000) baseRate = 0.15;
    else if (amount < 1000000) baseRate = 0.18;
    else if (amount < 5000000) baseRate = 0.22;
    else if (amount < 10000000) baseRate = 0.25;
    else if (amount < 50000000) baseRate = 0.30;
    else if (amount < 100000000) baseRate = 0.35;
    else baseRate = 0.40;

    double durationBonus = 0;
    if (days >= 180) durationBonus = 0.05;
    else if (days >= 90) durationBonus = 0.03;
    else if (days >= 30) durationBonus = 0.02;
    else if (days >= 10) durationBonus = 0.01;

    return baseRate + durationBonus;
  }

  // Get investment tier
  Map<String, dynamic> getInvestmentTier(double amount) {
    if (amount < 50000) {
      return {'name': 'Starter', 'nameRw': 'Intangiriro', 'minRate': 8, 'maxRate': 14, 'color': const Color(0xFF4CAF50), 'icon': Icons.savings, 'range': '200 - 49,999 RWF', 'badge': '🌱'};
    } else if (amount < 200000) {
      return {'name': 'Bronze', 'nameRw': 'Umuringa', 'minRate': 12, 'maxRate': 17, 'color': const Color(0xFFCD7F32), 'icon': Icons.trending_up, 'range': '50K - 199K', 'badge': '🥉'};
    } else if (amount < 500000) {
      return {'name': 'Silver', 'nameRw': 'Ifeza', 'minRate': 15, 'maxRate': 20, 'color': const Color(0xFF9E9E9E), 'icon': Icons.star, 'range': '200K - 499K', 'badge': '🥈'};
    } else if (amount < 1000000) {
      return {'name': 'Gold', 'nameRw': 'Zahabu', 'minRate': 18, 'maxRate': 23, 'color': const Color(0xFFFFD700), 'icon': Icons.workspace_premium, 'range': '500K - 999K', 'badge': '🥇'};
    } else if (amount < 5000000) {
      return {'name': 'Platinum', 'nameRw': 'Platinum', 'minRate': 22, 'maxRate': 27, 'color': const Color(0xFF9C27B0), 'icon': Icons.diamond, 'range': '1M - 4.9M', 'badge': '💎'};
    } else if (amount < 10000000) {
      return {'name': 'Diamond', 'nameRw': 'Diyama', 'minRate': 25, 'maxRate': 30, 'color': const Color(0xFF00BCD4), 'icon': Icons.auto_awesome, 'range': '5M - 9.9M', 'badge': '💠'};
    } else if (amount < 50000000) {
      return {'name': 'Emerald', 'nameRw': 'Emerald', 'minRate': 30, 'maxRate': 35, 'color': const Color(0xFF00E676), 'icon': Icons.stars, 'range': '10M - 49M', 'badge': '🌟'};
    } else if (amount < 100000000) {
      return {'name': 'Ruby', 'nameRw': 'Ruby', 'minRate': 35, 'maxRate': 40, 'color': const Color(0xFFE91E63), 'icon': Icons.military_tech, 'range': '50M - 99M', 'badge': '💖'};
    } else {
      return {'name': 'Elite', 'nameRw': 'Elite', 'minRate': 40, 'maxRate': 45, 'color': const Color(0xFF6A1B9A), 'icon': Icons.emoji_events, 'range': '100M+', 'badge': '👑'};
    }
  }

  // Duration options (minimum 10 days)
  List<Map<String, dynamic>> get durationOptions => [
    {'days': 10, 'label': '10 Iminsi', 'labelEn': '10 Days', 'bonus': 1},
    {'days': 14, 'label': '2 Ibyumweru', 'labelEn': '2 Weeks', 'bonus': 1},
    {'days': 21, 'label': '3 Ibyumweru', 'labelEn': '3 Weeks', 'bonus': 1},
    {'days': 30, 'label': '1 Ukwezi', 'labelEn': '1 Month', 'bonus': 2},
    {'days': 60, 'label': '2 Amezi', 'labelEn': '2 Months', 'bonus': 2},
    {'days': 90, 'label': '3 Amezi', 'labelEn': '3 Months', 'bonus': 3},
    {'days': 180, 'label': '6 Amezi', 'labelEn': '6 Months', 'bonus': 5},
    {'days': 365, 'label': '1 Umwaka', 'labelEn': '1 Year', 'bonus': 5},
  ];

  // Calculate expected return
  double calculateExpectedReturn({required double amount, required int durationDays}) {
    final rate = calculateInterestRate(amount, durationDays);
    final interest = amount * rate * (durationDays / 365);
    return amount + interest;
  }

  // Calculate current value (real-time streaming)
  double calculateCurrentValue({
    required double amount,
    required int durationDays,
    required DateTime startDate,
  }) {
    final now = DateTime.now();
    final elapsedSeconds = now.difference(startDate).inSeconds;
    final totalSeconds = durationDays * 24 * 60 * 60;
    
    if (elapsedSeconds >= totalSeconds) {
      return calculateExpectedReturn(amount: amount, durationDays: durationDays);
    }
    
    final rate = calculateInterestRate(amount, durationDays);
    final totalInterest = amount * rate * (durationDays / 365);
    final currentInterest = totalInterest * (elapsedSeconds / totalSeconds);
    
    return amount + currentInterest;
  }

  // Calculate per-second growth
  double calculatePerSecondGrowth(double amount, int days) {
    final rate = calculateInterestRate(amount, days);
    final totalInterest = amount * rate * (days / 365);
    final totalSeconds = days * 24 * 60 * 60;
    return totalInterest / totalSeconds;
  }

  // Calculate daily return
  double calculateDailyReturn(double amount, int days) {
    final total = calculateExpectedReturn(amount: amount, durationDays: days);
    return (total - amount) / days;
  }

  // Progressive early withdrawal penalty
  double calculateEarlyWithdrawalPenalty(double amount, int daysInvested, int totalDays) {
    final remainingDays = totalDays - daysInvested;
    final remainingRatio = remainingDays / totalDays;
    
    double penaltyRate;
    if (remainingRatio > 0.75) penaltyRate = 0.25;
    else if (remainingRatio > 0.50) penaltyRate = 0.18;
    else if (remainingRatio > 0.25) penaltyRate = 0.12;
    else penaltyRate = 0.06;
    
    return amount * penaltyRate;
  }

  // E-Kimina profit calculation
  Map<String, double> calculatePlatformProfit(double amount, int days) {
    final userRate = calculateInterestRate(amount, days);
    final lendingRate = userRate + 0.10; // E-Kimina lends at 10% higher
    
    final userInterest = amount * userRate * (days / 365);
    final lendingInterest = amount * lendingRate * (days / 365);
    final platformProfit = lendingInterest - userInterest;
    
    return {
      'userReturn': amount + userInterest,
      'lendingReturn': amount + lendingInterest,
      'platformProfit': platformProfit,
      'profitMargin': (platformProfit / amount) * 100,
    };
  }

  // Create investment
  Future<Map<String, dynamic>> createInvestment({
    required double amount,
    required int durationDays,
    required String pin,
  }) async {
    final rate = calculateInterestRate(amount, durationDays);
    final tier = getInvestmentTier(amount);
    final expectedReturn = calculateExpectedReturn(amount: amount, durationDays: durationDays);
    final platformProfit = calculatePlatformProfit(amount, durationDays);

    final response = await _apiClient.post('/investments', data: {
      'tier': tier['name'],
      'amount': amount,
      'durationDays': durationDays,
      'interestRate': rate,
      'expectedReturn': expectedReturn,
      'platformProfit': platformProfit['platformProfit'],
      'pin': pin,
    });

    return response.data;
  }

  Future<Map<String, dynamic>> getUserInvestments(String userId) async {
    return await _apiClient.get('/investments/user/$userId');
  }

  Future<Map<String, dynamic>> getInvestmentDetails(String investmentId) async {
    return await _apiClient.get('/investments/$investmentId');
  }

  Future<Map<String, dynamic>> withdrawInvestment({
    required String investmentId,
    required bool isEarly,
  }) async {
    return await _apiClient.post('/investments/$investmentId/withdraw', {
      'isEarly': isEarly,
      'withdrawalDate': DateTime.now().toIso8601String(),
    });
  }

  Future<Map<String, dynamic>> getInvestmentStats(String userId) async {
    return await _apiClient.get('/investments/user/$userId/stats');
  }

  Future<Map<String, dynamic>> getRealTimeValue(String investmentId) async {
    return await _apiClient.get('/investments/$investmentId/realtime');
  }
}
