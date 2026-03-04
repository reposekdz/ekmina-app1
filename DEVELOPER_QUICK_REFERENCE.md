# E-KIMINA DEVELOPER QUICK REFERENCE

## 🚀 Quick Start Guide for New Components

### 📱 NEW SCREENS

#### 1. Password Reset Screen
```dart
// Navigate to password reset
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const PasswordResetScreen(),
  ),
);
```

#### 2. Security Settings Screen
```dart
// Navigate to security settings
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => SecuritySettingsScreen(userId: currentUserId),
  ),
);
```

#### 3. Login History Screen
```dart
// Navigate to login history
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => LoginHistoryScreen(userId: currentUserId),
  ),
);
```

---

### 🎨 UI COMPONENTS

#### Transaction Card Widget

**Basic Usage:**
```dart
import 'package:ekmina/presentation/widgets/transaction_card.dart';

TransactionCard(
  transaction: {
    'type': 'DEPOSIT',
    'amount': 50000,
    'status': 'COMPLETED',
    'description': 'MTN MoMo Deposit',
    'provider': 'MTN_MOMO',
    'createdAt': '2024-01-15T10:30:00Z',
  },
  onTap: () {
    // Navigate to transaction details
  },
)
```

**With Fraud Detection:**
```dart
TransactionCard(
  transaction: {
    'type': 'WITHDRAWAL',
    'amount': 500000,
    'status': 'BLOCKED',
    'fraudRisk': 'HIGH',
    'fraudScore': 85,
    'description': 'Large withdrawal',
    'provider': 'MTN_MOMO',
    'createdAt': '2024-01-15T10:30:00Z',
  },
  onTap: () => showTransactionDetails(),
)
```

**Transaction Types:**
- `DEPOSIT` - Money in (green, arrow down)
- `WITHDRAWAL` - Money out (red, arrow up)
- `TRANSFER_IN` / `TRANSFER_OUT` - Transfers (blue, swap)
- `LOAN_DISBURSEMENT` - Loan received (green, bank)
- `LOAN_PAYMENT` - Loan payment (orange, payment)
- `FEE` - Service fee (grey, receipt)

**Status Values:**
- `COMPLETED` / `SUCCESS` - Green
- `PENDING` - Orange
- `FAILED` - Red
- `BLOCKED` - Red

---

#### KYC Status Badge Widget

**Basic Usage:**
```dart
import 'package:ekmina/presentation/widgets/kyc_status_badge.dart';

// With label
KYCStatusBadge(
  status: 'VERIFIED',
  showLabel: true,
)

// Icon only
KYCStatusBadge(
  status: 'PENDING',
  showLabel: false,
  size: 32,
)
```

**Animated Version:**
```dart
// Automatically animates for PENDING and UNDER_REVIEW
AnimatedKYCStatusBadge(
  status: 'PENDING',
  showLabel: true,
)
```

**Status Values:**
- `VERIFIED` / `APPROVED` - Green, verified icon
- `PENDING` / `SUBMITTED` - Orange, pending icon
- `REJECTED` / `FAILED` - Red, cancel icon
- `NOT_STARTED` / `INCOMPLETE` - Grey, info icon
- `UNDER_REVIEW` - Blue, review icon

---

#### Fraud Warning Widget

**Full Warning:**
```dart
import 'package:ekmina/presentation/widgets/fraud_warning_widget.dart';

FraudWarningWidget(
  riskLevel: 'HIGH',
  message: 'Unusual transaction pattern detected',
  reasons: [
    'Transaction amount exceeds normal pattern',
    'New device detected',
    'Unusual time of transaction',
  ],
  onViewDetails: () {
    // Show detailed fraud analysis
  },
  onDismiss: () {
    // Dismiss warning
  },
)
```

**Compact Version:**
```dart
CompactFraudWarning(
  riskLevel: 'MEDIUM',
  onTap: () {
    // Show full warning details
  },
)
```

**Risk Levels:**
- `CRITICAL` - Dark red, dangerous icon
- `HIGH` - Red, warning icon
- `MEDIUM` - Orange, error outline icon
- `LOW` - Yellow, info icon

---

#### PIN Input Widget

**Dialog Version:**
```dart
import 'package:ekmina/presentation/widgets/pin_input_widget.dart';

// Show PIN dialog
final pin = await PINInputDialog.show(
  context,
  title: 'Emeza igikorwa',
  subtitle: 'Shyiramo PIN yawe yo kwishyura',
  showBiometric: true,
);

if (pin != null) {
  if (pin == 'BIOMETRIC') {
    // User authenticated with biometric
  } else {
    // User entered PIN: pin
  }
}
```

**Bottom Sheet Version:**
```dart
final pin = await PINInputBottomSheet.show(
  context,
  title: 'Shyiramo PIN',
  subtitle: 'Emeza kwishyura',
  showBiometric: true,
);
```

**Inline Version:**
```dart
PINInputWidget(
  title: 'Shyiramo PIN',
  subtitle: 'PIN yawe yo kwishyura',
  showBiometric: true,
  obscureText: true,
  onCompleted: (pin) {
    // Process PIN
    if (pin == 'BIOMETRIC') {
      // Biometric auth
    } else {
      // PIN entered
    }
  },
  onBiometricPressed: () async {
    // Custom biometric handling
  },
)
```

---

#### Payment Method Selector

**Full Version:**
```dart
import 'package:ekmina/presentation/widgets/payment_method_selector.dart';

PaymentMethodSelector(
  selectedMethod: PaymentMethod.mtnMomo,
  onMethodSelected: (method) {
    setState(() {
      _selectedMethod = method;
    });
  },
  showWallet: true,
  walletBalance: 100000,
  enabledMethods: [
    PaymentMethod.mtnMomo,
    PaymentMethod.airtelMoney,
    PaymentMethod.wallet,
  ],
)
```

**Compact Version:**
```dart
CompactPaymentMethodSelector(
  selectedMethod: _selectedMethod,
  onMethodSelected: (method) {
    setState(() => _selectedMethod = method);
  },
  showWallet: true,
)
```

**Using Payment Method:**
```dart
// Get string value for API
final methodValue = _selectedMethod.value; // 'MTN_MOMO'

// Get display name
final displayName = _selectedMethod.displayName; // 'MTN Mobile Money'

// Get icon
final icon = _selectedMethod.icon; // Icons.phone_android

// Get color
final color = _selectedMethod.color; // Colors.yellow[700]

// Convert from string
final method = paymentMethodFromString('MTN_MOMO'); // PaymentMethod.mtnMomo
```

---

## 🎯 COMMON PATTERNS

### 1. Show Transaction with Fraud Warning
```dart
Column(
  children: [
    if (transaction['fraudRisk'] != 'LOW')
      FraudWarningWidget(
        riskLevel: transaction['fraudRisk'],
        message: 'This transaction has been flagged',
      ),
    TransactionCard(
      transaction: transaction,
      onTap: () => showDetails(),
    ),
  ],
)
```

### 2. Profile with KYC Badge
```dart
Row(
  children: [
    CircleAvatar(
      backgroundImage: NetworkImage(user.photoUrl),
    ),
    SizedBox(width: 12),
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user.name, style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 4),
          KYCStatusBadge(status: user.kycStatus),
        ],
      ),
    ),
  ],
)
```

### 3. Payment Flow with PIN
```dart
Future<void> processPayment() async {
  // Select payment method
  final method = await showDialog<PaymentMethod>(
    context: context,
    builder: (context) => Dialog(
      child: PaymentMethodSelector(
        onMethodSelected: (m) => Navigator.pop(context, m),
      ),
    ),
  );
  
  if (method == null) return;
  
  // Get PIN
  final pin = await PINInputDialog.show(context);
  
  if (pin == null) return;
  
  // Process payment
  await api.processPayment(
    method: method.value,
    pin: pin,
    amount: amount,
  );
}
```

### 4. Transaction List with Filters
```dart
ListView.builder(
  itemCount: transactions.length,
  itemBuilder: (context, index) {
    final tx = transactions[index];
    return TransactionCard(
      transaction: tx,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailsScreen(
              transactionId: tx['id'],
            ),
          ),
        );
      },
    );
  },
)
```

---

## 🎨 THEMING

### Colors
```dart
// Primary
const primaryGreen = Color(0xFF00A86B);
const primaryGold = Color(0xFFFFB800);
const primaryBlue = Color(0xFF0066CC);

// Status
const successGreen = Colors.green;
const warningOrange = Colors.orange;
const errorRed = Colors.red;
const infoBlue = Colors.blue;

// Fraud Risk
final criticalRed = Colors.red[700];
final highRed = Colors.red;
final mediumOrange = Colors.orange;
final lowYellow = Colors.yellow[700];
```

### Border Radius
```dart
const smallRadius = 8.0;
const mediumRadius = 12.0;
const largeRadius = 16.0;
const circularRadius = 20.0;
```

### Spacing
```dart
const tinySpace = 4.0;
const smallSpace = 8.0;
const mediumSpace = 16.0;
const largeSpace = 24.0;
const xlargeSpace = 32.0;
```

---

## 🔧 UTILITIES

### Format Currency
```dart
import 'package:ekmina/core/utils/formatters.dart';

Formatters.formatCurrency(50000); // "50,000 RWF"
Formatters.formatCompactNumber(1500000); // "1.5M"
```

### Format Date/Time
```dart
Formatters.formatDate(DateTime.now()); // "Jan 15, 2024"
Formatters.formatDateTime(DateTime.now()); // "Jan 15, 2024 10:30 AM"
Formatters.formatTime(DateTime.now()); // "10:30 AM"
```

### Validators
```dart
import 'package:ekmina/core/utils/validators.dart';

Validators.validatePhone(phone); // Phone validation
Validators.validatePassword(password); // Password validation
Validators.validateMinAmount(amount, 1000); // Min amount check
Validators.validateMaxAmount(amount, balance); // Max amount check
```

---

## 🐛 ERROR HANDLING

### API Errors
```dart
import 'package:ekmina/core/utils/error_handler.dart';

try {
  await api.someMethod();
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(ErrorHandler.handleError(e)),
      backgroundColor: Colors.red,
    ),
  );
}
```

### Biometric Errors
```dart
final biometric = BiometricService();

final canAuth = await biometric.canAuthenticate();
if (!canAuth) {
  // Show error: Biometric not available
  return;
}

final authenticated = await biometric.authenticate();
if (!authenticated) {
  // Show error: Authentication failed
  return;
}
```

---

## 📱 NAVIGATION

### Push Screen
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => NewScreen()),
);
```

### Replace Screen
```dart
Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (context) => NewScreen()),
);
```

### Pop with Result
```dart
Navigator.pop(context, result);
```

### Named Routes (if using go_router)
```dart
context.push('/security-settings');
context.go('/login');
```

---

## ✅ CHECKLIST FOR NEW FEATURES

- [ ] Import required widgets
- [ ] Add error handling
- [ ] Add loading states
- [ ] Add empty states
- [ ] Test with different data
- [ ] Test error scenarios
- [ ] Check responsive layout
- [ ] Verify color scheme
- [ ] Add accessibility labels
- [ ] Test on different devices
- [ ] Add analytics tracking
- [ ] Update documentation

---

## 📚 ADDITIONAL RESOURCES

### Files to Reference
- `lib/core/theme/app_theme.dart` - Theme configuration
- `lib/core/utils/formatters.dart` - Formatting utilities
- `lib/core/utils/validators.dart` - Validation functions
- `lib/core/utils/error_handler.dart` - Error handling
- `lib/data/remote/api_client.dart` - API client

### Documentation
- Flutter: https://flutter.dev/docs
- Material Design: https://m3.material.io
- Riverpod: https://riverpod.dev

---

## 🆘 SUPPORT

For questions or issues:
1. Check this quick reference
2. Review the implementation summary
3. Check the main README
4. Contact the development team

---

**Happy Coding! 🚀**

© 2024 E-Kimina Rwanda
