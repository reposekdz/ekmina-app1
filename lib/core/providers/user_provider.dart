import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/secure_storage_service.dart';

class UserState {
  final String? userId;
  final String? phone;
  final String? name;
  final bool isAuthenticated;

  UserState({this.userId, this.phone, this.name, this.isAuthenticated = false});

  UserState copyWith({String? userId, String? phone, String? name, bool? isAuthenticated}) {
    return UserState(
      userId: userId ?? this.userId,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class UserNotifier extends StateNotifier<UserState> {
  final SecureStorageService _storage = SecureStorageService();

  UserNotifier() : super(UserState()) {
    _loadUser();
  }

  Future<void> _loadUser() async {
    final userId = await _storage.getUserId();
    final phone = await _storage.getUserPhone();
    
    if (userId != null) {
      state = UserState(userId: userId, phone: phone, isAuthenticated: true);
    }
  }

  Future<void> setUser(String userId, String phone, {String? name}) async {
    await _storage.saveUserId(userId);
    await _storage.saveUserPhone(phone);
    state = UserState(userId: userId, phone: phone, name: name, isAuthenticated: true);
  }

  Future<void> logout() async {
    await _storage.clearAll();
    state = UserState(isAuthenticated: false);
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) => UserNotifier());
