import '../../data/remote/api_client.dart';

class LoanService {
  final ApiClient _apiClient;

  LoanService(this._apiClient);

  Future<Map<String, dynamic>> checkEligibility(String groupId) async {
    try {
      final response = await _apiClient.dio.get('/api/loans?action=check-eligibility&groupId=$groupId');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> applyForLoan({
    required String groupId,
    required double amount,
    required String purpose,
    required List<String> guarantorIds,
    required int repaymentPeriod,
  }) async {
    // Validate inputs
    if (amount < 1000) {
      throw Exception('Amafaranga agomba kuba angana na 1,000 RWF cyangwa arenga');
    }
    if (guarantorIds.length < 2) {
      throw Exception('Ugomba guhitamo abamenyesha babiri nibura');
    }
    if (repaymentPeriod < 1 || repaymentPeriod > 12) {
      throw Exception('Igihe cyo kwishyura kigomba kuba hagati y\'amezi 1 na 12');
    }
    if (purpose.trim().isEmpty) {
      throw Exception('Sobanura impamvu yo gusaba inguzanyo');
    }

    return await _apiClient.applyForLoan(
      groupId,
      amount,
      purpose,
      guarantorIds,
      repaymentPeriod,
    );
  }

  Future<Map<String, dynamic>> approveLoan({
    required String loanId,
    required bool approved,
    String? comment,
  }) async {
    return await _apiClient.approveLoan(loanId, approved, comment: comment);
  }

  Future<Map<String, dynamic>> payLoan({
    required String loanId,
    required double amount,
    required String paymentMethod,
    String? phone,
    String? pin,
  }) async {
    if (amount <= 0) {
      throw Exception('Amafaranga agomba kuba angana na 0 cyangwa arenga');
    }

    if (paymentMethod == 'WALLET' && (pin == null || pin.isEmpty)) {
      throw Exception('Shyiramo PIN yawe');
    }

    if ((paymentMethod == 'MTN' || paymentMethod == 'AIRTEL') && 
        (phone == null || phone.isEmpty)) {
      throw Exception('Shyiramo nomero ya telefoni');
    }

    return await _apiClient.payLoan(
      loanId,
      amount,
      paymentMethod,
      phone: phone,
      pin: pin,
    );
  }

  Future<List<dynamic>> getUserLoans({String? groupId}) async {
    final response = await _apiClient.getLoans(groupId: groupId);
    return response['loans'] ?? [];
  }

  double calculateInterest({
    required double amount,
    required double interestRate,
    required int months,
  }) {
    return (amount * interestRate * months) / 100;
  }

  double calculateTotalAmount({
    required double amount,
    required double interestRate,
    required int months,
  }) {
    final interest = calculateInterest(
      amount: amount,
      interestRate: interestRate,
      months: months,
    );
    return amount + interest;
  }

  double calculateMonthlyPayment({
    required double totalAmount,
    required int months,
  }) {
    return totalAmount / months;
  }

  String getLoanStatusText(String status, String language) {
    final texts = {
      'PENDING': {
        'rw': 'Irategerezwa',
        'en': 'Pending Approval',
        'fr': 'En attente d\'approbation'
      },
      'APPROVED': {
        'rw': 'Yemejwe',
        'en': 'Approved',
        'fr': 'Approuvé'
      },
      'REJECTED': {
        'rw': 'Yanze',
        'en': 'Rejected',
        'fr': 'Rejeté'
      },
      'DISBURSED': {
        'rw': 'Yahawe',
        'en': 'Disbursed',
        'fr': 'Décaissé'
      },
      'ACTIVE': {
        'rw': 'Irakora',
        'en': 'Active',
        'fr': 'Actif'
      },
      'PAID': {
        'rw': 'Yishyuwe',
        'en': 'Fully Paid',
        'fr': 'Entièrement payé'
      },
      'DEFAULTED': {
        'rw': 'Ntiyishyuwe',
        'en': 'Defaulted',
        'fr': 'En défaut'
      },
    };
    return texts[status]?[language] ?? status;
  }

  String getLoanStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return '#FF9800';
      case 'APPROVED':
        return '#2196F3';
      case 'REJECTED':
        return '#F44336';
      case 'DISBURSED':
      case 'ACTIVE':
        return '#4CAF50';
      case 'PAID':
        return '#8BC34A';
      case 'DEFAULTED':
        return '#D32F2F';
      default:
        return '#9E9E9E';
    }
  }

  String getPaymentMethodText(String method, String language) {
    final texts = {
      'WALLET': {
        'rw': 'Wallet',
        'en': 'Wallet',
        'fr': 'Portefeuille'
      },
      'MTN': {
        'rw': 'MTN MoMo',
        'en': 'MTN MoMo',
        'fr': 'MTN MoMo'
      },
      'AIRTEL': {
        'rw': 'Airtel Money',
        'en': 'Airtel Money',
        'fr': 'Airtel Money'
      },
    };
    return texts[method]?[language] ?? method;
  }

  bool isLoanOverdue(DateTime dueDate) {
    return DateTime.now().isAfter(dueDate);
  }

  int getDaysOverdue(DateTime dueDate) {
    if (!isLoanOverdue(dueDate)) return 0;
    return DateTime.now().difference(dueDate).inDays;
  }

  String getEligibilityMessage(Map<String, dynamic> eligibility, String language) {
    if (eligibility['isEligible'] == true) {
      final maxAmount = eligibility['maxLoanAmount'] ?? 0;
      final messages = {
        'rw': 'Ushobora gusaba inguzanyo igera kuri ${maxAmount.toStringAsFixed(0)} RWF',
        'en': 'You can apply for a loan up to ${maxAmount.toStringAsFixed(0)} RWF',
        'fr': 'Vous pouvez demander un prêt jusqu\'à ${maxAmount.toStringAsFixed(0)} RWF'
      };
      return messages[language] ?? messages['en']!;
    } else {
      final reason = eligibility['reason'] ?? 'Unknown';
      return reason;
    }
  }
}
