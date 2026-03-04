import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:logger/logger.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final Logger _logger = Logger();

  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters?.cast<String, Object>());
      _logger.i('Analytics event logged: $name');
    } catch (e) {
      _logger.e('Failed to log analytics event: $e');
    }
  }

  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
  }

  Future<void> setUserProperty(String name, String value) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  // Custom events
  Future<void> logGroupCreated(String groupId, String groupName) async {
    await logEvent('group_created', parameters: {'group_id': groupId, 'group_name': groupName});
  }

  Future<void> logContributionMade(String groupId, double amount) async {
    await logEvent('contribution_made', parameters: {'group_id': groupId, 'amount': amount});
  }

  Future<void> logLoanRequested(String groupId, double amount) async {
    await logEvent('loan_requested', parameters: {'group_id': groupId, 'amount': amount});
  }

  Future<void> logPaymentCompleted(String method, double amount) async {
    await logEvent('payment_completed', parameters: {'method': method, 'amount': amount});
  }
}
