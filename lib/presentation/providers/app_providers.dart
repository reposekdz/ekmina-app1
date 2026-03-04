import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../data/models/group_model.dart';
import '../../data/remote/api_client.dart';
import '../../data/local/hive_service.dart';

final userProvider = StateNotifierProvider<UserNotifier, AsyncValue<UserModel?>>((ref) {
  return UserNotifier(ref.read(apiClientProvider));
});

class UserNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final ApiClient _api;

  UserNotifier(this._api) : super(const AsyncValue.loading()) {
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = HiveService.getUser();
    state = user != null ? AsyncValue.data(user) : const AsyncValue.data(null);
  }

  Future<void> login(String phone, String password) async {
    state = const AsyncValue.loading();
    try {
      final response = await _api.login(phone, password);
      final user = UserModel.fromJson(response['user']);
      await HiveService.saveUser(user);
      await HiveService.saveToken(response['token']);
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> logout() async {
    await HiveService.clearUser();
    state = const AsyncValue.data(null);
  }
}

final groupsProvider = StateNotifierProvider<GroupsNotifier, AsyncValue<List<GroupModel>>>((ref) {
  final user = ref.watch(userProvider).value;
  return GroupsNotifier(ref.read(apiClientProvider), user?.id);
});

class GroupsNotifier extends StateNotifier<AsyncValue<List<GroupModel>>> {
  final ApiClient _api;
  final String? _userId;

  GroupsNotifier(this._api, this._userId) : super(const AsyncValue.loading()) {
    if (_userId != null) loadGroups();
  }

  Future<void> loadGroups() async {
    if (_userId == null) return;
    state = const AsyncValue.loading();
    try {
      final response = await _api.getGroups(_userId!);
      final groups = (response['groups'] as List).map((g) => GroupModel.fromJson(g)).toList();
      state = AsyncValue.data(groups);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final selectedGroupProvider = StateProvider<String?>((ref) => null);
final notificationsCountProvider = StateProvider<int>((ref) => 0);
final themeModeProvider = StateProvider<bool>((ref) => false);
final languageProvider = StateProvider<String>((ref) => 'rw');
