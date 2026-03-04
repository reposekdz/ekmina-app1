import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  AppException(this.message, {this.code, this.details});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException(super.message, {super.code, super.details});
}

class AuthException extends AppException {
  AuthException(super.message, {super.code, super.details});
}

class ValidationException extends AppException {
  ValidationException(super.message, {super.code, super.details});
}

class ErrorHandler {
  static final Logger _logger = Logger();

  static String handleError(dynamic error) {
    _logger.e('Error occurred: $error');

    if (error is DioException) {
      return _handleDioError(error);
    } else if (error is AppException) {
      return error.message;
    } else {
      return 'Ikosa ritunguranye. Ongera ugerageze.';
    }
  }

  static String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Igihe cyarangiye. Gerageza kongera.';
      
      case DioExceptionType.badResponse:
        return _handleStatusCode(error.response?.statusCode);
      
      case DioExceptionType.cancel:
        return 'Ibikorwa byahagaritswe';
      
      case DioExceptionType.connectionError:
        return 'Nta murandasi. Gerageza kongera.';
      
      default:
        return 'Ikosa ritunguranye. Ongera ugerageze.';
    }
  }

  static String _handleStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Amakuru yashyizwemo ntabwo ari yo';
      case 401:
        return 'Ntabwo wemerewe. Injira kongera.';
      case 403:
        return 'Ntabwo ufite uburenganzira';
      case 404:
        return 'Ntabwo byabonetse';
      case 500:
        return 'Ikosa rya seriveri. Gerageza nyuma.';
      case 503:
        return 'Serivisi ntiboneka. Gerageza nyuma.';
      default:
        return 'Ikosa ritunguranye (Code: $statusCode)';
    }
  }

  static void logError(String message, {dynamic error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
