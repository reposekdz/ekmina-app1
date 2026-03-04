class AppConfig {
  static const String appName = 'E-Kimina Rwanda';

  // Use a production-ready URL or a configurable one
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.ekimina.rw',
  );

  // For local development on web, you might need to point to your local server
  // static const String apiBaseUrl = 'http://localhost:3000';

  static const String mtmMomoApiKey = String.fromEnvironment('MTN_MOMO_API_KEY');
  static const String airtelMoneyApiKey = String.fromEnvironment('AIRTEL_MONEY_API_KEY');
  
  static const String ussdCode = '*700#';
  
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;
  
  static const double platformFeePercentage = 0.01;
  static const double joinFeeCommission = 0.10;
  
  static const int maxLoanMultiplier = 3;
  static const int defaultGuarantorsRequired = 2;
  static const int defaultApprovalThreshold = 2;
  
  static const String supportPhone = '+250788000000';
  static const String supportEmail = 'support@ekimina.rw';
  
  static const List<String> supportedLanguages = ['rw', 'en', 'fr'];
  
  static const Map<String, String> languageNames = {
    'rw': 'Kinyarwanda',
    'en': 'English',
    'fr': 'Français',
  };
}
