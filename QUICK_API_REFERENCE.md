# Quick Fix Reference - API Calls

## ✅ Fixed Files

1. **deposit_money_screen.dart** - Deposit API call fixed
2. **withdraw_money_screen.dart** - Withdraw API call fixed  
3. **advanced_wallet_screen.dart** - All wallet API calls fixed

## 🔧 How to Use API Methods

### Import
```dart
import '../../../data/remote/api_client.dart';
```

### Initialize
```dart
final _apiClient = ApiClient();
// OR with Riverpod
final api = ref.read(apiClientProvider);
```

### Get Wallet
```dart
final wallet = await api.getWallet(userId: userId);
final balance = wallet['wallet']['balance'];
```

### Deposit
```dart
final result = await api.deposit(
  userId,           // String: User ID
  amount,           // double: Amount in RWF
  'MTN_MOMO',       // String: Provider
  phone: phoneNum,  // String?: Optional phone
);
```

### Withdraw
```dart
final result = await api.withdraw(
  userId,           // String: User ID
  amount,           // double: Amount in RWF
  'MTN_MOMO',       // String: Provider
  pin,              // String: Wallet PIN
  phone: phoneNum,  // String?: Optional phone
);
```

### Transfer
```dart
final result = await api.transfer(
  amount,              // double: Amount
  toPhone,             // String: Recipient phone
  pin,                 // String: Wallet PIN
  description: desc,   // String?: Optional description
);
```

## 🚀 Run Commands

```bash
# Clean and rebuild
flutter clean
flutter pub get

# Analyze code
flutter analyze

# Run app
flutter run
```

## 📝 TODO

- [ ] Replace hardcoded userId with actual auth state
- [ ] Test all wallet operations
- [ ] Fix BiometricService if needed
- [ ] Remove duplicate methods in api_client.dart
