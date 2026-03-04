class Validators {
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Shyiramo nimero ya telefoni';
    }
    
    final phoneRegex = RegExp(r'^(078|079|072|073)\d{7}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Nimero ya telefoni ntabwo ari yo (078/079/072/073XXXXXXX)';
    }
    
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Shyiramo imeyili';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Imeyili ntabwo ari yo';
    }
    
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Shyiramo ijambo ryibanga';
    }
    
    if (value.length < 6) {
      return 'Ijambo ryibanga rigomba kuba rifite imibare 6 cyangwa irenga';
    }
    
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Shyiramo amazina';
    }
    
    if (value.length < 2) {
      return 'Amazina agomba kuba afite inyuguti 2 cyangwa zirenga';
    }
    
    return null;
  }

  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Shyiramo amafaranga';
    }
    
    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Shyiramo umubare wibanze';
    }
    
    if (amount <= 0) {
      return 'Amafaranga agomba kuba arenga 0';
    }
    
    return null;
  }

  static String? validatePin(String? value) {
    if (value == null || value.isEmpty) {
      return 'Shyiramo PIN';
    }
    
    if (value.length != 4) {
      return 'PIN igomba kuba ifite imibare 4';
    }
    
    final pinRegex = RegExp(r'^\d{4}$');
    if (!pinRegex.hasMatch(value)) {
      return 'PIN igomba kuba imibare gusa';
    }
    
    return null;
  }

  static String? validateNationalId(String? value) {
    if (value == null || value.isEmpty) {
      return 'Shyiramo indangamuntu';
    }
    
    if (value.length != 16) {
      return 'Indangamuntu igomba kuba ifite imibare 16';
    }
    
    final idRegex = RegExp(r'^\d{16}$');
    if (!idRegex.hasMatch(value)) {
      return 'Indangamuntu ntabwo ari yo';
    }
    
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Shyiramo $fieldName';
    }
    return null;
  }

  static String? validateMinAmount(String? value, double minAmount) {
    final error = validateAmount(value);
    if (error != null) return error;
    
    final amount = double.parse(value!);
    if (amount < minAmount) {
      return 'Amafaranga agomba kuba angana na ${minAmount.toStringAsFixed(0)} RWF cyangwa arenga';
    }
    
    return null;
  }

  static String? validateMaxAmount(String? value, double maxAmount) {
    final error = validateAmount(value);
    if (error != null) return error;
    
    final amount = double.parse(value!);
    if (amount > maxAmount) {
      return 'Amafaranga ntashobora kurenga ${maxAmount.toStringAsFixed(0)} RWF';
    }
    
    return null;
  }
}
