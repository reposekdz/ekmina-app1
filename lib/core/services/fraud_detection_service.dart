class FraudDetectionService {
  String getRiskLevelText(String riskLevel, String language) {
    final texts = {
      'LOW': {
        'rw': 'Umutekano mwiza',
        'en': 'Low Risk',
        'fr': 'Risque faible'
      },
      'MEDIUM': {
        'rw': 'Umutekano wo hagati',
        'en': 'Medium Risk',
        'fr': 'Risque moyen'
      },
      'HIGH': {
        'rw': 'Akaga gakomeye',
        'en': 'High Risk',
        'fr': 'Risque élevé'
      },
      'CRITICAL': {
        'rw': 'Akaga gakabije cyane',
        'en': 'Critical Risk',
        'fr': 'Risque critique'
      },
    };
    return texts[riskLevel]?[language] ?? riskLevel;
  }

  String getRiskLevelColor(String riskLevel) {
    switch (riskLevel) {
      case 'LOW':
        return '#4CAF50';
      case 'MEDIUM':
        return '#FF9800';
      case 'HIGH':
        return '#F44336';
      case 'CRITICAL':
        return '#D32F2F';
      default:
        return '#9E9E9E';
    }
  }

  String getRiskWarningMessage(String riskLevel, List<String> reasons, String language) {
    if (riskLevel == 'LOW') return '';

    final headers = {
      'MEDIUM': {
        'rw': 'Burira! Iyi transaction ifite akaga ko hagati.',
        'en': 'Warning! This transaction has medium risk.',
        'fr': 'Attention! Cette transaction présente un risque moyen.'
      },
      'HIGH': {
        'rw': 'Akaga gakomeye! Iyi transaction ifite akaga gakomeye.',
        'en': 'High Risk! This transaction has high risk.',
        'fr': 'Risque élevé! Cette transaction présente un risque élevé.'
      },
      'CRITICAL': {
        'rw': 'Akaga gakabije! Iyi transaction yahagaritswe.',
        'en': 'Critical Risk! This transaction has been blocked.',
        'fr': 'Risque critique! Cette transaction a été bloquée.'
      },
    };

    final reasonTexts = {
      'VELOCITY_CHECK': {
        'rw': 'Ibikorwa byinshi mu gihe gito',
        'en': 'Too many transactions in short time',
        'fr': 'Trop de transactions en peu de temps'
      },
      'AMOUNT_CHECK': {
        'rw': 'Amafaranga menshi kuruta bisanzwe',
        'en': 'Amount higher than usual',
        'fr': 'Montant plus élevé que d\'habitude'
      },
      'FREQUENCY_CHECK': {
        'rw': 'Ibikorwa byinshi ku munsi',
        'en': 'Too many transactions today',
        'fr': 'Trop de transactions aujourd\'hui'
      },
      'PATTERN_CHECK': {
        'rw': 'Ibikorwa bitandukanye n\'ibisanzwe',
        'en': 'Unusual transaction pattern',
        'fr': 'Modèle de transaction inhabituel'
      },
      'KYC_CHECK': {
        'rw': 'Amafaranga menshi asaba kwemeza umwirondoro',
        'en': 'Large amount requires KYC verification',
        'fr': 'Montant important nécessite vérification KYC'
      },
    };

    String message = headers[riskLevel]?[language] ?? '';
    if (reasons.isNotEmpty) {
      message += '\n\n';
      message += reasons.map((r) => '• ${reasonTexts[r]?[language] ?? r}').join('\n');
    }

    return message;
  }

  bool shouldBlockTransaction(String riskLevel) {
    return riskLevel == 'CRITICAL';
  }

  bool shouldWarnUser(String riskLevel) {
    return riskLevel == 'HIGH' || riskLevel == 'MEDIUM';
  }

  String getBlockedTransactionMessage(String language) {
    final messages = {
      'rw': 'Iyi transaction yahagaritswe kubera umutekano. Hamagara support: +250 788 123 456',
      'en': 'This transaction has been blocked for security. Contact support: +250 788 123 456',
      'fr': 'Cette transaction a été bloquée pour des raisons de sécurité. Contactez le support: +250 788 123 456'
    };
    return messages[language] ?? messages['en']!;
  }

  Map<String, dynamic> analyzeFraudCheck(Map<String, dynamic>? fraudCheck) {
    if (fraudCheck == null) {
      return {
        'riskLevel': 'LOW',
        'reasons': [],
        'shouldBlock': false,
        'shouldWarn': false,
      };
    }

    final riskLevel = fraudCheck['riskLevel'] ?? 'LOW';
    final reasons = List<String>.from(fraudCheck['reasons'] ?? []);

    return {
      'riskLevel': riskLevel,
      'reasons': reasons,
      'shouldBlock': shouldBlockTransaction(riskLevel),
      'shouldWarn': shouldWarnUser(riskLevel),
      'score': fraudCheck['score'] ?? 0,
    };
  }
}
